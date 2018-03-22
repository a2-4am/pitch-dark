#
# Pitch Dark Makefile
# assembles source code, optionally builds a disk image and mounts it
#
# original by Quinn Dunki on 2014-08-15
# One Girl, One Laptop Productions
# http://www.quinndunki.com/blondihacks
#
# adapted by 4am on 2018-01-07
#

DISK=Pitch Dark.2mg

# third-party tools required to build
# https://sourceforge.net/projects/acme-crossass/
ACME=acme
# https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
# https://github.com/mach-kernel/cadius
CADIUS=cadius

md:
	mkdir -p build

clean:
	rm -rf build/

asm: md
	$(ACME) -r build/grue.system.lst src/grue.system.s
	$(ACME) -r build/pitchdark.lst src/pitchdark.a
	$(ACME) -r build/onbeyond.system.lst src/onbeyond/onbeyond.system.s
	$(ACME) -r build/z1.lst src/onbeyond/z1/z1.s
	$(ACME) -r build/z2.lst src/onbeyond/z2/z2.s
	$(ACME) -r build/z3.lst src/onbeyond/z3/z3.s
	$(ACME) -r build/z4.lst src/onbeyond/z4/z4.s
	$(ACME) -r build/z5.lst src/onbeyond/z5/z5.s
	$(ACME) -r build/z5u.lst src/onbeyond/z5u/z5u.s

dsk: md asm
	cp res/"Pitch Dark.master games collection.do.not.edit.2mg" build/"$(DISK)"
	cp res/_FileInformation.txt build/
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/" "build/GRUE.SYSTEM"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/" "build/ONBEYOND.SYSTEM"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/" "build/PITCH.DARK"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/" "res/PITCH.DARK.CONF"
	$(CADIUS) CREATEFOLDER build/"$(DISK)" "/PITCH.DARK/LIB/"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "res/WEEGUI"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "build/ONBEYONDZ1"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "build/ONBEYONDZ2"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "build/ONBEYONDZ3"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "build/ONBEYONDZ4"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "build/ONBEYONDZ5"
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/LIB/" "build/ONBEYONDZ5U"

txt: dsk
	mkdir -p build/text
	$(PY3) bin/textnormalize.py res/text/*
	cd build && $(CADIUS) ADDFOLDER "$(DISK)" "/PITCH.DARK/TEXT" text

artwork: dsk
	rsync -a res/artwork build/
	cd build && $(CADIUS) ADDFOLDER "$(DISK)" "/PITCH.DARK/ARTWORK" artwork
	$(CADIUS) ADDFILE build/"$(DISK)" "/PITCH.DARK/ARTWORK/" "res/DHRSLIDE.SYSTEM"

mount: dsk
	osascript bin/V2Make.scpt "`pwd`" bin/pitchdark.vii build/"$(DISK)"

all: clean asm dsk txt artwork mount
