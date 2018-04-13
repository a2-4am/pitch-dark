0</* :
@echo off
if "%1" equ "clean" (
:clean
echo y|1>nul 2>nul rd build /s
goto :EOF
)

if "%1" equ "asm" (
:asm
2>nul md build
acme -r build\grue.system.lst src\grue.system.s
acme -r build\pitchdark.lst src\pitchdark.a
acme -r build\onbeyond.system.lst src\onbeyond\onbeyond.system.s
acme -r build\z1.lst src\onbeyond\z1\z1.s
acme -r build\z2.lst src\onbeyond\z2\z2.s
acme -r build\z3.lst src\onbeyond\z3\z3.s
acme -r build\z4.lst src\onbeyond\z4\z4.s
acme -r build\z5.lst src\onbeyond\z5\z5.s
acme -r build\z5u.lst src\onbeyond\z5u\z5u.s
acme -r build\zinfo.system.lst src\zinfo\zinfo.system.s
acme -r build\zinfo1.lst src\zinfo\z1\z1.s
goto :EOF
)

set DISK=Pitch Dark.2mg

if "%1" equ "dsk" (
:dsk
call :asm
1>nul copy /y res\"Pitch Dark.master games collection.do.not.edit.2mg" "build\%DISK%"
1>nul copy /y res\_FileInformation.txt build\
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\GRUE.SYSTEM"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ONBEYOND.SYSTEM"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\ZINFO.SYSTEM"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "build\PITCH.DARK"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/" "res\PITCH.DARK.CONF"
cadius CREATEFOLDER "build\%DISK%" "/PITCH.DARK/LIB/"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "res\WEEGUI"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ1"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ2"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ3"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ4"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ5"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ONBEYONDZ5U"
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/LIB/" "build\ZINFO1"
if not "%1" equ "" set DISK=
goto :EOF
)

if "%1" equ "txt" (
call :dsk
:txt
2>nul md build\text
cscript /nologo //e:jscript %~f0
cd build & cadius ADDFOLDER "%DISK%" "/PITCH.DARK/TEXT" text & cd ..
if not "%1" equ "" set DISK=
goto :EOF
)

if "%1" equ "artwork" (
call :dsk
:artwork
1>nul xcopy /q /y /i res\artwork build\artwork
cd build & cadius ADDFOLDER "%DISK%" "/PITCH.DARK/ARTWORK" artwork & cd ..
cadius ADDFILE "build\%DISK%" "/PITCH.DARK/ARTWORK/" "res\DHRSLIDE.SYSTEM"
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
*/
WScript.echo("")
a = new ActiveXObject("scripting.filesystemobject")
fileinfo = ""
for (b = new Enumerator(a.GetFolder("res\\text").files); !b.atEnd(); b.moveNext())
{
    f = a.opentextfile(b.item())
    try
    {
        shortf = a.GetBaseName(b.item()).toUpperCase()
        newf = ""
        fileinfo += "\r\n" + shortf + "=Type(04),AuxType(0000),VersionCreate(70),MinVersion(BE),Access(C3)"
        l = 0
        while (1)
        {
            lines = f.readline()
            !lines.length && (linelength = 0);
            l && linelength && (lines += new Array(linelength - lines.length).join(" "))
            newf += lines + "\n"
            if (lines.substring(0, 6) == "[info]") linelength = 65
            else if (lines.substring(0, 13) == "[description]") linelength = 78
            l = linelength
        }
    }
    catch(e){}
    a.createtextfile("build\\text\\" + shortf, 1).write(newf)
}
a.createtextfile("build\\text\\_FileInformation.txt", 1).write(fileinfo.substring(2))

/*
bat/jscript hybrid make script for Windows environments
a qkumba monstrosity from 2018-03-01
requires ACME, CADIUS
https://sourceforge.net/projects/acme-crossass/
https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
https://github.com/mach-kernel/cadius
requires ACME, CADIUS to be in path
*/
