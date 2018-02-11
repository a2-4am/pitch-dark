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

DISK=pitchdark.po

# third-party tools required to build
# https://sourceforge.net/projects/acme-crossass/
ACME=acme
# https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
# https://github.com/mach-kernel/cadius
CADIUS=cadius

asm:
	mkdir -p build
	cd src && $(ACME) pitchdark.a

dsk: asm
	cp res/$(DISK) build/
	cp res/_FileInformation.txt build/
	$(CADIUS) ADDFILE build/$(DISK) "/PDBOOT/" "build/PITCH.DARK"

txt: dsk
	mkdir -p build/text
	$(PY3) bin/textnormalize.py text/*
	cd build && $(CADIUS) ADDFOLDER $(DISK) "/PDBOOT/TEXT" text

clean:
	rm -rf build/

mount:
	osascript bin/V2Make.scpt "`pwd`" build/$(DISK)

all: clean asm dsk txt mount
