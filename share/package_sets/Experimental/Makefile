NAME=Experimental
SHAREDIR=usr/share/oscar/package_sets/$(NAME)

SUBDIRS := 

FILES :=				debian-10-x86_64.xml \
		                  	debian-11-x86_64.xml \
		rhel-6-i386.xml   	rhel-6-x86_64.xml \
				   	rhel-7-x86_64.xml \
				   	rhel-8-x86_64.xml \
					fc-30-x86_64.xml \
					suse-15-x86_64.xml

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
