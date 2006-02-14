#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) Bernard Li <bli@bcgsc.ca>
# 
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#      - complete rewrite to enable use on top of images
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::Fedora;

use strict;

# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect {
    my ($root) = @_;
    my ($release_string, $fc_release);
    my $dfile = "/etc/fedora-release";

    # If /etc/fedora-release exists, continue, otherwise, quit.
    if (-f "$root$dfile") {
	$release_string = `cat $root$dfile`;
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    # We only support Fedora Core 2, 3, and 4 -- otherwise quit.
    if ($release_string =~ 'Stentz') {
	$fc_release = 4;
    } elsif ($release_string =~ 'Heidelberg') {
	$fc_release = 3;
    } elsif ($release_string =~ 'Tettnang') {
	$fc_release = 2;
    } else {
	return undef;
    }

    $id->{distro} = "fedora";
    $id->{distro_version} = $fc_release;
    $id->{compat_distro} = "fc";
    $id->{compat_distrover} = $fc_release;
    $id->{pkg} = "rpm";

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch($root);
    $id->{arch} = $arch;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}";

    return $id;
}

# If we got here, we're happy
1;
