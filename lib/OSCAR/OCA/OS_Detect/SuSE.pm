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

package OSCAR::OCA::OS_Detect::SuSE;

use strict;

my $distro = "suse";
my $compat_distro = "suse";
my $pkg = "rpm";
my $detect_package = "suse-release";
my $detect_file = "/bin/bash";

sub detect_dir {
    my ($root) = @_;
    my $release_string;

    # If /etc/SuSE-release exists, continue, otherwise, quit.
    if (-f "$root/etc/SuSE-release") {
        $release_string = `cat $root/etc/SuSE-release`;
    } else {
        return undef;
    }

    my $id = {
        os => "linux",
        chroot => $root,
    };

    if (($release_string =~ /SUSE LINUX (\d+)\.(\d+)/) ||
        ($release_string =~ /openSUSE (\d+)\.(\d+) /)) {
        my $os_version = $1;
        my $os_update = $2;
        $id->{distro} = $distro;
        $id->{distro_upgrade} = $os_update;
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

    # determine services management subsystem (systemd, initscripts, manual)
    if ($id->{distro_version} <= 12) {
        $id->{service_mgt} = "initscripts";
    } else {
        $id->{service_mgt} = "systemd"; # In use since 12.1
    }

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}";

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
                                                             undef,
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
