# -*- makefile -*-
#
# Copyright (c) 2002 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the LICENSE file in the top level directory of the
# OSCAR source distribution.
#
# $Id: Makefile.am,v 1.1 2002/10/29 03:14:05 jsquyres Exp $
#

EXTRA_DIST	= post_client_rpm_install 

disable_files	= \
	disable.incoming-mail \
	disable.kudzu \
	disable.slocate \
	disable.whatis

post_client_rpm_install: $(disable_files)
	@ rm -f $@; \
	  for file in $(disable_files); \
	  do \
	    cat $$file >> $@; \
	  done; \
	  chmod +x $@
