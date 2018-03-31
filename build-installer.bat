@echo off
::set PATH=%PATH%;%WIX%\bin
::candle .\rudehash.wxs && light .\rudehash.wixobj -sice:ICE91

set PATH=%PATH%;%ProgramFiles(x86)%\NSIS
makensis rudehash.nsi

pause
