TARGETDIR=usr/share/oscar/oscarsamples/diskfiles

SUBDIRS := 
FILES := ide-pata.disk ide-sata.disk \
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
