DESTDIR=
LIBDIR=`perl -V:vendorarch | sed s/vendorarch=\'// | sed s/\'\;//`

all:

install:
	@echo Creating $(DESTDIR)/$(LIBDIR)/OSCAR
	@mkdir -p $(DESTDIR)/$(LIBDIR)/OSCAR
	cp *.pm $(DESTDIR)/$(LIBDIR)/OSCAR
