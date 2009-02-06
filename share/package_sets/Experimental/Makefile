NAME=Experimental
SHAREDIR=usr/share/oscar/package_sets/$(NAME)

SUBDIRS := 

FILES := debian-4-i386.xml 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	install -d -m 0755 $(DESTDIR)/$(SHAREDIR)
	install    -m 0755 ${FILES} $(DESTDIR)/$(SHAREDIR)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/$(SHAREDIR); rm -f ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done
