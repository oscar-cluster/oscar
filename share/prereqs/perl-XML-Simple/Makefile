DESTDIR=
SHAREDIR=usr/share/oscar/prereqs
PREREQNAME=perl-XML-Simple

SUBDIRS := 
FILES := prereq.cfg

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	install -d -m 0755 $(DESTDIR)/$(SHAREDIR)/$(PREREQNAME)
	install    -m 0755 ${FILES} $(DESTDIR)/$(SHAREDIR)/$(PREREQNAME)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/$(SHAREDIR)/$(PREREQNAME); rm -f ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done
