#!/usr/bin/env perl
#
# Copyright (c) 2020 Olivier Lahaye <olivier.lahaye@cea.fr>
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#

package OSCAR::OCA::PM_Abstract::apt;

use strict;

# check for:
# - /usr/bin/apt-get			=> package management
# - /usr/bin/apt-cache
# - ...
# - /usr/bin/???			=> repo management
# - /usr/bin/???			=> repo creation
# - deboostrap				=> bootstrap

BEGIN {
	die "Work in progress, not useable yet".
	die "apt-get unavailable on this system" if(! -x "/usr/bin/apt-get"); # Prevent module loading if yum not available.
}

sub update_options {
	my $id = shift;
	my $options = shift;
	$options = " --root-directory= $id->{'chroot'}".$options if ($id->{'chroot'} ne '/');
	return $options; # -o RootDir= better?
}

sub pm_command {
	my $command = shift;
	my $id = shift; # the OS_Detect infos (what package manager; what installroot, ....)
	my $options = shift; # A string with package manager options (e.g. "-y --force")
	my @args = @_;
	my $pkgs = "";
	$options = update_options($id, $options);
	if ($command eq "install") {
		return -1 if ( scalar @args == 0); # no pkg names provided: error
		$pkgs = join (' ', @args); # packages (or repo names)
		return system("yum $options install $pkgs");
	} elsif ($command eq "update") {
		$pkgs = join (' ', @args) if ( scalar @args == 0);
		return system("yum $options update $pkgs");
	} elsif ($command eq "reinstall") {
		return -1 if ( scalar @args == 0); # no pkg names provided: error
		$pkgs = join (' ', @args);
		return system("yum $options reinstall $pkgs");
	} elsif ($command eq "remove") {
		return -1 if ( scalar @args == 0); # no pkg names provided: error
		$pkgs = join (' ', @args);
		return system("yum $options remove $pkgs");
	} elsif ($command eq "what_provides") {
		return -1 if ( scalar @args != 1); # args: pkg name, path or feature.
		$pkgs = join (' ', @args);
		return system("LC_ALL=C yum -q $options provides '$pkgs'|sed '/^Repo/d;/^\$/d'");
	} elsif ($command eq "bootstrap") {
		# Need a list of bootstrap packages
		# Need to use the platform-id on some distros (dnf)
	} elsif ($command eq "list_available") {
		return system("yum $options list all");
	} elsif ($command eq "list_installed") {
		return system("rpm -qa");
	} elsif ($command eq "list_repos") {
		return system("yum $options repolist");
	} elsif ($command eq "repo_create") {
		# $args[0]: repo absolute path.
		return system("createrepo --update -s sha '$args[0]'");
	} elsif ($command eq "repo_optimize") { # remove all duplicates keeping only the latest version.
		system("repomanage --keep=1 --old '$args[0]' |xargs -r rm");
		return system("createrepo --update -s sha '$args[0]'");
	} elsif ($command eq "repo_update") {
		return system("createrepo --update -s sha '$args[0]'");
	} elsif ($command eq "repo_add") {
		return system("yum-config-manager --add-repo '$args[0]'");
	} elsif ($command eq "repo_remove") {
		return -1; # not supported
	} elsif ($command eq "repo_enable") {
		return system("yum-config-manager --enable '$args[0]'");
	} elsif ($command eq "repo_disable") {
		return system("yum-config-manager --disable '$args[0]'");
	} elsif ($command eq "clear_cache") {
		return system("yum $options clean all");
	} elsif ($command eq "make_cache") {
		return system("yum $options makecache");
	} else {
		print "ERROR: Unknown command: $command\n";
		return -1; # Unknown package command (bug)
	}
}

# If we got here, we're happy
1;
