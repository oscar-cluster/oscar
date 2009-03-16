TARGETDIR=usr/share/oscar/oscarsamples

SUBDIRS := 
FILES := debian-4-i386.rpmlist fc-5-i386.rpmlist fc-8-x86_64.rpmlist \
		rhel-3-ia64.rpmlist rhel-4-x86_64.rpmlist suse-10.0-i386.rpmlist \
		debian-4-x86_64.rpmlist fc-5-x86_64.rpmlist fc-9-x86_64.rpmlist \
		rhel-3u2-i386.rpmlist rhel-5-i386.rpmlist suse-10.2-x86_64.rpmlist \
		fc-3-i386.rpmlist fc-6-i386.rpmlist ide.disk rhel-3u2-ia64.rpmlist \
		rhel-5-x86_64.rpmlist suse-10.3-x86_64.rpmlist fc-3-x86_64.rpmlist \
		fc-7-i386.rpmlist rhel-3-x86_64.rpmlist scsi.disk swraid1-scsi.disk \
		fc-4-i386.rpmlist fc-7-x86_64.rpmlist mdv-2006-i386.rpmlist \
		rhel-4-i386.rpmlist scsi.ia64.disk ydl-5-ppc64.rpmlist \
		fc-4-x86_64.rpmlist fc-8-i386.rpmlist rhel-3-i386.rpmlist \
		rhel-4-ia64.rpmlist scsi.ppc64-ps3.disk fc-10-x86_64.rpmlist \
		centos-5.2-x86_64.rpmlist ubuntu-8.04-i386.rpmlist \
		suse-10.0-x86_64.rpmlist

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	install -d -m 0755 $(DESTDIR)/$(TARGETDIR)
	install    -m 0755 ${FILES} $(DESTDIR)/$(TARGETDIR)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/$(TARGETDIR); rm -f ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done
