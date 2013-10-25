TARGETDIR=usr/share/oscar/oscarsamples

SUBDIRS := 
FILES := debian-4-i386.rpmlist debian-4-x86_64.rpmlist \
	debian-5-i386.rpmlist debian-5-x86_64.rpmlist \
	ubuntu-804-i386.rpmlist ubuntu-904-x86_64.rpmlist ubuntu-1004-x86_64.rpmlist ubuntu-1204-x86_64.rpmlist \
	ubuntu-1210-x86_64.rpmlist \
	fc-3-i386.rpmlist fc-3-x86_64.rpmlist \
	fc-4-i386.rpmlist fc-4-x86_64.rpmlist \
	fc-5-i386.rpmlist fc-5-x86_64.rpmlist \
	fc-6-i386.rpmlist \
	fc-7-i386.rpmlist fc-7-x86_64.rpmlist \
	fc-8-i386.rpmlist fc-8-x86_64.rpmlist \
	                  fc-9-x86_64.rpmlist \
	                  fc-10-x86_64.rpmlist \
	                  fedora-17-x86_64.rpmlist \
	                  fedora-18-x86_64.rpmlist \
	                  fedora-19-x86_64.rpmlist \
	rhel-3-i386.rpmlist rhel-3-ia64.rpmlist rhel-3-x86_64.rpmlist \
	rhel-3u2-i386.rpmlist rhel-3u2-ia64.rpmlist \
	rhel-4-i386.rpmlist rhel-4-ia64.rpmlist rhel-4-x86_64.rpmlist \
	rhel-5-i386.rpmlist rhel-5-x86_64.rpmlist \
	redhat-el-5-i386.rpmlist redhat-el-5-x86_64.rpmlist \
	centos-5-i386.rpmlist centos-5-x86_64.rpmlist \
	centos-6-i386.rpmlist centos-6-x86_64.rpmlist \
	scientific_linux-5-i386.rpmlist scientific_linux-5-x86_64.rpmlist \
	scientific_linux-6-i386.rpmlist scientific_linux-6-x86_64.rpmlist \
	suse-10.0-i386.rpmlist suse-10.0-x86_64.rpmlist \
	                       suse-10.2-x86_64.rpmlist \
	                       suse-10.3-x86_64.rpmlist \
	                       suse-12.3-x86_64.rpmlist \
	mdv-2006-i386.rpmlist \
	ydl-5-ppc64.rpmlist \
	ide-pata.disk ide-sata.disk \
	scsi.disk swraid1-scsi.disk scsi.ia64.disk scsi.ppc64-ps3.disk \
	cciss.disk

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
