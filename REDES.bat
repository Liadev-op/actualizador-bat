@echo off
setlocal EnableExtensions EnableDelayedExpansion
Title Mapeo de Unidades de Red - DAIKIN
Mode 80,20 & Color 0A
cls

:: ------------------------- CONFIGURACIÓN DE ACTUALIZACIÓN -------------------------
:: URL RAW directa del archivo en GitHub
set "UPDATE_URL=https://raw.githubusercontent.com/Liadev-op/actualizador-bat/main/REDES.bat"
set "LOCAL_FILE=%~f0"
set "TEMP_FILE=%TEMP%\actualizacion_redes.bat"

:: Descargar nueva versión del script a archivo temporal
echo Verificando actualizaciones...
powershell -Command "try { Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing -ErrorAction Stop } catch { Write-Host '[ERROR] No se pudo descargar la nueva versión.'; exit 1 }"

:: Validar que se haya descargado correctamente
if not exist "%TEMP_FILE%" (
    echo [ERROR] No se pudo descargar el archivo actualizado.
    timeout /t 5 >nul
    goto :Continue
)

:: Comparar los archivos
fc /b "%TEMP_FILE%" "%LOCAL_FILE%" >nul
if errorlevel 1 (
    echo [INFO] Se encontró una nueva versión. Ejecutando nueva versión...
    timeout /t 2 >nul
    start "" "%TEMP_FILE%"
    exit /b
) else (
    del "%TEMP_FILE%" >nul 2>&1
    echo [INFO] El script está actualizado.
)

:Continue
echo.


:: ------------------------- ENTRADA DE USUARIO Y CLAVE -------------------------
echo ============================================================================
echo                UTILIDAD PARA MAPEAR UNIDADES DE RED DAIKIN
echo ============================================================================
echo.
echo Nota: Su usuario es la primer parte de su correo de Daikin justo antes del "@".
echo.

set /p U=Ingrese su usuario: 

call :InputPassword "Ingrese su contraseña" P

:: Cerrar conexiones anteriores
net use * /delete /y >nul 2>&1

:: Agregar credenciales si es necesario
cmdkey /add:sqlsrv /user:darg\!U! /pass:!P!
net use x: /delete /y >nul 2>&1

:: ------------------------- MAPEO DE UNIDADES -------------------------
call :MapDrive "g:" "\\filesrv2\shared$" "usuarios" "Darg1430*"
call :MapDrive "w:" "\\SQLSRV\datossrv$\Waldbott" "darg\!U!" "!P!"
call :MapDrive "y:" "\\SQLSRV\datossrv$\Alpha" "darg\!U!" "!P!"
call :MapDrive "h:" "\\dargnas\discoh" "dargnas\usuarios" "s875wp11"
call :MapDrive "i:" "\\dargnas\it" "dargnas\usuarios" "s875wp11"
call :MapDrive "x:" "\\dargnas\g" "dargnas\nas" "S875wp11"

echo.
echo [FIN] Todas las unidades han sido procesadas.
pause
exit /b

:: ------------------------- FUNCIONES -------------------------

:MapDrive
set "DRIVE=%~1"
set "SHARE=%~2"
set "USER=%~3"
set "PASS=%~4"

echo Mapeando %DRIVE% -> %SHARE% ...
net use %DRIVE% %SHARE% %PASS% /user:%USER% /persistent:yes >nul 2>&1

if errorlevel 1 (
    echo [ERROR] No se pudo mapear %DRIVE% (%SHARE%)
) else (
    echo [OK] %DRIVE% mapeado correctamente.
)
exit /b

:InputPassword
set "psCommand=powershell -Command "$pword = read-host '%~1' -AsSecureString ; ^
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
for /f "usebackq delims=" %%p in (`%psCommand%`) do set "%2=%%p"
exit /b
