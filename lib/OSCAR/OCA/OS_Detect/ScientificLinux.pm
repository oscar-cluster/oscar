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

package OSCAR::OCA::OS_Detect::ScientificLinux;

use strict;

my $distro = "scientific_linux";
my $compat_distro = "rhel";
my $pkg = "rpm";
my $detect_package = "sl-release";
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

    # complex match strings
    my $os_release;
    my $os_update;
    my $os_family; # Beryllium, etc... don't care about this
    if (($release_string =~ /Scientific Linux SL release (\d+)\.(\d+) \((\S+)\)/)
        || ($release_string =~ /Scientific Linux release (\d+)\.(\d+) \((\S+)\)/)) {
        $os_release = $1;
        $os_update = $2;
        $os_family = $3; # Beryllium, etc... don't care about this
    } else {
        return undef;
    }

    $id->{distro} = $distro;
    $id->{distro_version} = $os_release;
    $id->{distro_update} = $os_update;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $os_release;
    $id->{pkg} = $pkg;

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root,$detect_file);
    $id->{arch} = $arch;

    # determine services management subsystem (systemd, initscripts, manual)
    if ($id->{distro_version} <= 6) {
        $id->{service_mgt} = "initscripts";
    } else {
        $id->{service_mgt} = "systemd";
    }

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
