DESTDIR=

include ./Config.mk

SUBDIRS := OCA

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR
	@mkdir -p $(DESTDIR)$(LIBDIR)/OSCAR
	cp *.pm $(DESTDIR)$(LIBDIR)/OSCAR
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
