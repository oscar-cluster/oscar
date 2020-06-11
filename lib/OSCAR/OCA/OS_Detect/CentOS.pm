#!/usr/bin/env perl
#
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
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

package OSCAR::OCA::OS_Detect::CentOS;

use strict;

my $distro = "centos";
my $compat_distro = "rhel";
my $pkg = "rpm";
my $detect_package = "centos-release";
my $detect_file = "/bin/bash";

sub detect_dir {
    my $root = "/";
    my $release_string;
    if (@_) {
        $root = shift;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
        chroot => $root,
    };

    my $os_release = main::OSCAR::OCA::OS_Detect::parse_os_release($root);

    if (defined($os_release)) {
        return undef if ($os_release->{NAME} !~ /^CentOS Linux/); # Not CentOS: quit now
        $id->{distro_version} = $os_release->{VERSION_ID};
	$id->{platform_id} = $os_release->{PLATFORM_ID};
	$id->{pretty_name} = $os_release->{PRETTY_NAME};
	$id->{distro_update} = 0; # unknown in fact. TODO: is it usefull?
    } elsif (-f "$root/etc/redhat-release") {
        $release_string = `cat $root/etc/redhat-release`;
        if ($release_string =~ /CentOS release (\d+)\.(\d+) \((\S+)\)/ ||
            $release_string =~ /CentOS release (\d+) \((\S+)\)/ ||
            $release_string =~ /CentOS Linux release (\d+)\.(\d+) \(.+\)/ ||
            $release_string =~ /CentOS Linux release (\d+)\.(\d+)\.(\d+) \(.+\)/ ||
            $release_string =~ /CentOS Linux release (\d+) \(\D+\d+\.(\d+)\)/) {
            $id->{distro_version} = $1;

            # CentOS's major number release does not have a minor number (eg. 5 vs 5.0), set $os_update to 0 by default
            my $upd = $2;
            if ( $upd =~ /^[0-9]+$/ ) {
                $id->{distro_update} = $upd;
            } else {
                $id->{distro_update} = 0;
            }
        } else {
            return undef;
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

    # Don't try to add fields on undefined hash.
    return if ( ! defined($id) );

    # Set os type (for now, it's always linux. no bsd yet)
    $id->{os} = "linux";

    # Make sure chroot is set
    $id->{chroot} = "/" if(!defined($id->{chroot}));

    # Set distro code_name
    $id->{codename} = "Core";

    # Set pretty name
    $id->{pretty_name} = "CentOS Linux $id->{distro_version} (Core)" if (! defined($id->{pretty_name}));

    # Set platform id.
    $id->{platform_id} = "platform:el$id->{distro_version}" if (! defined($id->{platform_id}));

    # Determine which package manager is in use.
    if ($id->{distro_version} <= 7) {
        $id->{pkg_mgr} = "yum";
    } else {
        $id->{pkg_mgr} = "dnf";
    }

    # Determine services management subsystem (systemd, initscripts, manual)
    if ($id->{distro_version} <= 6) {
       $id->{service_mgt} = "initscripts";
    } else {
       $id->{service_mgt} = "systemd";
    }

    # Set dummy distro_update if missing so ident is correct.
    $id->{distro_update} = 0 if (! defined($id->{distro_update}));

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
        my $id = { };
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
