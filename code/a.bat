..\bin\snasm -map mod_demo.asm mod_tmp.nex
if ERRORLEVEL 1 goto doexit

rem simple 48k model
..\bin\CSpect.exe -debug -brk -emu -tv -w3 -vsync -s28 -map=mod_tmp.nex.map -zxnext -mmc=.\ mod_player.nex

:doexit

