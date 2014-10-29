PERL    = perl
RM      = rm -rf
TAR     = tar
GZIP    = gzip
DISTDIR = Source
VERSION = $(shell cat Source/ExpectMSU.pm | grep 'VERSION =' | cut -d\' -f2)
FILE	= ExpectMSU_$(VERSION)

default:
	@echo "all, build, install, clean, or dist?"

update: all dist

all:
	$(MAKE) clean && $(MAKE) build && $(MAKE) install && $(MAKE) test

clean:
	cd $(DISTDIR) && $(RM) Makefile pm_to_blib blib

dist:
	$(MAKE) clean
	cd .. && $(TAR) -cf $(FILE).tar ExpectMSU
	$(GZIP) -f ../$(FILE).tar

build:
	cd $(DISTDIR) && $(PERL) Makefile.PL
	cd $(DISTDIR) && $(MAKE)

install:
	cd $(DISTDIR) && $(MAKE) install

test:
	@perl -MExpectMSU -e 'print "\nExpectMSU loads properly.\n\n"'
	@echo ""
	@echo "Testing not yet implemented..."
	@echo ""
	cd $(DISTDIR) && $(MAKE) test
