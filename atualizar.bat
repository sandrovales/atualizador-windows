@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

:: ============================================================
::  Atualizador Windows - Sandro Vales
::  Uso: atualizar.bat [/reboot ^| /noreboot] [/repair] [/nopause] [/?]
:: ============================================================

:: Capturados antes do SHIFT, que tambem desloca %0.
set "SELF=%~f0"
set "SELF_NAME=%~nx0"
set "HERE=%~dp0"
set "SELF_ARGS=%*"

set "REBOOT_MODE=ask"
set "REPAIR=0"
set "USAGE_RC=0"
set "NOPAUSE=0"

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="/reboot"   set "REBOOT_MODE=auto"  & shift & goto parse
if /i "%~1"=="/noreboot" set "REBOOT_MODE=never" & shift & goto parse
if /i "%~1"=="/repair"   set "REPAIR=1"          & shift & goto parse
if /i "%~1"=="/nopause"  set "NOPAUSE=1"         & shift & goto parse
if "%~1"=="/?" goto usage
if /i "%~1"=="/help" goto usage
echo Opcao desconhecida: %~1
echo.
set "USAGE_RC=1"
goto usage

:parsed
:: Sem pausa nao ha como perguntar: nao reinicia, a menos que /reboot seja usado.
if "%NOPAUSE%"=="1" if "%REBOOT_MODE%"=="ask" set "REBOOT_MODE=never"

:: --- Elevacao via PowerShell (sem VBScript) ---
net session >nul 2>&1
if %errorlevel% EQU 0 goto gotAdmin
echo Solicitando permissao de Administrador...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=@{FilePath=$env:SELF;Verb='RunAs'}; if ($env:SELF_ARGS) { $p.ArgumentList=$env:SELF_ARGS }; try { Start-Process @p -ErrorAction Stop } catch { exit 1 }"
if errorlevel 1 (
    echo.
    echo Permissao de Administrador negada ou indisponivel. Nada foi alterado.
    pause
    exit /b 1
)
exit /b 0

:gotAdmin
cd /d "%HERE%"

:: --- Log ---
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%i"
if not exist "%HERE%logs" mkdir "%HERE%logs"
set "LOG=%HERE%logs\atualizar_%TS%.log"

set "S1=IGNORADO"
set "S2=IGNORADO"
set "S3=IGNORADO"
set "FAILS=0"
set "PENDING=0"

call :log "==========================================="
call :log "  ATUALIZACAO DO WINDOWS (MODO ADM)"
call :log "  Inicio: %DATE% %TIME%"
call :log "  Reinicio: %REBOOT_MODE%   Reparo: %REPAIR%"
call :log "  Log: %LOG%"
call :log "==========================================="
echo.

:: ------------------------------------------------------------
:: 1. Aplicativos via WinGet
:: ------------------------------------------------------------
call :log "[1/3] Atualizando aplicativos (WinGet)..."
where winget >nul 2>&1
if errorlevel 1 (
    call :log "WinGet nao encontrado. Instale o 'App Installer' pela Microsoft Store."
    set "S1=IGNORADO (WinGet ausente)"
    goto step2
)
set "STEP_CMD=winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"
call :runstep
:: 0x8A15002B = nenhuma atualizacao aplicavel
if "%RC%"=="0" (set "S1=OK") else if "%RC%"=="-1978335189" (set "S1=OK (nada a atualizar)") else (
    set "S1=FALHA (codigo %RC%)"
    set /a FAILS+=1
)

:step2
echo.
:: ------------------------------------------------------------
:: 2. Integridade do sistema
:: ------------------------------------------------------------
if "%REPAIR%"=="1" goto step2repair
call :log "[2/3] Consultando integridade da imagem (DISM /CheckHealth)..."
set "STEP_CMD=dism /Online /Cleanup-Image /CheckHealth"
call :runstep
call :dismstatus
goto step3

:step2repair
call :log "[2/3] Reparando imagem (DISM /RestoreHealth) - pode demorar..."
set "STEP_CMD=dism /Online /Cleanup-Image /RestoreHealth"
call :runstep
call :dismstatus
if not "%S2:~0,2%"=="OK" goto step3
call :log "      Verificando arquivos de sistema (SFC /scannow)..."
sfc /scannow
set "SFC_RC=%errorlevel%"
call :log "      SFC terminou com codigo %SFC_RC%. Detalhes: %WINDIR%\Logs\CBS\CBS.log"
if not "%SFC_RC%"=="0" set "S2=%S2% / SFC codigo %SFC_RC% - verifique o CBS.log"

:step3
echo.
:: ------------------------------------------------------------
:: 3. Windows Update via PSWindowsUpdate
:: ------------------------------------------------------------
call :log "[3/3] Buscando atualizacoes do Windows (PSWindowsUpdate)..."
set "STEP_CMD=[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; if (-not (Get-Module -ListAvailable PSWindowsUpdate)) { Write-Output 'Instalando modulo PSWindowsUpdate...'; if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null }; Install-Module PSWindowsUpdate -Scope AllUsers -Force -AllowClobber -ErrorAction Stop }; Import-Module PSWindowsUpdate -ErrorAction Stop; Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -ErrorAction Stop"
call :runstep
if "%RC%"=="0" (set "S3=OK") else (
    set "S3=FALHA (codigo %RC%)"
    set /a FAILS+=1
)

:: ------------------------------------------------------------
:: Resumo
:: ------------------------------------------------------------
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1 && set "PENDING=1"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && set "PENDING=1"

echo.
call :log "==========================================="
call :log "  RESUMO"
call :log "  [1] Aplicativos (WinGet) : %S1%"
call :log "  [2] Integridade          : %S2%"
call :log "  [3] Windows Update       : %S3%"
if "%PENDING%"=="1" (call :log "  Reinicializacao pendente: SIM") else (call :log "  Reinicializacao pendente: nao")
if "%FAILS%"=="0" (call :log "  Resultado: CONCLUIDO SEM FALHAS") else (call :log "  Resultado: %FAILS% ETAPA(S) COM FALHA - veja o log")
call :log "  Fim: %DATE% %TIME%"
call :log "==========================================="
echo.

if "%PENDING%"=="0" goto finish
if "%REBOOT_MODE%"=="never" (
    call :log "Reinicie o computador quando for conveniente para concluir as atualizacoes."
    goto finish
)
if "%REBOOT_MODE%"=="auto" goto doreboot
choice /c SN /m "Reiniciar o computador agora? Salve seus arquivos antes"
if errorlevel 2 (
    call :log "Reinicializacao adiada pelo usuario."
    goto finish
)
:doreboot
call :log "Reiniciando em 60 segundos. Para cancelar: shutdown /a"
shutdown /r /t 60 /c "Atualizador Windows: reiniciando para concluir as atualizacoes."

:finish
if "%NOPAUSE%"=="0" pause
if "%FAILS%"=="0" exit /b 0
exit /b 1

:: ============================================================
:: Sub-rotinas
:: ============================================================

:: Executa %STEP_CMD% no PowerShell, mostrando a saida e gravando no log.
:: Retorna o codigo de saida em RC.
:runstep
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code=0; try { & ([scriptblock]::Create($env:STEP_CMD)) 2>&1 | Out-String -Stream -Width 200 | ForEach-Object { $_; Add-Content -LiteralPath $env:LOG -Value $_ -Encoding UTF8 }; if ($LASTEXITCODE) { $code=$LASTEXITCODE } } catch { $m='ERRO: ' + $_.Exception.Message; Write-Host $m -ForegroundColor Red; Add-Content -LiteralPath $env:LOG -Value $m -Encoding UTF8; $code=1 }; exit $code"
set "RC=%errorlevel%"
call :log "      Codigo de saida: %RC%"
exit /b

:: Interpreta o codigo do DISM (3010 = sucesso, reinicio necessario).
:dismstatus
if "%RC%"=="0" (set "S2=OK") else if "%RC%"=="3010" (
    set "S2=OK (reinicio necessario)"
    set "PENDING=1"
) else (
    set "S2=FALHA (codigo %RC%)"
    set /a FAILS+=1
)
exit /b

:log
echo(%~1
>>"%LOG%" echo(%~1
exit /b

:usage
echo Uso: %SELF_NAME% [/reboot ^| /noreboot] [/repair] [/nopause]
echo.
echo   /reboot    Reinicia automaticamente (em 60 s) se houver reinicio pendente.
echo   /noreboot  Nunca reinicia; apenas avisa se for necessario.
echo              Sem nenhum dos dois, pergunta ao final.
echo   /repair    Usa DISM /RestoreHealth + SFC /scannow em vez de DISM /CheckHealth.
echo   /nopause   Nao pausa no final (para uso agendado). Implica /noreboot,
echo              a menos que /reboot seja informado.
echo.
echo Logs em: %HERE%logs\
exit /b %USAGE_RC%
