@echo off
echo Ejecutando prueba de restaurante...
echo.

REM Guardar main.lua original
if exist main.lua (
    if not exist main_backup.lua (
        copy main.lua main_backup.lua >nul
        echo [OK] Backup de main.lua creado
    )
)

REM Copiar prueba_restaurante.lua como main.lua
copy /Y prueba_restaurante.lua main.lua >nul
echo [OK] prueba_restaurante.lua copiado como main.lua

REM Ejecutar LOVE
echo.
echo Ejecutando LOVE...
echo Usa FLECHAS ARRIBA/ABAJO para ajustar la escala
echo Presiona ESC para salir
echo.

"C:\Program Files\LOVE\love.exe" .

REM Restaurar main.lua original
if exist main_backup.lua (
    copy /Y main_backup.lua main.lua >nul
    del main_backup.lua >nul
    echo.
    echo [OK] main.lua original restaurado
)

echo.
echo Prueba finalizada. Presiona cualquier tecla para cerrar...
pause >nul
