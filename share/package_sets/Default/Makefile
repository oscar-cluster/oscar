SHAREDIR=usr/share/oscar/package_sets/Default

SUBDIRS := 

FILES := debian-4-i386.xml fc-6-x86_64.xml rhel-4-i386.xml suse-10-x86_64.xml \
		debian-4-x86_64.xml fc-7-i386.xml rhel-4-x86_64.xml fc-5-i386.xml \
		fc-7-x86_64.xml rhel-5-i386.xml fc-6-i386.xml rhel-5-x86_64.xml \
		fc-10-x86_64.xml debian-5-x86_64.xml

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
