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
#      - enabled use on top of package pools
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::Mandriva;

use strict;

my $distro = "mandriva";
my $compat_distro = "mdv";
my $pkg = "rpm";
my $detect_package = "mandriva-release";
my $detect_file = "/bin/bash";

sub detect_dir {
    my ($root) = @_;
    my $release_string;
    my ($os_version,$os_version);

    # If /etc/mandriva-release exists, continue, otherwise, quit.
    if (-f "/etc/mandriva-release") {
	$release_string = `cat /etc/mandriva-release`;
    } else {
	return undef;
    }

    if ($release_string =~ /Mandriva Linux release (\d+)\.(\d+) /) {
	$os_version = $1;
	$os_release = $2;
    } else {
	return undef;
    }

    my $id = {
	os => "linux",
	chroot => $root,
    };

    $id->{distro} = $distro;
    $id->{distro_version} = $os_version;
    $id->{distro_release} = $os_release;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $os_version;
    $id->{pkg} = $pkg;

    # this hash contains all info necessary for identifying the OS

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

# If we got here, we're happy
1;
