SHAREDIR=usr/share/oscar/images

FILES := oscar.gif

all:

install:
	install -d -m 0755 $(DESTDIR)/$(SHAREDIR)
	install    -m 0755 ${FILES} $(DESTDIR)/$(SHAREDIR)

uninstall:
	cd $(DESTDIR)/$(SHAREDIR); rm -f ${FILES}

clean:
	rm -f *~
