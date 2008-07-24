CONFIGDIR=etc/oscar

install:
	install -d -m 0755 $(DESTDIR)/$(CONFIGDIR)
	install -d -m 0755 $(DESTDIR)/$(CONFIGDIR)/templates
	install    -m 0755 etc/supported_distros.txt $(DESTDIR)/$(CONFIGDIR)
	install    -m 0755 etc/templates/oscar.conf $(DESTDIR)/$(CONFIGDIR)/templates

uninstall:
	rm -f $(DESTDIR)/$(CONFIGDIR)/supported_distros.txt
	rm -f $(DESTDIR)/$(CONFIGDIR)/templates/oscar.conf
