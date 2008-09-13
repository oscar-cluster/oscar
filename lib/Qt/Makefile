DESTDIR=

TOPDIR = ..
include $(TOPDIR)/Config.mk

SUBDIRS := 

FILES := OpderAbout.pm OpderAddRepository.pm OpderDownloadInfo.pm \
		 OpderDownloadPackage.pm OpderImages.pm Opder.pl OpderTable.pm

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/Qt
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/Qt
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/Qt
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(LIBDIR)/Qt; rm -rf ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
