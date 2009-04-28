#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2008 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#   $Id$
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This script checks the yum configuration file.

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use warnings;
use English '-no_match_vars';
use OSCAR::ConfigFile;

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = SUCCESS;

if ( -f "/etc/yum.conf" ) {
    # When you want the value of a key, the key name has to follow the AppConfig
    # syntax. It means that to access the key gpgcheck under the main section of
    # the configuration file, the key name is "main_gpgcheck".
    my $value = OSCAR::ConfigFile::get_value ("/etc/yum.conf",
                                              undef,
                                              "main_gpgcheck");
    if (defined ($value) && $value == 1) {
        print "----------------------------------------------\n";
        print " ERROR: Yum configuration is invalid\n";
        print " The gpgkey is set to 1, it will be impossible\n";
        print " to install OSCAR packages.\n";
        print " Please, set the gpgkey to 0 (\"gpgkey=0\" in \n";
        print "/etc/yum.conf).\n";
        print "----------------------------------------------\n";
        $rc = FAILURE;
    }
}

exit ($rc);
