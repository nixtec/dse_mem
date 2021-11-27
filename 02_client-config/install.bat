@echo off

echo "Installing ...."
copy forwarder.exe %windir%
copy forwarder.bat %windir%

REM Add registry entry
regedit forwarder-install.reg
echo "Done"
pause
