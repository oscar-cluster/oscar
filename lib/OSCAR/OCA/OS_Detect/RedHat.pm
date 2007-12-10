#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) Bernard Li <bli@bcgsc.ca>
# 
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#      - complete rewrite to enable use on top of images
#      - enabled use on top of package pools
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::RedHat;

use strict;

my $distro = "redhat-el";
my $compat_distro = "rhel";
my $pkg = "rpm";
my $detect_package = "redhat-release";
my $detect_file = "/bin/bash";

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on a RHEL machine or not.
# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect_dir {
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

    # complex match strings
    if ($release_string =~
        /Red Hat Enterprise Linux (\S+) release (\d+) \((\S+) Update (\d+)\)/ 
	or $release_string =~
        /Red Hat Enterprise Linux (\S+) release (\d+|\d+\.\d+) \((\S+)\)/) {
	my $flavor = $1; # AS, WS, ES? This information is irrelevant for OSCAR
	my $os_release = $2;
	my $os_family = $3; # Nahant, blah...
	my $os_update = $4;

	# only support these two for now
	if ($os_family !~ /^(Taroon|Nahant|Tikanga)$/) {
	    return undef;
	}

	$id->{distro} = $distro."-".lc($flavor);
	$id->{distro_version} = $os_release;
	$id->{distro_update} = $os_update;
	$id->{compat_distro} = $compat_distro;
	$id->{compat_distrover} = $os_release;
	$id->{pkg} = $pkg;

    } else {
	return undef;
    }

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root,$detect_file);
    $id->{arch} = $arch;

    # Make final string
    # [EF: does anybody care about this ugly string at all? The information
    #      is redundant and can be construted anytime.]
    $id->{distro_update} = ""  if !$id->{distro_update};
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";

    return $id;
}

sub detect_pool {
    my ($pool) = @_;

    my $id = main::OSCAR::OCA::OS_Detect::detect_pool_rpm($pool,
							  $detect_package,
							  $distro,
							  $compat_distro);

    return $id;
}

sub detect_fake {
    my ($fake) = @_;
    my $id = main::OSCAR::OCA::OS_Detect::detect_fake_common($fake,
							     $distro,
							     $compat_distro,
							     $pkg);
    return $id;
}

sub detect_oscar_pool ($) {
    my $pool = shift;
    my $ret = main::OSCAR::OCA::OS_Detect::detect_oscar_pool_common($pool,
        $compat_distro);

    if ($ret) {
        # The component can use the OSCAR pool
        my $id = {
            os => "linux",
        };
        $id->{distro} = $distro;
        $id->{pkg} = $pkg;
        return $id;
    } else {
        return undef;
    }
}

# If we got here, we're happy

1;
