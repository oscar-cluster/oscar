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

package OCA::RM_Detect::TORQUE;

use strict;
use XML::Simple;

my $pkg = "torque";
my $pkg_dir = "$ENV{OSCAR_HOME}/packages/$pkg";
my $pkg_config = "$pkg_dir/config.xml";

my $xml_ref = undef;
my $xs = new XML::Simple();
$xml_ref = eval { $xs->XMLin( $pkg_config ); };

my $displayname = "TORQUE";
my $test = "pbs_test";
my $jobscript = "pbs_script";

# First set of data

our $id = {
    name => $displayname,
    pkg => $pkg,
    major => $xml_ref->{version}->{major},
    minor => $xml_ref->{version}->{minor},
    subversion => $xml_ref->{version}->{subversion},
    test => "/usr/lib/oscar/testing/$pkg/$test",
    jobscript => $jobscript,
};

# Make final string

$id->{ident} = "$id->{pkg}-$id->{major}.$id->{minor}.$id->{subversion}";

# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}

# If we got here, we're happy

1;
