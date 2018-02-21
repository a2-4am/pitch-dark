@echo off
if "%1" equ "clean" (
echo y|1>nul 2>nul rd build /s
goto :EOF
)

2>nul md build
if "%1" equ "asm" (
call :asm
goto :EOF
)

set DISK=PitchDark.2mg

if "%1" equ "dsk" (
call :asm
call :dsk
set DISK=
goto :EOF
)

if "%1" equ "txt" (
call :asm
call :dsk
call :txt
set DISK=
goto :EOF
)

goto :EOF

:asm
acme src\grue.system.s
acme src\pitchdark.a
acme src\onbeyond\onbeyond.system.s
acme src\onbeyond\z3\z3.s
acme src\onbeyond\z4\z4.s
acme src\onbeyond\z5\z5.s
acme src\onbeyond\z5u\z5u.s
goto :EOF

:dsk
1>nul copy /y res\"Pitch Dark.master games collection.do.not.edit.2mg" build\%DISK%
1>nul copy /y res\WEEGUI build\
1>nul copy /y res\_FileInformation.txt build\
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\GRUE.SYSTEM"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\PITCH.DARK"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\WEEGUI"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\ONBEYOND.SYSTEM"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\ONBEYONDZ3"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\ONBEYONDZ4"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\ONBEYONDZ5"
cadius ADDFILE build\%DISK% "/PITCH.DARK/" "build\ONBEYONDZ5U"
goto :EOF

:txt
md text
python3 bin\textnormalize.py text\*
cadius ADDFOLDER %disk% "/PITCH.DARK/TEXT" text
goto :EOF

/*
make script for Windows environments
a qkumba monstrosity from 2018-02-20
requires ACME, CADIUS, Python
https://sourceforge.net/projects/acme-crossass/
https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
https://github.com/mach-kernel/cadius
https://www.python.org/
requires ACME, CADIUS, Python to be in path
*/
