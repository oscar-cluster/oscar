# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) Bernard Li <bli@bcgsc.ca>
# Copyright (c) Paul Greidanus <paul@majestik.org>
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#
# $Id: RedHat.pm 3865 2005-10-28 04:51:56Z bli $
#

package OCA::OS_Detect::ScientificLinux;

use strict;
use POSIX;
use Config;

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on a Scientific Linux machine or not.

# Check uname

my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

# We only support Linux -- if we're not Linux, then quit

return 0 if ("Linux" ne $sysname);

my $sl_release;
my $distro;
my $distro_ver;

# If /etc/redhat-release exists, continue, otherwise, quit.
if (-e "/etc/redhat-release") {
	$sl_release = `cat /etc/redhat-release`;
} else {
	return 0;
}

# We only support ScientificLinux 4.1, otherwise quit.
if ($sl_release =~ 'Beryllium' &&
    $sl_release =~ m/release 4.1/ ) {
    $distro_ver = 4;
} else {
    return 0;
}

if ($sl_release =~ /Scientific Linux SL release/ ) {
    $distro = "redhat-el-ws";
} else {
    return 0;
}

# First set of data

our $id = {
    os => "linux",
    arch => $machine,
    os_release => $release,
    linux_distro => $distro,
    linux_distro_version => $distro_ver,
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
