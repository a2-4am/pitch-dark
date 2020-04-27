# Is this page for you?

[Download the latest Pitch Dark disk image](https://archive.org/details/PitchDark) at the archive.org home page if you just want to play text adventures on your Apple II. The rest of this page is for developers who want to work with the source code and assemble it themselves.

# Building the code

## Mac OS X

You will need
 - [Xcode command line tools](https://www.google.com/search?q=xcode+command+line+tools)
 - [ACME](https://sourceforge.net/projects/acme-crossass/)
 - [sicklittlemonkey's Cadius fork](https://github.com/sicklittlemonkey/cadius)

Then open a terminal window and type

```
$ cd pitch-dark/
$ make
```

If all goes well, the `build/` subdirectory will contain a `Pitch Dark.2mg` image which can be mounted in emulators like [OpenEmulator](https://archive.org/details/OpenEmulatorSnapshots) or [Virtual II](http://virtualii.com/).

## Windows

You will need
 - [ACME](https://sourceforge.net/projects/acme-crossass/)
 - [Cadius for Windows](https://www.brutaldeluxe.fr/products/crossdevtools/cadius/)

(Those tools will need to be added to your command-line PATH.)

Then open a `CMD.EXE` window and type

```
C:\> CD PITCH-DARK
C:\4cade> WINMAKE
```
If all goes well, the `BUILD\` subdirectory will contain a `Pitch Dark.2mg` image which can be mounted in emulators like [AppleWin](https://github.com/AppleWin/AppleWin).
