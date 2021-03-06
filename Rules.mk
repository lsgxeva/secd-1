
TOPDIR			?= .
SECDDIR			= $(TOPDIR)/secd
LISPKITDIR	= $(TOPDIR)/lispkit
SECD				= $(SECDDIR)/secd
LISPKIT			= $(LISPKITDIR)/compiler.lob
M4INCLUDE		= -I$(TOPDIR) -I$(TOPDIR)/util

CLEANFILES	?=

DEBUG=0
M4=m4 $(M4INCLUDE) $(M4FLAGS)
CC=gcc
AS=nasm -g
ARCH=elf32
ASFLAGS=-f $(ARCH) -I$(SECDDIR)/
ifeq ($(DEBUG),1)
	ASFLAGS+=-D DEBUG=1
endif
LD=ld
LDFLAGS=-m elf_i386

$(SECD): $(SECDDIR)/support.o $(SECDDIR)/string.o $(SECDDIR)/heap.o $(SECDDIR)/secd.o $(SECDDIR)/main.o
	$(LD) $(LDFLAGS) -o $@ $^
	if (($(DEBUG) == 0)); then strip $@; fi

clean:
	rm -f $(CLEANFILES)
	ls -1 *.lob | grep -iv '^APENDIX2\.LOB$$' | xargs rm -f

$(LISPKITDIR)/primitive-compiler.lob: $(LISPKITDIR)/APENDIX2.LOB $(LISPKITDIR)/APENDIX2.LSO $(SECD)
	cat $(LISPKITDIR)/APENDIX2.LOB $(LISPKITDIR)/APENDIX2.LSO | $(SECD) > $@

$(LISPKIT): $(LISPKITDIR)/compiler.lso $(LISPKITDIR)/primitive-compiler.lob $(SECD) 
	$(M4) $< | cat $(LISPKITDIR)/primitive-compiler.lob - | $(SECD) > $@.tmp
	$(M4) $< | cat $@.tmp - | $(SECD) > $@
	-rm -f $@.tmp

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

%.lob : %.lso $(LISPKIT) $(SECD)
	$(M4) $< | cat $(LISPKIT) - | $(SECD) > $@
	@if ( head -n 1 "$@" | grep -q '^\s*(\s*ERROR\b' ); then cat "$@"; rm -f "$@"; exit 1; fi

run-% : %.lob
	@cat $< - | $(SECD)

