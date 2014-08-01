TARGETDIR=usr/share/oscar/oscarsamples/pkglists

SUBDIRS := 
FILES := debian-4-i386.pkglist           debian-4-x86_64.pkglist \
         debian-5-i386.pkglist           debian-5-x86_64.pkglist \
                                         ubuntu-1004-x86_64.pkglist \
                                         ubuntu-1204-x86_64.pkglist \
                                         ubuntu-1210-x86_64.pkglist \
                                         fedora-17-x86_64.pkglist \
                                         fedora-18-x86_64.pkglist \
                                         fedora-19-x86_64.pkglist \
                                         fedora-20-x86_64.pkglist \
         redhat-el-5-i386.pkglist        redhat-el-5-x86_64.pkglist \
         redhat-el-6-i386.pkglist        redhat-el-6-x86_64.pkglist \
                                         redhat-el-7-x86_64.pkglist \
         centos-5-i386.pkglist           centos-5-x86_64.pkglist \
         centos-6-i386.pkglist           centos-6-x86_64.pkglist \
                                         centos-7-x86_64.pkglist \
         scientific_linux-5-i386.pkglist scientific_linux-5-x86_64.pkglist \
         scientific_linux-6-i386.pkglist scientific_linux-6-x86_64.pkglist \
                                         scientific_linux-7-x86_64.pkglist \
         suse-10.0-i386.pkglist          suse-10.0-x86_64.pkglist \
                                         suse-10.2-x86_64.pkglist \
                                         suse-10.3-x86_64.pkglist \
                                         suse-12.3-x86_64.pkglist \
         mdv-2006-i386.pkglist \
                                         ydl-5-ppc64.pkglist

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
