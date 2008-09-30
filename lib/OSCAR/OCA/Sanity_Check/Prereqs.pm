#!/usr/bin/env perl
#
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#
# This file check the status of prereqs (installed or not).

package OCA::Sanity_Check::Prereqs;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::ConfigManager;
use OSCAR::FileUtils;
use OSCAR::Utils;
use Carp

my $oscar_configurator = OSCAR::ConfigManager->new();
my $config = $oscar_configurator->get_config();

my $prereqs_path = $config->{'prereqs_path'};
my $scripts_path = $config->{'scripts_path'};

print "Prereqs available at: $prereqs_path\n";
print "Scripts available at: $scripts_path\n";

my $ipscript = $scripts_path . "/install_prereqs ";

my @entries = OSCAR::FileUtils::get_directory_content ($prereqs_path);
if (scalar (@entries) == 0) {
    carp "ERROR: Impossible to find the prereqs dir ($prereqs_path)\n";
    exit 0;
}

foreach my $e (@entries) {
    my $path = "$prereqs_path/$e";
    if ( -d  "$path") {
        print "Checking prereqs status $e ($path)\n";
        my $cmd = "$scripts_path/install_prereq $path --status";
        if (system ($cmd)) {
            print "ERROR: impossible to get the status of the prereqs $e\n";
            exit 0;
        }
    }
}

1;
