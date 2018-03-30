@echo off
set PATH=%PATH%;%WIX%\bin
candle .\rudehash.wxs && light .\rudehash.wixobj -sice:ICE91
