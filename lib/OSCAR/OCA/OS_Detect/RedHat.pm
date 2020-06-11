#!/usr/bin/env perl
#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) Bernard Li <bli@bcgsc.ca>
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

package OSCAR::OCA::OS_Detect::RedHat;

use strict;

my $distro = "redhat-el";
my $compat_distro = "rhel";
my $pkg = "rpm";
my $detect_package = "redhat-release";
my $detect_file = "/bin/bash";

# List supported OS fammily. To drop support for a familly: replace familly name with undef.
my @os_families = ( undef, undef, undef, undef, undef, undef, 'Santiago', 'Maipo', 'Ootpa' );

# This is the logic that determines whether this component can be
# loaded or not -- i.e., whether we're on a RHEL machine or not.
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

    my $os_release = main::OSCAR::OCA::OS_Detect::parse_os_release($root);

    if (defined ($os_release)) {
	return undef if ($os_release->{NAME} !~ /^Red Hat Enterprise Linux/); # Not RHEL: quit now
        $id->{distro_version} = $os_release->{VERSION_ID};
        $id->{platform_id} = $os_release->{PLATFORM_ID};
        $id->{pretty_name} = $os_release->{PRETTY_NAME};
        $id->{distro_update} = 0; # Fixed later if needed.
    } elsif (-f "$root/etc/redhat-release") { # If /etc/redhat-release exists, continue, otherwise, quit.
        $release_string = `cat $root/etc/redhat-release`;
        if ($release_string =~ /Red Hat Enterprise Linux (\S+) release (\d+) \((\S+) Update (\d+)\)/ ||
            $release_string =~ /Red Hat Enterprise Linux (\S+) release (\d+|\d+\.\d+) \((\S+)\)/) {
            my $flavor = $1; # AS, WS, ES? This information is irrelevant for OSCAR
            $id->{distro_version} = $2;
            $id->{os_family} = $3; # Nahant, blah...
            $id->{distro_update} = $4;

            # only support these three for now
	    #if ($id->{os_family} !~ /^(Santiago|Maipo|Ootpa)$/) { # RHEL-6, RHEL-7, RHEL-8
	    #    return undef; # Unsupported OS family
	    #}
	    my @matches = grep { /$id->{os_family}/ } @os_families; # Look for family in supported families
	    return undef if (! @matches);
        } else {
            return undef; # Red Hat Enterprise Linux not in /etc/redhat-release: not a RHEL: quit (maybe a fedora?)
        }
    } else {
        return undef; # no /etc/os-release and no /etc/redhat-release
    }

    # In case the version number and the update number are all together, we
    # explicitely make the distinction
    if ($id->{distro_version} =~ /(\d+).(\d+)/) {
        $id->{distro_version} = $1;
        $id->{distro_update} = $2;
    } else {
	$id->{distro_update} = 0;
    }

    $id->{distro} = $distro; #."-".lc($flavor);
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

    # Don't try to add fields to an undefined hash.
    return if(! defined($id));

    # Set os type (for now, it's always linux. no bsd yet)
    $id->{os} = "linux";

    # Make sure chroot is set
    $id->{chroot} = "/" if(!defined($id->{chroot}));

    # Set the distro code_name
    $id->{codename} = $os_families[$id->{distro_version}];

    # Set pretty name
    $id->{pretty_name} = "Red Hat Enterprise Linux Server $id->{distro_version} ($id->{distro_code_name})" if (! defined($id->{pretty_name}));

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
