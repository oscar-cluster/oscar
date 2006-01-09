# -*- makefile -*-
#
# Copyright (c) 2004, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id$
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

include $(top_srcdir)/dist/Makefile.options

oscar_SCRIPTS		= \
			allow_client_access \
			c3_conf_manager \
			client_status \
			create_and_populate_basic_node_info \
			generic-setup \
			get_num_proc \
			install_server \
			integrate_image \
			mac_collector \
			macinfo2sis \
			make_database_password \
		        manage_cluster \
			opd \
			oscar_wizard \
			package_config_xmls_to_database \
			ping_clients \
			populate_default_package_set \
			post_clients \
			post_install \
			post_rpm_install \
			set_global_oscar_values \
			set_node_nics \
			set_oscar_interface \
			setup_pxe \
			ssh_install \
			start_over \
			wizard_prep

# This is somewhat of a break in the abstraction; we have to install
# to /etc/profile.d directly (i.e., not under the $prefix).  Note that
# at least Automake will automatically handle $(DESTDIR) correctly.

profile_ddir		= /etc/profile.d
profile_d_SCRIPTS	= oscar_home.sh oscar_home.csh

EXTRA_DIST		= $(oscar_SCRIPTS)

uninstall-local:
	rm -f $(profile_ddir)/oscar_home.sh
	rm -f $(profile_ddir)/oscar_home.csh

