#
# Simple Makefile for building perl-Qt programs
#

SHELL = /bin/bash
# EF: Is puic in the path?
#     If not, try to locate it in some known places
ifeq "$(shell which puic 2>/dev/null)" ""
    find_puic = $(wildcard $(dir)/puic)
    dirs := /opt/kde3/bin /opt/perl-Qt/bin
    puicdir := $(dir $(firstword $(foreach dir,$(dirs),$(find_puic))))
    ifndef puicdir
        $(error "!! Could not locate puic (from perl-Qt package) !!")
    else
        export PATH := $(puicdir):$(PATH)
    endif
endif


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

