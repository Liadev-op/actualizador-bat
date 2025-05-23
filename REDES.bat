@echo off
setlocal EnableExtensions EnableDelayedExpansion
Title Mapeo de Unidades de Red - DAIKIN
Mode 80,20 & Color 0A
cls

:: ------------------------- VERIFICACION DE ADMINISTRADOR -------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requiere privilegios de administrador. Reiniciando como administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ------------------------- CONFIGURACION DE ACTUALIZACION -------------------------
set "UPDATE_URL=https://raw.githubusercontent.com/Liadev-op/actualizador-bat/refs/heads/main/REDES.bat"
set "LOCAL_FILE=%~f0"
set "TEMP_FILE=%TEMP%\actualizacion_redes.bat"

echo Verificando actualizaciones...
powershell -Command "try { Invoke-WebRequest -Uri '%UPDATE_URL%' -OutFile '%TEMP_FILE%' -ErrorAction Stop } catch { exit 1 }"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] No se pudo verificar la actualizacion. Continuando con la version actual...
    goto continue
)

fc /b "%TEMP_FILE%" "%LOCAL_FILE%" >nul
if errorlevel 1 (
    echo [INFO] Se encontro una nueva version. Actualizando...
    timeout /t 2 >nul
    copy /y "%TEMP_FILE%" "%LOCAL_FILE%" >nul
    echo [OK] Script actualizado. Reiniciando...
    timeout /t 2 >nul
    start "" "%LOCAL_FILE%"
    exit /b
) else (
    del "%TEMP_FILE%" >nul 2>&1
    echo [INFO] El script esta actualizado.
)

:continue
echo.
:: ------------------------- ENTRADA DE USUARIO Y CLAVE -------------------------
echo ============================================================================
echo               UTILIDAD PARA MAPEAR UNIDADES DE RED DAIKIN
echo ============================================================================
echo.
echo Nota: Su usuario es la primer parte de su correo de Daikin justo antes del "@".
echo.

set /p U=Ingrese su usuario: 

call :InputPassword "Ingrese su contrasena" P

:: Cerrar conexiones anteriores
net use * /delete /y >nul 2>&1

:: Agregar credenciales si es necesario (SQLSRV)
cmdkey /add:sqlsrv /user:darg\!U! /pass:!P!

:: ------------------------- MAPEO DE UNIDADES -------------------------
set "SUCCESS_DRIVES="
set "FAILED_DRIVES="

call :MapDrive "g:" "\\filesrv2\shared$" "usuarios" "Darg1430*"
call :MapDrive "w:" "\\SQLSRV\datossrv$\Waldbott" "darg\!U!" "!P!"
call :MapDrive "y:" "\\SQLSRV\datossrv$\Alpha" "darg\!U!" "!P!"
call :MapDrive "h:" "\\dargnas\discoh" "dargnas\usuarios" "s875wp11"
call :MapDrive "i:" "\\dargnas\it" "dargnas\usuarios" "s875wp11"
call :MapDrive "x:" "\\dargnas\g" "dargnas\usuarios" "s875wp11"

echo.
echo ============================================================================
echo                     RESUMEN DE MAPEO DE UNIDADES
echo ============================================================================
if defined SUCCESS_DRIVES (
    echo [OK] Unidades mapeadas correctamente: !SUCCESS_DRIVES!
) else (
    echo [INFO] No se mapeo ninguna unidad correctamente.
)
if defined FAILED_DRIVES (
    echo [ERROR] Unidades con fallo: !FAILED_DRIVES!
) else (
    echo [OK] Ninguna unidad fallo.
)
echo ============================================================================
echo.

pause
exit /b

:: ------------------------- FUNCIONES -------------------------

:MapDrive
set "DRIVE=%~1"
set "SHARE=%~2"
set "USER=%~3"
set "PASS=%~4"

echo Mapeando %DRIVE% -> %SHARE% ...

:: Ejecutar el comando y capturar salida
net use %DRIVE% %SHARE% %PASS% /user:%USER% /persistent:yes >"%TEMP%\netuse_output.txt" 2>&1
set "ERRORCODE=%ERRORLEVEL%"

if %ERRORCODE% neq 0 (
    echo [ERROR] No se pudo mapear %DRIVE% (%SHARE%)
    type "%TEMP%\netuse_output.txt"
    set "FAILED_DRIVES=!FAILED_DRIVES! %DRIVE%"
) else (
    echo [OK] %DRIVE% mapeado correctamente.
    set "SUCCESS_DRIVES=!SUCCESS_DRIVES! %DRIVE%"
)

del "%TEMP%\netuse_output.txt" >nul 2>&1
exit /b


:InputPassword
set "psCommand=powershell -Command "$pword = read-host '%~1' -AsSecureString ; ^
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
for /f "usebackq delims=" %%p in (`%psCommand%`) do set "%2=%%p"
exit /b
