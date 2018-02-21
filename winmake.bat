@echo off
if "%1" equ "clean" (
:clean
echo y|1>nul 2>nul rd build /s
goto :EOF
)

if "%1" equ "asm" (
:asm
2>nul md build
acme src\grue.system.s
acme src\pitchdark.a
acme src\onbeyond\onbeyond.system.s
acme src\onbeyond\z3\z3.s
acme src\onbeyond\z4\z4.s
acme src\onbeyond\z5\z5.s
acme src\onbeyond\z5u\z5u.s
goto :EOF
)

set DISK=Pitch Dark.2mg

if "%1" equ "dsk" (
:dsk
call :asm
1>nul copy /y res\"Pitch Dark.master games collection.do.not.edit.2mg" "build\%DISK%"
1>nul copy /y res\WEEGUI build\
1>nul copy /y res\_FileInformation.txt build\
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\GRUE.SYSTEM"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\PITCH.DARK"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\WEEGUI"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYOND.SYSTEM"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYONDZ3"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYONDZ4"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYONDZ5"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYONDZ5U"
if not "%1" equ "" set DISK=
goto :EOF
)

if "%1" equ "txt" (
call :dsk
:txt
2>nul md build\text
python bin\textnormalize.py text\*
cd build
cadius ADDFOLDER "%DISK%" "/PITCH.DARK/TEXT" text
cd ..
if not "%1" equ "" set DISK=
goto :EOF
)

if "%1" equ "artwork" (
call :dsk
:artwork
1>nul xcopy /q /y /i res\artwork build\artwork
cd build
cadius ADDFOLDER "%DISK%" "/PITCH.DARK/ARTWORK" artwork
cd ..
if not "%1" equ "" set DISK=
goto :EOF
)

if "%1" equ "all" (
call :clean
call :dsk
call :txt
call :artwork
set DISK=
goto :EOF
)

echo usage: %0 clean / asm / dsk / txt / artwork / all
goto :EOF

rem make script for Windows environments
rem a qkumba monstrosity from 2018-02-20
rem requires ACME, CADIUS, Python
rem https://sourceforge.net/projects/acme-crossass/
rem https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
rem https://github.com/mach-kernel/cadius
rem https://www.python.org/
rem requires ACME, CADIUS, Python to be in path
