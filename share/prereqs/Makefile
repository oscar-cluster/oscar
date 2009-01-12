SHAREDIR=usr/share/oscar/prereqs

SUBDIRS := AppConfig packman perl-Qt perl-XML-Parser base \
			OSCAR-Database perl-HTML-Tree perl-Tk perl-XML-Simple ORM \
			Selector Configurator

FILES := prereqs.order

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
