#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2006, 2007 Bernard Li <bernard@vanhpc.org>
# 
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#      - complete rewrite to enable use on top of images
#      - enabled use on top of package pools
#
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

package OSCAR::OCA::OS_Detect::Fedora;

use strict;

my $distro = "fedora";
my $compat_distro = "fc";
my $pkg = "rpm";
my $detect_package = "fedora-release";
my $detect_file = "/bin/bash";

# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect_dir {
    my $release_string;
    my $root = "/";
    if (@_) {
        $root = shift;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
        chroot => $root,
    };

    my %os_release = main::OSCAR::OCA::OS_Detect::parse_os_release($root);

    if (%os_release) {
        return undef if ($os_release{NAME} !~ /^Fedora/); # Not Fedora: quit now
        $id->{distro_version} = $os_release{VERSION_ID};
        $id->{platform_id} = $os_release{PLATFORM_ID};
        $id->{pretty_name} = $os_release{PRETTY_NAME};
    } elsif (-f "$root/etc/fedora-release") { # If /etc/fedora-release exists, continue, otherwise, quit.
        $release_string = `cat $root/etc/fedora-release`;
        if ($release_string =~ /Fedora release (\d+)\.9\d \(Rawhide\)/) { 
            # Fedora Core test releases 
            $id->{distro_version} = $1+1;
        } elsif ($release_string =~ /Fedora (?:Core )?release (\d+)/) {
            $id->{distro_version} = $1;
        } else {
            return undef; # Can't parse /etc/fedora-release
        }
    } else {
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

    $id->{distro_update} = 0; # irrelevant in Fedora. TODO: is it usefull?

    # Set os type (for now, it's always linux. no bsd yet)
    $id->{os} = "linux";

    # Make sure chroot is set
    $id->{chroot} = "/" if(!defined($id->{chroot}));

    # Set distro code_name
    $id->{codename} = "";

    # Set pretty name
    $id->{pretty_name} = "Fedora $id->{distro_version}" if (! defined($id->{pretty_name}));

    # Set platform id.
    $id->{platform_id} = "platform:f$id->{distro_version}" if (! defined($id->{platform_id}));

    # Determine which package manager is in use.
    $id->{pkg_mgr} = "dnf";

    # Determine services management subsystem (systemd, initscripts, manual)
    $id->{service_mgt} = "systemd";

    # Set dummy distro_update if missing so ident is correct.
    $id->{distro_update} = 0 if (! defined($id->{distro_update}));

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}";
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
