#!/usr/bin/env perl
#
# Copyright (c) 2020 Olivier Lahaye <olivier.lahaye@cea.fr>
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#

package OSCAR::OCA::PM_Abstract::zypper;

use strict;

# check for:
# - /usr/bin/zypper			=> package management
# - /usr/bin/createrepo			=> repo creation
BEGIN {
	die "zypper unavailable on this system" if(! -x "/usr/bin/zypper"); # Prevent module loading if zypper not available.
}

sub update_options {
	my $id = shift;
	my $options = shift;
	$options = " --root $id->{'chroot'}".$options if ($id->{'chroot'} ne '/');
	return $options;
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
		return system("zypper $options install $pkgs");
	} elsif ($command eq "update") {
		$pkgs = join (' ', @args) if ( scalar @args == 0);
		return system("zypper $options update $pkgs");
	} elsif ($command eq "reinstall") {
		return -1 if ( scalar @args == 0); # no pkg names provided: error
		$pkgs = join (' ', @args);
		return system("zypper -f $options install $pkgs");
	} elsif ($command eq "remove") {
		return -1 if ( scalar @args == 0); # no pkg names provided: error
		$pkgs = join (' ', @args);
		return system("zypper $options remove $pkgs");
	} elsif ($command eq "what_provides") {
		return -1 if ( scalar @args != 1); # args: pkg name, path or feature.
		return system("zypper $options search --provides '$pkgs'"); # BUG: use --xmlout and parse using xmlstarlet
	} elsif ($command eq "bootstrap") {
		# Need a list of bootstrap packages
		# Need to use the platform-id on some distros (dnf)
	} elsif ($command eq "list_available") {
		return system("zypper $options packages");
	} elsif ($command eq "list_installed") {
		return system("rpm -qa");
	} elsif ($command eq "list_repos") {
		return system("zypper $options repos");
	} elsif ($command eq "repo_create") {
		# $args[0]: repo absolute path.
		return system("createrepo --update -s sha '$args[0]'");
	} elsif ($command eq "repo_optimize") { # remove all duplicates keeping only the latest version.
		system("repomanage --keep=1 --old '$args[0]' |xargs -r rm");
		return system("createrepo --update -s sha '$args[0]'");
	} elsif ($command eq "repo_update") {
		return system("createrepo --update -s sha '$args[0]'");
	} elsif ($command eq "repo_add") {
		return system("zypper $options addrepo '$args[0]' '$args[1]'"); # ARG0: url / ARG1: name
	} elsif ($command eq "repo_remove") {
		return system("zypper $options removerepo '$args[0]'"); # ARG0: repo name
	} elsif ($command eq "repo_enable") {
		return system("zypper modifyrepo -e '$args[0]'"); # ARG0: repo alias or number.
	} elsif ($command eq "repo_disable") {
		return system("zypper modifyrepo -d '$args[0]'");
	} elsif ($command eq "clear_cache") {
		return system("zypper $options clean");
	} elsif ($command eq "make_cache") {
		return system("zypper $options refresh");
	} else {
		print "ERROR: Unknown command: $command\n";
		return -1; # Unknown package command (bug)
	}
}

# If we got here, we're happy
1;
