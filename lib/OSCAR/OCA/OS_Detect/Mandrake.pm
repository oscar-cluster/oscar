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

package OCA::OS_Detect::Mandrake;

use strict;

my $distro = "mandrake";
my $compat_distro = "mdk";
my $pkg = "rpm";
my $detect_package = "mandrake-release";
my $detect_file = "/bin/bash";

sub detect_dir {
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

    $id->{distro} = $distro;
    $id->{distro_version} = $mandrake_release;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $mandrake_release;
    $id->{pkg} = $pkg;

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
