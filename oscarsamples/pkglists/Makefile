TARGETDIR=usr/share/oscar/oscarsamples/pkglists

SUBDIRS := 
FILES :=                                 debian-8-x86_64.pkglist \
                                         debian-9-x86_64.pkglist \
                                         ubuntu-1404-x86_64.pkglist \
                                         fedora-27-x86_64.pkglist \
         redhat-el-6-i386.pkglist        redhat-el-6-x86_64.pkglist \
                                         redhat-el-7-x86_64.pkglist \
         centos-6-i386.pkglist           centos-6-x86_64.pkglist \
                                         centos-7-x86_64.pkglist \
         scientific_linux-6-i386.pkglist scientific_linux-6-x86_64.pkglist \
                                         scientific_linux-7-x86_64.pkglist \
                                         suse-42.3-x86_64.pkglist \
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
