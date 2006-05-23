#


SUBDIRS = Selector Opder NodeMgmt NodeGroupLister Installer 

all:
	list='$(SUBDIRS)'; for subdir in $$list; do \
	  echo "Making build in $$subdir"; \
	  (cd $$subdir && $(MAKE) all) || exit 1; \
	done

install:
	list='$(SUBDIRS)'; for subdir in $$list; do \
	  echo "Making install in $$subdir"; \
	  (cd $$subdir && $(MAKE) install) || exit 1; \
	done

clean:
	list='$(SUBDIRS)'; for subdir in $$list; do \
	  echo "Making clean in $$subdir"; \
	  (cd $$subdir && $(MAKE) clean) || exit 1; \
	done

