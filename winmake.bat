@echo off
rem
rem Pitch Dark Makefile for Windows
rem assembles source code, optionally builds a disk image
rem
rem a qkumba monstrosity from 2018-03-01
rem

set BUILDDISK=build\Pitch Dark.hdv
set VOLUME=PITCH.DARK

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
%ACME% -r build\zinfo5u.lst src\zinfo\z5u\z5u.s
goto :EOF
)

if "%1" equ "dsk" (
:dsk
call :asm
1>nul copy /y res\blank.hdv "%BUILDDISK%"
1>nul copy /y res\_FileInformation.txt build\
cscript /nologo bin\fixFileInformation.js build\_FileInformation.txt
%CADIUS% CREATEFOLDER "%BUILDDISK%" "/%VOLUME%/Z/"
for /d %%q in (res\Z\*) do %CADIUS% ADDFOLDER "%BUILDDISK%" "/%VOLUME%/Z/%%~nxq" "%%q"
%CADIUS% ADDFOLDER "%BUILDDISK%" "/%VOLUME%/" "res/HINTS"
for %%q in ("build\GRUE.SYSTEM" "build\ONBEYOND.SYSTEM" "build\ZINFO.SYSTEM" "build\PITCH.DARK" "res\PITCH.DARK.CONF" "res\GAMES.CONF" "res\CREDITS.TXT") do %CADIUS% ADDFILE "%BUILDDISK%" "/%VOLUME%" "%%q"
%CADIUS% CREATEFOLDER "%BUILDDISK%" "/%VOLUME%/LIB/"
for %%q in (ONBEYONDZ1 ONBEYONDZ2 ONBEYONDZ3 ONBEYONDZ4 ONBEYONDZ5 ONBEYONDZ5U ZINFO1 ZINFO2 ZINFO3 ZINFO4 ZINFO5 ZINFO5U) do %CADIUS% ADDFILE "%BUILDDISK%" "/%VOLUME%/LIB/" "build\%%q"
goto :EOF
)

if "%1" equ "txt" (
call :dsk
:txt
2>nul md build\TEXT
cscript /nologo bin/textnormalize.js res\text
%CADIUS% ADDFOLDER "%BUILDDISK%" "/%VOLUME%/TEXT" build/TEXT
goto :EOF
)

if "%1" equ "artwork" (
call :dsk
:artwork
%CADIUS% ADDFOLDER "%BUILDDISK%" "/%VOLUME%/ARTWORK" "res\artwork"
%CADIUS% ADDFILE "%BUILDDISK%" "/%VOLUME%/ARTWORK/" "res\DHRSLIDE.SYSTEM"
%CADIUS% ADDFOLDER "%BUILDDISK%" "/%VOLUME%/ARTWORKGS" "res\artworkgs"
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
