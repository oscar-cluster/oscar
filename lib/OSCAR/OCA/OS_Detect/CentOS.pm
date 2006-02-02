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
# $Id: RedHat.pm 3865 2005-10-28 04:51:56Z bli $
#

package OCA::OS_Detect::CentOS;

use strict;

# query returns a reference to the ID hash or undef if the current package
# doesn't fit to the queried distribution
sub query {
    my %opt = @_;
    if (exists($opt{chroot})) {
	if (-d $opt{chroot}) {
	    return detect($opt{chroot});
	} else {
	    print STDERR "WARNING: Path $opt{chroot} does not exist!\n";
	    return undef;
	}
    } else {
	return detect("/");
    }
}

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on a RHEL machine or not.
# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
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
    } else {
	return undef;
    }

    # determine architecture
    my $arch = detect_arch($root);
    $id->{arch} = $arch;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
    return $id;
}

# Determine architecture by checking the executable type of a wellknown
# program
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
