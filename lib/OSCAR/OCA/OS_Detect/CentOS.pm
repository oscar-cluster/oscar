#!/usr/bin/env perl
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

package OCA::OS_Detect::CentOS;

use strict;

my $distro = "centos";
my $compat_distro = "rhel";
my $pkg = "rpm";
my $detect_package = "centos-release";
my $detect_file = "/bin/bash";

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

    # complex match strings for RHEL 3 and 4
    if ($release_string =~ /CentOS release (\d+)\.(\d+) \((\S+)\)/) {
	my $os_release = $1;
	my $os_update = $2;
	my $os_family = $3; # don't care about this
	$id->{distro} = $distro;
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

# If we got here, we're happy
1;
