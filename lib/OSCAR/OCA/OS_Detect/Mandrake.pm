#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2005 Bernard Li <bli@bcgsc.ca>
#                    All rights reserved.
# Copyright (c) 2005, Revolution Linux
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OCA::OS_Detect::Mandrake;

use strict;
use POSIX;
use Config;

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on a Mandrake machine or not.

# Check uname

my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

# We only support Linux -- if we're not Linux, then quit

return 0 if ("Linux" ne $sysname);

my $mandrake_release;

# If /etc/mandrake-release exists, continue, otherwise, quit.

if (-e "/etc/mandrake-release")  {
	$mandrake_release = `cat /etc/mandrake-release`;
} else {
	return 0;
}

# We only support Mandrake 10.0 and 10.1 -- otherwise quit.

if ($mandrake_release =~ '10.0') {
	$mandrake_release = 10.0;
} elsif ($mandrake_release =~ '10.1') {
	$mandrake_release = 10.1;
} else {
	return 0;
}

# First set of data

our $id = {
    os => "linux",
    arch => $machine,
    os_release => $release,
    linux_distro => "mandrake",
    linux_distro_version => $mandrake_release
};

# Make final string

$id->{ident} = "$id->{os}-$id->{arch}-$id->{os_release}-$id->{linux_distro}-$id->{linux_distro_version}";

# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}

# If we got here, we're happy

1;
