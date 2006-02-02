#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) Bernard Li <bli@bcgsc.ca>
#                    All rights reserved.
# Copyright (c) 2005, Revolution Linux
#
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#                    All rights reserved.
#      - complete rewrite to enable use on top of images
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::Mandrake;

use strict;

sub detect {
    my ($root) = @_;
    my $mandrake_release;

    # If /etc/mandrake-release exists, continue, otherwise, quit.
    if (-f "/etc/mandrake-release")  {
	$mandrake_release = `cat /etc/mandrake-release`;
    } else {
	return undef;
    }

    # We only support Mandrake 10.0 and 10.1 -- otherwise quit.
    if ($mandrake_release =~ '10.0') {
	$mandrake_release = 10.0;
    } elsif ($mandrake_release =~ '10.1') {
	$mandrake_release = 10.1;
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    $id->{distro} = "mandrake";
    $id->{distro_version} = $mandrake_release;
    $id->{compat_distro} = "mdk";
    $id->{compat_distrover} = $mandrake_release;
    $id->{pkg} = "rpm";

    # determine architecture
    my $arch = detect_arch($root);
    $id->{arch} = $arch;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";

    return $id;
}

# Determine architecture by checking the executable type of a wellknown
# program [EF: this code should be shared]
sub detect_arch {
    my ($root) = @_;
    my $arch="unknown";
    my $q = `env LC_ALL=C file $root/bin/bash`;
    if ($q =~ m/executable,\ \S+\ (\S+),\ version/) {
	$arch = $1;
	if ($arch =~ m/386$/) {
	    $arch = "i386";
	}
    }
    return $arch;
}

# If we got here, we're happy
1;
