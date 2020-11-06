#
# Copyright (c) 2020 CEA
#                    All rights reserved.
#
# Copyright (c) 2020 Olivier Lahaye <olivier.lahaye@cea.fr>
#                    All rights reserved
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OSCAR::OCA::PM_Abstract;

use strict;
use vars qw(@EXPORT $LOCAL_NODE_OS);
use base qw(Exporter);
use File::Glob qw(:globally :nocase); # disabling case sensitivity so it
                                      # works under openSUSE: /etc/SuSE-release
                                      # vs suse-release-oss RPM
use Carp;

use OSCAR::OCA;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use Module::Load;
#
# Exports
#

@EXPORT = qw( pm_command );

#
# Subroutine to open the OS_Detect framework
#
# Arguments and usage examples:
# 1st argument for all functions is an OS_Detect hash:
# $id->{distro_version}		=> $os_release->{VERSION_ID};
# $id->{platform_id}		=> $os_release->{PLATFORM_ID};
# $id->{pretty_name}		=> $os_release->{PRETTY_NAME};
# $id->{distro_update}		=> Distro minor version
# $id->{distro}			=> centos, rhel, fedora, sled, sles, opensuse, debian, ubuntu, ...
# $id->{compat_distro}		=> rhel, fedora, suse, debian, suse
# $id->{compat_distrover}	=> Example: ubuntu 14.10 => debian 8 (8 == compat distrover for ubuntu 14.10)
# $id->{pkg}			=> Either "rpm" or "deb" for now
# $id->{arch}			=> x86_64, ...
# $id->{os}			=> "linux" what else?
# $id->{chroot}			=> Defaults to "/". Used to point to image path when dealing with images
# $id->{codename}		=> Distro code name like "Core" for CentOS;
# $id->{pkg_mgr}		=> yum, dnf, zypper, urpmi, apt, ...
# $id->{service_mgt}		=> systemd, initscripts, upstart, ...
# $id->{ident}			=> $os-$arch-$distro-$distro_version-$distro_update
#
# Use OSCAR::OCA::OS_Detect to get a $id hash that will be used by below functions.
# OSCAR::OCA::OS_Detect::open()              : When working with host distro and packages (chroot = '/')
# OSCAR::OCA::OS_Detect::open($path)         : When working on an image
# OSCAR::OCA::OS_Detect::open(chroot=>$path) : Same as above
# OSCAR::OCA::OS_Detect::open(pool=>$pool)   : When working with a repository
# OSCAR::OCA::OS_Detect::open(fake=>{ distro=>$distro, distro_version=>$version, arch=>$arch})
#                                            : build fake $id structure when distro is known but
#                                              distro files are not accessible (e.g. for pools
#                                              referenced by URLs). Main purpose: Bootstrap image or repo
# OSCAR::OCA::OS_Detect::CentOS::detect_dir when working on an image
# OSCAR::OCA::OS_Detect::CentOS::detect_pool when working on a repository
# OSCAR::OCA::OS_Detect::CentOS::detect_fake when working on empty image or empty repo
# OSCAR::OCA::OS_Detect::CentOS::detect_oscar_pool when working with an oscar repo

# TODO: yume creates temp repo files from supported_distros (found in /tftpboot/*url)
# TODO: create bootstrap stuff (can be done is PM_Detect::<package_manager>.pm ?

sub pm_command {
	my $command = shift;
	my $id = shift;		# the OS_Detect infos (what package manager; what installroot, ....)
	my $options = shift;	# A string with package manager options (e.g. "-y --force")
	my @args = @_;		# Package names or repo na mes or rpo path or ...
	return -1 if (! defined($id->{pkg_mgr}));

	# All supported commands:
	my @valid_commands = ( 'install', 'reinstall', 'update', 'remove', 'what_provides', 'bootstrap',
		'list_available', 'list_installed', 'list_repos',
		'repo_create', 'repo_optimize', 'repo_update', 'repo_add', 'repo_remove', 'repo_enable', 'repo_disable',
		'clear_cache', 'make_cache');

	my $perl_mod = "OSCAR::OCA::PM_Abstract::$id->{pkg_mgr}";

	if ( $command ~~ @valid_commands ) { # check valid command.
		return eval $perl_mod."::pm_command(\$command, \$id, \$options, \@args)"; # $id is needed for installroot
	} else {
		# invalid command
		return -1;
	}
}

###############################################################################
# Subroutine to open the PM_Abstract framework.                               #
# Input:  Requested package manager (returned by OS_Detect).                  #
# Return: Return 1 if available else die.                                     #
#         For example, on a CentOS-7, you may have apt-get installed.         #
#         apt-get will then be available to update a debian image.            #
###############################################################################

sub open {
    my $requested_pm = shift;
    # Look for available package managers.
    my $comps = OSCAR::OCA::find_components("PM_Abstract");

    # No framework components found or only the None one has been found
    if (scalar(@$comps) == 0) {
        die "ERROR: Could not find any available component for this PM_Abstract framework!\n";
    }

    if ( $requested_pm ~~ @$comps ) {
        # Happiness -- tell the caller that all went well.
        return 1;
    } else {
        die "ERROR: requested package manager ($requested_pm) is not available. Available package managers: ".join (' ', @$comps)."\n";
    }
}

1;
