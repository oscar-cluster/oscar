# -*- makefile -*-
#
# Copyright (c) 2002 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the LICENSE file in the top level directory of the
# OSCAR source distribution.
#
# $Id: Makefile.am,v 1.3 2002/10/26 12:05:55 jsquyres Exp $
#

# This file is necessary -- we can't use the OSCAR
# Makefile.am-generator because we don't want to ship all the files
# that will be in this directory (e.g., config.xml) because a) they
# will be generated at autogen.sh time, and b) there will be extra
# kruft in here as a result of running the setup script (e.g.,
# config.log, config.status).

AUTOCONF_GENERATED	= setup
AUTOGEN_GENERATED	= config.guess config.sub install-sh
GENERATED_FILES		= $(AUTOCONF_GENERATED) $(AUTOGEN_GENERATED)

EXTRA_DIST = setup.ac config.xml.in $(GENERATED_FILES)

dist-hook: $(GENERATED_FILES)

setup:
	sh ./autogen.sh

config.guess: setup
config.sub: setup
install-sh: setup

CLEANFILES = *~ $(GENERATED_FILES)
