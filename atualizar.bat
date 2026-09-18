@echo off
:: --- INICIO DO BLOCO DE AUTO-ELEVACAO ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando permissao de Administrador...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%cd%"
    CD /D "%~dp0"
:: --- FIM DO BLOCO ---

echo.
echo ===========================================
echo   INICIANDO ATUALIZACAO TOTAL (MODO ADM)
echo ===========================================
echo.

:: 1. Atualizar aplicativos via WinGet
echo [1/3] Atualizando aplicativos...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

echo.
:: 2. Verificacao de integridade
echo [2/3] Verificando integridade do sistema...
dism /online /cleanup-image /checkhealth

echo.
:: 3. Windows Update via PowerShell
echo [3/3] Buscando atualizacoes do Windows...
powershell -command "if (!(Get-Module -ListAvailable PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -AllowClobber }; Get-WindowsUpdate -Install -AcceptAll -AutoReboot"

echo.
echo ===========================================
echo   PC ATUALIZADO COM SUCESSO!
echo ===========================================
pause
