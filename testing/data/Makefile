DESTDIR=
INSTALLDIR=/usr/lib/oscar/testing/data/base

CONTENT=*

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	if test -n "$(CONTENT)"; then \
		install -d -m 0755 $(DESTDIR)$(INSTALLDIR) \
		cp -r $(CONTENT)  $(DESTDIR)$(INSTALLDIR)/ \
	fi

uninstall:
	rm -rf $(DESTDIR)$(INSTALLDIR)

clean:
	rm -f *~
