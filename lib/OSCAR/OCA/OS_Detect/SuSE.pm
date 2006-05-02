#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2005-2006 Bernard Li <bli@bcgsc.ca>
#                         All rights reserved.
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

package OCA::OS_Detect::SuSE;

use strict;

my $distro = "suse";
my $compat_distro = "suse";
my $pkg = "rpm";
my $detect_package = "SuSE-release";
my $detect_file = "/bin/bash";

sub detect_dir {
    my ($root) = @_;
    my $release_string;

    # If /etc/SuSE-release exists, continue, otherwise, quit.
    if (-f "/etc/$detect_package") {
	$release_string = `cat /etc/$detect_package`;
    } else {
	return undef;
    }

    my $id = {
	os => "linux",
	chroot => $root,
    };

    if ($release_string =~ /SuSE Linux (\d+)\.(\d+) /) {
	my $os_version = $1;
        $id->{distro} = $distro;
        $id->{distro_version} = $os_version;
        $id->{compat_distro} = $compat_distro;
        $id->{compat_distrover} = $os_version;
        $id->{pkg} = $pkg;
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root,$detect_file);
    $id->{arch} = $arch;

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_release}";

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
