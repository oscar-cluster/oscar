#!/usr/bin/env perl
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

package OCA::OS_Detect::CentOS;

use strict;

sub detect {
    my ($root) = @_;
    my $release_string;

    # If /etc/redhat-release exists, continue, otherwise, quit.
    if (-f "$root/etc/redhat-release") {
	$release_string = `cat $root/etc/redhat-release`;
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    # complex match strings for RHEL 3 and 4
    if ($release_string =~ /CentOS release (\d+)\.(\d+) \((\S+)\)/) {
	my $os_release = $1;
	my $os_update = $2;
	my $os_family = $3; # don't care about this
	$id->{distro} = "centos";
	$id->{distro_version} = $os_release;
	$id->{distro_update} = $os_update;
	$id->{compat_distro} = "rhel";
	$id->{compat_distrover} = $os_release;
	$id->{pkg} = "rpm";
    } else {
	return undef;
    }

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch($root);
    $id->{arch} = $arch;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
    return $id;
}

# If we got here, we're happy
1;
