#!/usr/bin/env perl
#
# Copyright (c) 2008 Oak Ridge National Laboratory.
#		    All rights reserved.
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

package OSCAR::OCA::OS_Detect::Ubuntu;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::LSBreleaseParser;

my $DEBUG = 1 if( $ENV{DEBUG_OCA_OS_DETECT} );
my ($deb_ver);

my $detect_pkg  = "base-files"; # Deb pkg containing '/etc/debian_version'
				# therefore should always be available
				# and the Version: is always accurate!

my $dpkg_bin = "/usr/bin/dpkg-query"; # Tool to query Deb package Database

# TODO: the following variable should be constants.
my $distro = "ubuntu";
my $compat_distro = "debian";
my $pkg = "deb";
my $detect_package = "base-files";
my $detect_file = "/bin/bash";

my %codenames = (
		'2304'	=> "lunar lobster",
		'2210'	=> "kinetic",
		'2204'	=> "jammy",
		'2110'	=> "impish",
		'2104'	=> "hirsute",
		'2010'  => "groovy",
		'2004'  => "focal",
		'1910'  => "eoan",
		'1904'  => "disco",
		'1810'  => "cosmic",
		'1804'  => "bionic",
		'1710'  => "artful",
		'1704'  => "zesty",
		'1610'  => "yakkety",
		'1604'  => "xenial",
		'1510'  => "wily",
		'1504'  => "vivid",
		'1410'  => "utopic",
		'1404'  => "trusty",
		'1310'  => "saucy",
		'1304'  => "raring",
		'1210'  => "quantal",
		'1204'  => "precise",
		'1110'  => "oneiric",
		'1104'  => "natty",
		'1010'  => "maverick",
		'1004'  => "lucid",
		'910'   => "karmic",
		'904'   => "jaunty",
		'810'   => "intrepid",
		'804'   => "hardy",
		'710'   => "gutsy",
		'704'   => "feisty",
		'610'   => "edgy",
		'606'   => "dapper",
		'510'   => "breezy",
		);

my %compat_version_mapping = (
		'2304'	=> "12",
		'2210'	=> "12",
		'2204'	=> "12",
		'2110'	=> "11",
		'2104'	=> "11",
		'2010'  => "11",
		'2004'  => "11",
		'1910'  => "10",
		'1904'  => "10",
		'1810'  => "10",
		'1804'  => "10",
		'1804'  => "10",
		'1710'  => "9",
		'1704'  => "9",
		'1610'  => "9",
		'1604'  => "9",
		'1510'  => "8",
		'1504'  => "8",
		'1410'  => "8",
		'1404'  => "8",
		'1310'  => "7",
		'1304'  => "7",
		'1210'  => "7",
		'1204'  => "7",
		'1110'  => "7",
		'1104'  => "6",
		'1010'  => "6",
		'1004'  => "6",
		'910'   => "5",
		'904'   => "5",
		'810'   => "4",
		'804'   => "4",
		'710'   => "4",
		'704'   => "4",
		'610'   => "4",
		'606'   => "4",
		'510'   => "4",
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

    my $os_release = main::OSCAR::OCA::OS_Detect::parse_os_release($root);

    if (defined($os_release)) {
        return undef if ($os_release->{NAME} !~ /^Ubuntu/); # Not Ubuntu: quit now
        $id->{distro_version} = $os_release->{VERSION_ID};
        $id->{platform_id} = $os_release->{PLATFORM_ID};
        $id->{pretty_name} = $os_release->{PRETTY_NAME};
        $id->{distro_update} = 0; # unknown in fact. TODO: is it usefull?
        return undef if($os_release->{ID} ne 'ubuntu'); # Quit if not an ubuntu
    } elsif( -f "$root/etc/lsb-release") {
        # There is a trick with Ubuntu systems: they have a non-valid 
        # /etc/debian_version and the ubuntu release data is actually in
        # /etc/lsb-release. So if we get data from this file and if it specifies
        # the system is an Ubuntu system we quit.
        my $distro_id = OSCAR::LSBreleaseParser::parse_lsbrelease($root);
        if (defined ($distro_id) && $distro_id ne "") {
            require OSCAR::PackagePath;
            my ($d, $v, $a) = OSCAR::PackagePath::decompose_distro_id ($distro_id);
            if ($d ne "ubuntu") {
		return undef; # Quit if not an ubuntu
            }
            if ($v =~ /(\d+)\.(\d+)/) {
		$id->{distro_version} = "$1$2"; # Ubuntu 12.04 version is 1204 used to match above tables
		$id->{distro_update} = 0;
            } else {
		return undef; # Can't parse version => Unsupported or not an ubuntu
	    }
        } else {
            return undef; # Not an ubuntu
        }
    } else {
	return undef; # No /etc/os-release, no /etc/lsb-release => Not an ubuntu
    }

    $id->{distro} = $distro;
    $id->{compat_distro} = $compat_distro;
    $id->{compat_distrover} = $compat_version_mapping{$id->{distro_version}};
    $id->{pkg} = $pkg;   

    # determine architecture
    my $arch = main::OSCAR::OCA::OS_Detect::detect_arch_file($root, $detect_file);
    $id->{arch} = $arch;

    # Limit support to only x86 and x86_64 machines
    if ($arch !~ /^x86_64$|^aarch64$|^i686$|^i586$|^i386$/ ) {
        print "OCA::OS_Detect::Debian-";
        print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
        return undef;
    }

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

    # Set distro code_name
    if(!defined($id->{codename})) {
      $id->{codename} = $codenames{$id->{distro_version}};
    }

    # Set pretty name
    $id->{pretty_name} = "Ubuntu $id->{distro_version}" if (! defined($id->{pretty_name}));

    # Set platform id.
    $id->{platform_id} = "platform:ubt$id->{distro_version}" if (! defined($id->{platform_id}));

    # Determine which package manager is in use.
    $id->{pkg_mgr} = "apt";

    # Determine services management subsystem (systemd, initscripts, manual)
    if ($id->{distro_version} < 1604) { # systemd is in ubuntu since 16.04
       $id->{service_mgt} = "upstart"; # was initscripts
    } else {
       $id->{service_mgt} = "systemd"; # Became default boot manager in Jessie
    }

    # Set dummy distro_update if missing so ident is correct.
    $id->{distro_update} = 0 if (! defined($id->{distro_update}));

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
    #$id->{ident} .= $id->{distro_update} if defined $id->{distro_update};
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

# EF: simply copied the function from RedHat.pm
sub detect_fake {
    my ($fake) = @_;

    return undef if (!defined $fake);

    # From the parameter, we detect the distro codename and add it in the
    # description of the OS
    my $l_version = $fake->{'distro_version'};
    $fake->{'codename'} = $codenames{$l_version};

    my $id = main::OSCAR::OCA::OS_Detect::detect_fake_common($fake,
				 $distro,
				 $compat_distro,
				 $compat_version_mapping{$l_version},
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
