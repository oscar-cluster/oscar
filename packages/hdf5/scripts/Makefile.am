# -*- makefile -*-
#
# Copyright (c) 2002 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the LICENSE file in the top level directory of the
# OSCAR source distribution.
#
# $Id: Makefile.am,v 1.2 2002/10/25 17:21:19 jsquyres Exp $
#

# This file is necessary -- we can't use the OSCAR
# Makefile.am-generator because we don't want to ship all the files
# that will be in this directory (e.g., config.xml) because a) they
# will be generated at autogen.sh time, and b) there will be extra
# kruft in here as a result of running the setup script (e.g.,
# config.log, config.status).

EXTRA_DIST = \
	setup setup.ac config.xml.in \
	config.guess config.sub install-sh

dist-hook:
	sh ./autogen.sh
