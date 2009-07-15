#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2008 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
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
    # We want to make sure the gpg check is deactivate for the OSCAR repos. For
    # that two solutions: this is deactivated in the config file specific to
    # the OSCAR repo or this is deactivated in the main configuration file.

    # Check if the oscar repo has been added to /etc/yum.repos.d
    my $value;
    my $file = `grep bison.csm.ornl.gov /etc/yum.repos.d/* | awk -F':' '{print \$1}'`;
    chomp $file;

    if ($file ne "") {
        # When you want the value of a key, the key name has to follow the AppConfig
        # syntax. It means that to access the key gpgcheck under the main section of
        # the configuration file, the key name is "oscar_gpgcheck".
        $value = OSCAR::ConfigFile::get_value ($file,
                                                  undef,
                                                  "oscar_gpgcheck");
        if (defined ($value) && $value == 1) {
            print "----------------------------------------------\n";
            print " ERROR: Yum configuration is invalid\n";
            print " The gpgcheck is set to 1, it will be impossible\n";
            print " to install OSCAR packages.\n";
            print " Please, set the gpgcheck to 0 (\"gpgcheck=0\" in \n";
            print "$file).\n";
            print "----------------------------------------------\n";
            $rc = FAILURE;
        }
    } else { 
        print "[WARN] Could not find oscar repo in /etc/yum.repos.d/.".
              "Checking /etc/yum.conf...\n";

        $value = OSCAR::ConfigFile::get_value ("/etc/yum.conf",
                                               undef,
                                               "main_gpgcheck");
        if (defined ($value) && $value == 1) {
            print "----------------------------------------------\n";
            print " ERROR: Yum configuration is invalid\n";
            print " The gpgcheck is set to 1, it will be impossible\n";
            print " to install OSCAR packages.\n";
            print " Please, set the gpgcheck to 0 (\"gpgcheck=0\" in \n";
            print "/etc/yum.conf).\n";
            print "----------------------------------------------\n";
            $rc = FAILURE
        }
    }
}

exit ($rc);
