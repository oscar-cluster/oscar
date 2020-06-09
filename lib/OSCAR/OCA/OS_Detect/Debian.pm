#!/usr/bin/env perl
#
# Copyright (c) 2005 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#                    All rights reserved.
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

package OSCAR::OCA::OS_Detect::Debian;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::LSBreleaseParser;
use OSCAR::Utils;

my $DEBUG = 1 if( $ENV{DEBUG_OCA_OS_DETECT} );

my $detect_pkg  = "base-files"; # Deb pkg containing '/etc/debian_version'
                                # therefore should always be available
                                # and the Version: is always accurate!

my $dpkg_bin = "/usr/bin/dpkg-query"; # Tool to query Deb package Database


my $distro = "debian";
my $compat_distro = "debian";
my $pkg = "deb";
my $detect_package = "base-files";
my $detect_file = "/bin/bash";
my $distro_flavor;

# The different Debian codenames, useful to set the distro_flavor variable
my %codenames = (
		'12.0'  => "bookworm",
		'11.0'  => "bullseye",
                '10.0'  => "buster",
                '9.0'   => "stretch",
                '8.0'   => "jessie",
                '7.0'   => "wheezy",
                '6.0'   => "squeeze",
                '5.0'   => "lenny",
                '4.0'   => "etch",
                '3.1'   => "sarge",
                '3.0'   => "woody",
                '2.2'   => "potato",
                '2.1'   => "slink",
                '2.0'   => "hamm",
                );

#
#  End of all configuration/global variable setup
# 
#---------------------------------------------------------------------



# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect_dir {
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
        return undef if ($os_release{NAME} !~ /^Debian GNU\/Linux/); # Not Debian: quit now
        $id->{distro_version} = $os_release{VERSION_ID};
        $id->{platform_id} = $os_release{PLATFORM_ID};
        $id->{pretty_name} = $os_release{PRETTY_NAME};
	return undef if($os_release{ID} ne 'debian'); # Quit if not a debian
    } elsif (-f "$root/etc/debian_version") {    # If /etc/debian_version exists, continue, otherwise, quit.
        # There is a trick with Ubuntu systems: they have a non-valid 
        # /etc/debian_version and the ubuntu release data is actually in
        # /etc/lsb-release. So if we get data from this file and if it specifies
        # the system is an Ubuntu system we quit.
        my $distro_id = OSCAR::LSBreleaseParser::parse_lsbrelease($root);
        if (OSCAR::Utils::is_a_valid_string ($distro_id)) {
            require OSCAR::PackagePath;
            my ($d, $v, $a) = 
                OSCAR::PackagePath::decompose_distro_id ($distro_id);
            return undef if ($d eq "ubuntu"); # Quit if not a debian
        }


        # GV (2009/04/22): this is completely stupid (yes it is!) to use
        # the version of the base-files package since developers may trick
        # the version number as a work around to packaging issues. As a
        # result, it is a nigthmare to get the actual version from it,
        # especially when at the same time, a file (/etc/debian-version)
        # is there to give the version (even if the file may store a codename
        # or a version, it is still simpler).
        my $cmd = "$dpkg_bin --show $detect_pkg 2>&1";
        open(CMD, "$cmd|") or die "Error: unable to open $cmd - $!\n";
        my $rslt = <CMD>;
        chomp($rslt);
        close(CMD);

        $id->{distro_version} = (split(/[\s\+]+/, $rslt))[1];  # [0]=name,  [1]=version, [2]=optional update release

    } else {
        return undef;
    }

    # two cases: the version number is "x" or "x.<something>" 
    # or "xcodenamey"
    if ($id->{distro_version} =~ /^(\d+)\.(\d+)/) {
        $id->{distro_version} = $1;
        $id->{distro_update} = $2;
    } elsif ($id->{distro_version} =~ /^(\d+)([A-z]+)(\d+)$/) {
        $id->{distro_version} = $1;
        $id->{distro_update} = 0;
    } else {
	$id->{distro_update} = 0;
    }

    $id->{distro} = $distro;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $id->{distro_version};
    $id->{pkg} = $pkg;

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root, $detect_file);
    $id->{arch} = $arch;

    # Limit support to only x86 and x86_64 machines
    if ($arch !~ /^x86_64$|^i686$|^i586$|^i386$/ ) {
        print "OCA::OS_Detect::Debian-";
        print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
        return 0;
    }

    add_missing_fields($id);

    return $id;
}

sub add_missing_fields {
    my ($id) = @_;

    # Set os type (for now, it's always linux. no bsd yet)
    $id->{os} = "linux";

    # Make sure chroot is set
    $id->{chroot} = "/" if(!defined($id->{chroot}));

    # Set distro code_name
    my $full_distro_ver = "$id->{distro_version}.$id->{distro_update}";
    $id->{codename} = $codenames{$full_distro_ver};

    # Set pretty name
    $id->{pretty_name} = "Debian GNU/Linux $id->{distro_version} ($id->{codename})" if (! defined($id->{pretty_name}));

    # Set platform id.
    $id->{platform_id} = "platform:deb$id->{distro_version}" if (! defined($id->{platform_id}));

    # Determine which package manager is in use.
    $id->{pkg_mgr} = "apt";

    # Determine services management subsystem (systemd, initscripts, manual)
    if ($id->{distro_version} <= 7) {
       $id->{service_mgt} = "initscripts";
    } else {
       $id->{service_mgt} = "systemd"; # Became default boot manager in Jessie
    }

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
}


# EF: simply copied the function from RedHat.pm, this is why we have common
# routines in OS_Detect, in order to avoid code replication
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

sub detect_fake ($) {
    my ($fake) = @_;

    return undef if (!defined $fake);

    # From the parameter, we detect the distro codename and add it in the
    # description of the OS
    my $l_version = $fake->{'distro_version'};
    if ($l_version !~ /(.*)\.(.*)/) {
        $l_version .= ".0";
    }
    $fake->{'codename'} = $codenames{$l_version};

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

detect_dir ("/");

# If we got here, we're happy
1;
