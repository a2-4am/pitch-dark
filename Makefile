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

BUILDDISK=build/Pitch Dark.hdv
VOLUME=PITCH.DARK

# third-party tools required to build
# https://sourceforge.net/projects/acme-crossass/
ACME=acme
# https://www.brutaldeluxe.fr/products/crossdevtools/cadius/
# https://github.com/mach-kernel/cadius
CADIUS=cadius

PY3=python3

asm: md
	$(ACME) -r build/grue.system.lst src/loader/grue.system.s
	$(ACME) -r build/pitchdark.lst src/pitchdark.a
	$(ACME) -r build/onbeyond.system.lst src/onbeyond/onbeyond.system.s
	$(ACME) -r build/z1.lst src/onbeyond/z1/z1.s
	$(ACME) -r build/z2.lst src/onbeyond/z2/z2.s
	$(ACME) -r build/z3.lst src/onbeyond/z3/z3.s
	$(ACME) -r build/z4.lst src/onbeyond/z4/z4.s
	$(ACME) -r build/z5.lst src/onbeyond/z5/z5.s
	$(ACME) -r build/z5u.lst src/onbeyond/z5u/z5u.s
	$(ACME) -r build/zinfo.system.lst src/zinfo/zinfo.system.s
	$(ACME) -r build/zinfo1.lst src/zinfo/z1/z1.s
	$(ACME) -r build/zinfo2.lst src/zinfo/z2/z2.s
	$(ACME) -r build/zinfo3.lst src/zinfo/z3/z3.s
	$(ACME) -r build/zinfo4.lst src/zinfo/z4/z4.s
	$(ACME) -r build/zinfo5.lst src/zinfo/z5/z5.s
	$(ACME) -r build/zinfo5u.lst src/zinfo/z5u/z5u.s

dsk: md asm
	cp res/blank.hdv "$(BUILDDISK)"
	cp res/_FileInformation.txt build/
	bin/fixFileInformation.sh build/_FileInformation.txt
	$(CADIUS) CREATEFOLDER "$(BUILDDISK)" "/$(VOLUME)/Z/"
	for f in res/Z/*; do \
		$(CADIUS) ADDFOLDER "$(BUILDDISK)" "/$(VOLUME)/Z/$$(basename $$f)" "$$f"; \
	done
	$(CADIUS) ADDFOLDER "$(BUILDDISK)" "/$(VOLUME)/" "res/HINTS"
	for f in "build/GRUE.SYSTEM" "build/ONBEYOND.SYSTEM" "build/ZINFO.SYSTEM" "build/$(VOLUME)" "res/PITCH.DARK.CONF" "res/GAMES.CONF" "res/CREDITS.TXT"; do \
		$(CADIUS) ADDFILE "$(BUILDDISK)" "/$(VOLUME)/" "$$f"; \
	done
	$(CADIUS) CREATEFOLDER "$(BUILDDISK)" "/$(VOLUME)/LIB/"
	for f in ONBEYONDZ1 ONBEYONDZ2 ONBEYONDZ3 ONBEYONDZ4 ONBEYONDZ5 ONBEYONDZ5U ZINFO1 ZINFO2 ZINFO3 ZINFO4 ZINFO5 ZINFO5U; do \
		$(CADIUS) ADDFILE "$(BUILDDISK)" "/$(VOLUME)/LIB/" "build/$$f"; \
	done
	# sample save game files for development
	#$(CADIUS) ADDFILE "$(BUILDDISK)" "/$(VOLUME)/Z/WISHBRINGER/" "res/R69.850920.SAV"
	#$(CADIUS) ADDFILE "$(BUILDDISK)" "/$(VOLUME)/Z/ZORK.I/" "res/R88.840726.SAV"

txt: dsk
	mkdir -p build/TEXT
	$(PY3) bin/textnormalize.py res/text/*
	$(CADIUS) ADDFOLDER "$(BUILDDISK)" "/$(VOLUME)/TEXT" build/TEXT

artwork: dsk
	$(CADIUS) ADDFOLDER "$(BUILDDISK)" "/$(VOLUME)/ARTWORK" "res/artwork"
	$(CADIUS) ADDFILE "$(BUILDDISK)" "/$(VOLUME)/ARTWORK/" "res/DHRSLIDE.SYSTEM"
	$(CADIUS) ADDFOLDER "$(BUILDDISK)" "/$(VOLUME)/ARTWORKGS" "res/artworkgs"

mount: dsk
	osascript bin/V2Make.scpt "`pwd`" bin/pitchdark.vii "$(BUILDDISK)"

md:
	mkdir -p build

clean:
	rm -rf build/

all: clean asm dsk txt artwork mount
