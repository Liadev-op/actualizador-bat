@echo off
setlocal EnableExtensions EnableDelayedExpansion
Title Mapeo de Unidades de Red - DAIKIN
Mode 80,20 & Color 0A
cls

:: ------------------------- CONFIGURACIÓN DE ACTUALIZACIÓN -------------------------
:: Reemplaza esta URL con el enlace directo de la versión más reciente del script
set "UPDATE_URL=https://raw.githubusercontent.com/Liadev-op/actualizador-bat/refs/heads/main/REDES.bat"
set "LOCAL_FILE=%~f0"
set "TEMP_FILE=%TEMP%\actualizacion_redes.bat"

:: Verificar y descargar nueva versión
echo Verificando actualizaciones...
powershell -Command "try { Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -ErrorAction Stop } catch { exit 1 }"

:: Comparar con archivo actual
fc /b "%TEMP_FILE%" "%LOCAL_FILE%" >nul
if errorlevel 1 (
    echo [INFO] Se encontró una nueva versión. Actualizando...
    timeout /t 2 >nul
    copy /y "%TEMP_FILE%" "%LOCAL_FILE%" >nul
    echo [OK] Script actualizado. Reiniciando...
    timeout /t 2 >nul
    start "" "%LOCAL_FILE%"
    exit /b
) else (
    del "%TEMP_FILE%" >nul 2>&1
    echo [INFO] El script está actualizado.
)
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

:: Agregar credenciales si es necesario (SQLSRV)
cmdkey /add:sqlsrv /user:darg\!U! /pass:!P!

:: ------------------------- MAPEO DE UNIDADES -------------------------
call :MapDrive "g:" "\\filesrv2\shared$" "usuarios" "Darg1430*"
call :MapDrive "w:" "\\SQLSRV\datossrv$\Waldbott" "darg\!U!" "!P!"
call :MapDrive "y:" "\\SQLSRV\datossrv$\Alpha" "darg\!U!" "!P!"
call :MapDrive "h:" "\\dargnas\discoh" "dargnas\usuarios" "s875wp11"
call :MapDrive "i:" "\\dargnas\it" "dargnas\usuarios" "s875wp11"
call :MapDrive "x:" "\\dargnas\g" "dargnas\nas" "Darg1430***"

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
for /f "usebackq delims=" %%p in (%psCommand%) do set "%2=%%p"
exit /b
