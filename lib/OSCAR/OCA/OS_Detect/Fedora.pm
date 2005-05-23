#!/usr/bin/env perl
#
# Copyright (c) 2005 Bernard Li <bli@bcgsc.ca>
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OCA::OS_Detect::Fedora;

use strict;
use POSIX;
use Config;

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on a Fedora machine or not.

# Check uname

my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

my $redhat_release = `cat /etc/redhat-release`;
my $fc_release;

# We only support Fedora Core 2 and 3, otherwise quit.

if ($redhat_release =~ 'Heidelberg') {
	$fc_release = 3;
} elsif ($redhat_release =~ 'Tettnang') {
	$fc_release = 2;
} else {
	return 0;
}

# First set of data

our $id = {
    os => "fedora",
    arch => $machine,
    os_release => $fc_release,
};

# Make final string

$id->{ident} = $id->{os} . "-" . $id->{arch} . "-" . $id->{os_release};

# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}

# If we got here, we're happy

1;
