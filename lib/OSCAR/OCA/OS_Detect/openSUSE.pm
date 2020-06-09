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
# Copyright (c) 2020 Olivier Lahaye <olivier.lahaye@cea.fr>
#      - Add support for /etc/os-release
#      - Add support for platform_id, pkg_mgr, service_mgt, pretty_name
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OSCAR::OCA::OS_Detect::openSUSE;

use strict;

my $distro = "opensuse";
my $compat_distro = "suse";
my $pkg = "rpm";
my $detect_package = "openSUSE-release"; # rpm package name containing /etc/os-release
my $detect_file = "/bin/bash";

sub detect_dir {
    my ($root) = @_;
    my $release_string;

    # this hash contains all info necessary for identifying the OS
    my $id = {
        os => "linux",
        chroot => $root,
    };

    my %os_release = main::OSCAR::OCA::OS_Detect::parse_os_release($root);

    if (%os_release) {
        return undef if ( $os_release{NAME} !~ /^openSUSE/); # Refuse to match "SLES" or "SLED"
        $id->{distro_version} = $os_release{VERSION_ID};
        # In case the version number and the update number are all together, we
        # explicitely make the distinction
        if ($id->{distro_version} =~ /(\d+).(\d+)/) {
            $id->{distro_version} = $1;
            $id->{distro_update} = $2;
        }
        $id->{platform_id} = $os_release{PLATFORM_ID};
        $id->{pretty_name} = $os_release{PRETTY_NAME};
        $id->{distro_update} = 0; # unknown in fact. TODO: is it usefull?
    } else { # /etc/suse-release is deprecated since 42.3
        return undef;
    }

    $id->{distro} = $distro;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $id->{distro_version};
    $id->{pkg} = $pkg;

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root,$detect_file);
    $id->{arch} = $arch;

    add_missing_fields($id);

    return $id;
}

sub add_missing_fields {
    my ($id) = @_;

    # Set the distro code_name
    $id->{codename} = "";

    # Set platform id.
    #$id->{platform_id} = "platform:sl$id->{distro_version}" if (! defined($id->{platform_id}));

    # Determine which package manager is in use.
    $id->{pkg_mgr} = "zypper";

    # Determine services management subsystem (systemd, initscripts, manual)
    $id->{service_mgt} = "systemd";

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
}

sub detect_pool {
    my ($pool) = @_;

    my $id = main::OSCAR::OCA::OS_Detect::detect_pool_rpm($pool,
                                                          $detect_package,
                                                          $distro,
                                                          $compat_distro);


    # Add missing fields
    add_missing_fields($id);

    return $id;
}

sub detect_fake {
    my ($fake) = @_;
    my $id = main::OSCAR::OCA::OS_Detect::detect_fake_common($fake,
                                                             $distro,
                                                             $compat_distro,
                                                             undef,
                                                             $pkg);

    # Add missing fields
    add_missing_fields($id);

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

        # Add missing fields
        add_missing_fields($id);

        return $id;
    } else {
        return undef;
    }
}


# If we got here, we're happy
1;
