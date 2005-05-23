#!/usr/bin/perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OCA::OS_Detect::OSX;

use strict;
use POSIX;
use Config;

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on an OS X machine or not.

# Check uname

my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

# We only support Darwin -- if we're not Darwin, then quit

return 0 if ("Darwin" ne $sysname);

# So we know we're on Darwin.  Now check to ensure we've got a
# supported OSX release.  Currently, this is only 10.3.

return 0 if ($release !~ /^7\./);

# Alles gut.  So save some additional information.  OS X has a command
# named "machine" that returns the machine / chip type.

# First set of data

our $id = {
    os => "osx",
    arch => "ppc",
    os_release => $release,
};

my $machine;
if (! open M, "machine|") {
    $machine = <M>;
    chomp($machine);
    $id->{machine} = $machine;
    if ($machine !~ /^ppc/) {
        $id->{arch} = $machine;
    }
    close M;
}

# Make final string

$id->{ident} = "osx-$id->{arch}-$id->{os_release}";

# Once all this has been setup, whenever someone invokes the "query"
# method on this component, we just return the pre-setup data.

sub query {
    our $id;
    return $id;
}

# If we got here, we're happy

1;
