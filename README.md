# Atualizador Windows

Script BAT de Sandro Vales para atualização de aplicativos via WinGet, consulta de integridade com DISM e Windows Update usando PSWindowsUpdate.

> **Esta versão pode reiniciar o computador automaticamente.** Salve seus arquivos e feche os programas antes de executar.

## O que faz

1. Solicita privilégios de administrador via UAC e VBScript temporário.
2. Executa `winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements`.
3. Executa `DISM /Online /Cleanup-Image /CheckHealth`: consulta o estado da imagem; não faz reparação nem varredura completa.
4. Tenta instalar PSWindowsUpdate se ausente e executa `Get-WindowsUpdate -Install -AcceptAll -AutoReboot`.

Não garante a atualização de todos os aplicativos, drivers, firmware ou BIOS. O alcance depende do WinGet e dos serviços de atualização configurados no Windows.

## Requisitos

- Windows com WinGet disponível: confira com `winget --version`.
- Windows PowerShell, DISM e Windows Script Host/VBScript disponíveis.
- Permissão de administrador e conexão à internet.
- Permissão para instalar módulos da PowerShell Gallery. Políticas da organização podem impedir a execução.

## Como baixar e usar

1. Clique em **Code > Download ZIP** nesta página.
2. Extraia o ZIP para uma pasta.
3. Leia `atualizar.bat` em um editor de texto.
4. Salve seus trabalhos: atualizações podem fechar programas e reiniciar o Windows.
5. Clique com o botão direito em `atualizar.bat` e escolha **Executar como administrador**.
6. Acompanhe as mensagens de cada ferramenta; pode haver solicitações adicionais.

## Limitações da primeira versão

- Código original do autor preservado.
- Os parâmetros do WinGet aceitam automaticamente acordos de pacotes e fontes; o Windows Update recebe `-AcceptAll`.
- `--include-unknown` inclui aplicativos cuja versão instalada não é conhecida pelo WinGet.
- `-AutoReboot` permite reinicialização automática.
- Não há tratamento de falhas por etapa. A mensagem **PC ATUALIZADO COM SUCESSO!** é incondicional e não comprova sucesso.
- A instalação de PSWindowsUpdate pode falhar por políticas de execução, acesso à Gallery ou dependências PowerShellGet/NuGet.
- A elevação depende de VBScript, que pode estar indisponível ou desativado.
- Não cria backup, ponto de restauração ou relatório próprio.

**Validação para publicação:** revisão estática do código e da documentação. O script não foi executado durante essa revisão, pois instalaria atualizações e poderia reiniciar o computador. Não há matriz de compatibilidade testada.

## Melhorias possíveis

- Tornar a reinicialização uma escolha explícita.
- Verificar dependências e códigos de saída.
- Substituir a elevação via VBScript.
- Registrar resultados em log e apresentar um resumo real por etapa.

## Contribuições

Sugestões e correções são bem-vindas por Issues e Pull Requests. Informe a versão do Windows e o erro, removendo dados pessoais dos relatos.

## Licença

[MIT](LICENSE). Consulte o arquivo LICENSE para as condições de uso, modificação e redistribuição.

## Referências

- [WinGet upgrade — Microsoft Learn](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade)
- [DISM — Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image?view=windows-11)
- [PSWindowsUpdate — PowerShell Gallery](https://www.powershellgallery.com/packages/PSWindowsUpdate)
