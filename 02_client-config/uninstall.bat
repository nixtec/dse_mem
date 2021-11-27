@echo off

echo "Uninstalling ...."
del %windir%\forwarder.bat
del %windir%\forwarder.exe

REM Remove registry entry
regedit forwarder-uninstall.reg
echo "Done"
pause
