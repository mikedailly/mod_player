..\bin\snasm -map mixer_demo.asm mixer_tmp.nex
if ERRORLEVEL 1 goto doexit

rem simple 48k model
..\bin\CSpect.exe  -brk -emu -tv -w3 -vsync -s28 -map=mixer_tmp.nex.map -zxnext -mmc=.\ mixer_demo.nex

:doexit

