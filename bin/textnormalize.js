a = new ActiveXObject("scripting.filesystemobject")
fileinfo = ""
for (b = new Enumerator(a.GetFolder(WScript.Arguments(0)).files); !b.atEnd(); b.moveNext())
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
            newf += lines + "\r"
            if (lines.substring(0, 6) == "[info]") linelength = 65
            else if (lines.substring(0, 13) == "[description]") linelength = 78
            l = linelength
        }
    }
    catch(e){}
    a.createtextfile("build\\text\\" + shortf, 1).write(newf)
}
a.createtextfile("build\\text\\_FileInformation.txt", 1).write(fileinfo.substring(2))
