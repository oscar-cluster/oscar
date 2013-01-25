DESTDIR=
TOP_DIR = ..
include $(TOP_DIR)/Config.mk

SUBDIRS := 
FILES := macros.oscar

all:
	cat macros.oscar.in > macros.oscar
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install: all
	@echo Creating $(DESTDIR)/etc/rpm
	install -d -m 0755 $(DESTDIR)/etc/rpm
	install    -m 0755 ${FILES} $(DESTDIR)/etc/rpm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)/etc/rpm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f ${FILES}
	rm -f *~
