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

package OCA::OS_Detect::Mandriva;

use strict;

sub detect {
    my ($root) = @_;
    my $mandriva_release;

    # If /etc/mandriva-release exists, continue, otherwise, quit.

    if (-f "/etc/mandriva-release") {
	$mandriva_release = `cat /etc/mandriva-release`;
    } else {
	return undef;
    }

    # We only support Mandriva 2006 -- otherwise quit.

    if ($mandriva_release =~ /2006/) {
	$mandriva_release = 2006;
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    $id->{distro} = "mandriva";
    $id->{distro_version} = $mandriva_release;
    $id->{compat_distro} = "mdv";
    $id->{compat_distrover} = $mandriva_release;
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
