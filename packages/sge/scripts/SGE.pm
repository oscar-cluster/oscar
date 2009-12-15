#!/usr/bin/env perl
#
# Copyright (c) 2005 Bernard Li <bli@bcgsc.ca>.
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OCA::RM_Detect::SGE;

use strict;
use XML::Simple;

my $displayname = "SGE";
my $test = "sge_test";
my $jobscript = "sge_script";
my $pkg = "sge";
my $pkg_dir;

if (defined $ENV{OSCAR_HOME}) {
    $pkg_dir = "$ENV{OSCAR_HOME}/packages/$pkg";
    $test = "$pkg_dir/testing/$test";
} else {
    $pkg_dir = "/var/lib/oscar/packages/$pkg";
    $test = "/var/lib/oscar/testing/$pkg/$test"
}
my $pkg_config = "$pkg_dir/config.xml";

my $xml_ref = undef;
my $xs = new XML::Simple();
$xml_ref = eval { $xs->XMLin( $pkg_config ); };

# First set of data

our $id = {
    name => $displayname,
    pkg => $pkg,
    major => $xml_ref->{version}->{major},
    minor => $xml_ref->{version}->{minor},
    test => "$test",
    jobscript => "$jobscript",
    gui => "qmon",
};

# Make final string

$id->{ident} = "$id->{pkg}-$id->{major}.$id->{minor}";

# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}

# If we got here, we're happy

1;
