@echo off
rem
rem Pitch Dark Makefile for Windows
rem assembles source code, optionally builds a disk image
rem
rem a qkumba monstrosity from 2018-03-01
rem

set DISK=Pitch Dark.2mg

rem third-party tools required to build (must be in path)
rem https://sourceforge.net/projects/acme-crossass/
set ACME=acme
rem https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
rem https://github.com/mach-kernel/cadius
set CADIUS=cadius

if "%1" equ "asm" (
:asm
2>nul md build
%ACME% -r build\grue.system.lst src\loader\grue.system.s
%ACME% -r build\pitchdark.lst src\pitchdark.a
%ACME% -r build\onbeyond.system.lst src\onbeyond\onbeyond.system.s
%ACME% -r build\z1.lst src\onbeyond\z1\z1.s
%ACME% -r build\z2.lst src\onbeyond\z2\z2.s
%ACME% -r build\z3.lst src\onbeyond\z3\z3.s
%ACME% -r build\z4.lst src\onbeyond\z4\z4.s
%ACME% -r build\z5.lst src\onbeyond\z5\z5.s
%ACME% -r build\z5u.lst src\onbeyond\z5u\z5u.s
%ACME% -r build\zinfo.system.lst src\zinfo\zinfo.system.s
%ACME% -r build\zinfo1.lst src\zinfo\z1\z1.s
%ACME% -r build\zinfo2.lst src\zinfo\z2\z2.s
%ACME% -r build\zinfo3.lst src\zinfo\z3\z3.s
%ACME% -r build\zinfo4.lst src\zinfo\z4\z4.s
%ACME% -r build\zinfo5.lst src\zinfo\z5\z5.s
goto :EOF
)

if "%1" equ "dsk" (
:dsk
call :asm
1>nul copy /y res\"Pitch Dark.master games collection.do.not.edit.2mg" "build\%DISK%"
1>nul copy /y res\_FileInformation.txt build\
cscript /nologo bin\fixFileInformation.js build\_FileInformation.txt
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\GRUE.SYSTEM"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYOND.SYSTEM"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ZINFO.SYSTEM"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\PITCH.DARK"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "res\PITCH.DARK.CONF"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "res\GAMES.CONF"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/" "res\CREDITS.TXT"
%CADIUS% CREATEFOLDER "build\%DISK%" "/PITCH.DARK/LIB/"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ1"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ2"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ3"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ4"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ5"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ5U"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ZINFO1"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ZINFO2"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ZINFO3"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ZINFO4"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ZINFO5"
goto :EOF
)

if "%1" equ "txt" (
call :dsk
:txt
2>nul md build\text
cscript /nologo bin/textnormalize.js res\text
cd build & %CADIUS% ADDFOLDER "%DISK%" "/PITCH.DARK/TEXT" text & cd ..
goto :EOF
)

if "%1" equ "artwork" (
call :dsk
:artwork
%CADIUS% ADDFOLDER "build\%DISK%" "/PITCH.DARK/ARTWORK" "res\artwork"
%CADIUS% ADDFILE "build\%DISK%" "/PITCH.DARK/ARTWORK/" "res\DHRSLIDE.SYSTEM"
%CADIUS% ADDFOLDER "build\%DISK%" "/PITCH.DARK/ARTWORKGS" "res\artworkgs"
goto :EOF
)

if "%1" equ "clean" (
:clean
echo y|1>nul 2>nul rd build /s
goto :EOF
)

if "%1" equ "all" (
call :clean
call :dsk
call :txt
call :artwork
goto :EOF
)

echo usage: %0 clean / asm / dsk / txt / artwork / all
