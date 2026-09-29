# Atualizador Windows

Script BAT de Sandro Vales para atualização de aplicativos via WinGet, verificação de integridade com DISM/SFC e Windows Update usando PSWindowsUpdate.

> **Salve seus arquivos e feche os programas antes de executar.** Por padrão o script pergunta antes de reiniciar; com `/reboot` ele reinicia sozinho (após 60 s) quando necessário.

## O que faz

1. Solicita privilégios de administrador via UAC (PowerShell `Start-Process -Verb RunAs`, sem VBScript).
2. Executa `winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements`.
3. Verifica a integridade da imagem:
   - padrão: `DISM /Online /Cleanup-Image /CheckHealth` (consulta rápida, não repara);
   - com `/repair`: `DISM /RestoreHealth` seguido de `sfc /scannow`.
4. Instala PSWindowsUpdate se ausente (com provedor NuGet e TLS 1.2) e executa `Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot`.
5. Mostra um **resumo real** por etapa (OK / FALHA com código de saída / IGNORADO), verifica se há reinicialização pendente e age conforme a opção escolhida.

Toda a saída das etapas é gravada em `logs\atualizar_AAAAMMDD_HHMMSS.log`, na pasta do script.

Não garante a atualização de todos os aplicativos, drivers, firmware ou BIOS. O alcance depende do WinGet e dos serviços de atualização configurados no Windows.

## Opções

| Opção | Efeito |
|---|---|
| *(nenhuma)* | Pergunta ao final se deve reiniciar (só se houver reinicialização pendente). |
| `/reboot` | Reinicia automaticamente em 60 s se necessário. Para cancelar: `shutdown /a`. |
| `/noreboot` | Nunca reinicia; apenas avisa. |
| `/repair` | Usa `DISM /RestoreHealth` + `sfc /scannow` (mais demorado) em vez de `/CheckHealth`. |
| `/nopause` | Não pausa no final, para uso agendado. Implica `/noreboot`, a menos que `/reboot` seja informado. |
| `/?` | Mostra a ajuda. |

Código de saída: `0` se todas as etapas terminaram sem falha, `1` caso contrário.

## Requisitos

- Windows com WinGet disponível: confira com `winget --version`. Se ausente, a etapa 1 é ignorada e o resumo informa.
- Windows PowerShell 5.1 e DISM.
- Permissão de administrador e conexão à internet.
- Permissão para instalar módulos da PowerShell Gallery. Políticas da organização podem impedir a execução.

## Como baixar e usar

1. Clique em **Code > Download ZIP** nesta página.
2. Extraia o ZIP para uma pasta.
3. Leia `atualizar.bat` em um editor de texto.
4. Salve seus trabalhos: atualizações podem fechar programas.
5. Dê dois cliques em `atualizar.bat` (ou execute pelo terminal com as opções desejadas) e aceite o pedido do UAC.
6. Acompanhe as mensagens de cada ferramenta e confira o resumo final e o log.

Exemplo para agendamento (Agendador de Tarefas, com "Executar com privilégios mais altos"):

```bat
atualizar.bat /nopause /noreboot
```

## Limitações

- Os parâmetros do WinGet aceitam automaticamente acordos de pacotes e fontes; o Windows Update recebe `-AcceptAll`.
- `--include-unknown` inclui aplicativos cuja versão instalada não é conhecida pelo WinGet.
- O WinGet retorna código diferente de zero se **qualquer** pacote falhar; nesse caso a etapa aparece como FALHA mesmo que os demais tenham sido atualizados. Consulte o log.
- O código de saída do `sfc` não é totalmente documentado; valores diferentes de 0 são sinalizados para conferência em `%WINDIR%\Logs\CBS\CBS.log`.
- A instalação de PSWindowsUpdate pode falhar por políticas de execução, acesso à Gallery ou dependências PowerShellGet/NuGet (a falha aparece no resumo).
- Não cria backup nem ponto de restauração.

**Validação:** o fluxo do script foi testado com comandos simulados (sucesso, código 3010 e falha) para conferir log, resumo e códigos de saída. A execução real depende do ambiente e não há matriz de compatibilidade testada.

## Contribuições

Sugestões e correções são bem-vindas por Issues e Pull Requests. Informe a versão do Windows e o erro, removendo dados pessoais dos relatos.

## Licença

[MIT](LICENSE). Consulte o arquivo LICENSE para as condições de uso, modificação e redistribuição.

## Referências

- [WinGet upgrade — Microsoft Learn](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade)
- [DISM — Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image?view=windows-11)
- [SFC — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/sfc)
- [PSWindowsUpdate — PowerShell Gallery](https://www.powershellgallery.com/packages/PSWindowsUpdate)
