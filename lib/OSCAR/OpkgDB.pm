package OSCAR::OpkgDB;
#---
# Perl module providing functionality for querying opkg information from
# opkg-* meta-packages in a somewhat similar way to what was done in earlier
# versions of OSCAR with data from config.xmls living in the ODA database.
# This code should make several package related tables in ODA obsolete.
#
# Copyright (c) 2007 Erich Focht efocht@hpce.nec.com>
#                    All rights reserved.
# 
#   $Id$
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#---

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use OSCAR::PackagePath;
use Carp;

@EXPORT = qw(
	     opkg_list_available
	     opkg_hash_available
	     opkg_list_installed
	     opkg_hash_installed
	     );

####
# List all opkgs which are available in the accessible repositories.
#
# Arguments: scope hash for detecting targetted distro
#            empty: local node
#            chroot => image_path : detect distro of specific image
#            fake=>{distro=>distroname, version=>distrover, arch=>arch}
#                don't detect distro, use passsed values
# 
# Returns array of API opkg names
####
sub opkg_list_available {
    my %scope = @_;
    my %opkgs;

    my $os = OSCAR::OCA::OS_Detect::open(%scope);
    return () if !$os;

    my $repo = make_repostring($os);
    my $pkg = $os->{pkg};
    if ($pkg eq "rpm") {
	my $cmd="/usr/bin/yume $repo --repoquery --nevra opkg-*-server";
	print "Running $cmd" if $verbose;
	open CMD, "$cmd |" or die "Error: $!";
	while (<CMD>) {
	    if (m/^opkg-(.*)-server-(.*).noarch.rpm/) {
		$opkgs{$1} = $2;
	    }
	}
	close CMD;
    } elsif ($pkg eq "deb") {
	#TODO# add search option to rapt
	my $cmd="/usr/bin/rapt $repo --names-only search 'opkg-.*-server'";
	print "Running $cmd" if $verbose;
	open CMD, "$cmd |" or die "Error: $!";
	while (<CMD>) {
	    if (m/^opkg-(.*)-server -/) {
		$opkgs{$1} = 1;
	    }
	}
	close CMD;
    } else {
	return undef;
    }
    return sort(keys(%opkgs));
}

####
# Build a hash for all opkgs which are available in the accessible
# repositories.
#
# Arguments: scope hash for detecting targetted distro
#            empty: local node
#            chroot => image_path : detect distro of specific image
#            fake=>{distro=>distroname, version=>distrover, arch=>arch}
#                don't detect distro, use passsed values
# 
# Returns hash of API opkgs
####
sub opkg_hash_available {
    my %scope = @_;
    my %o;

    my $os = OSCAR::OCA::OS_Detect::open(%scope);
    return () if !$os;

    my $repo = make_repostring($os);
    my $pkg = $os->{pkg};
    my $isdesc = 1;
    my ($name, $rel, $ver, $packager, $summary, $desc, $group, $conflicts);
    if ($pkg eq "rpm") {
	my $cmd="/usr/bin/yume $repo --repoquery --info opkg-*-server";
	print "Running $cmd" if $verbose;
	open CMD, "$cmd |" or die "Error: $!";
	while (<CMD>) {
	    chomp;
	    if (/^Name\s*: (.*)$/) {
		if ($name) {
		    $o{$name} = {
			name => $name,
			version => "$ver-$rel",
			summary => $summary,
			packager => $packager,
			description => $desc,
			group => $group,
		    };
		}
		$name = $1;
		$isdesc = 0;
		$ver = $rel = $summary = $packager = $desc = $group = "";
		$conflicts = "";
	    } else if (/^Version\s*:\s*(.*)\s*$/) {
		$ver = $1;
	    } else if (/^Release\s*:\s*(.*)\s*$/) {
		$rel = $1;
	    } else if (/^Packager\s*:\s*(.*)\s*$/) {
		$packager = $1;
	    } else if (/^Group\s*:\s*(.*)\s*$/) {
		$group = $1;
	    } else if (/^Summary\s*:\s*(.*), server part\s*$/) {
		$summary = $1;
	    } else if (/^Description\s*:/) {
		$isdesc = 1;
	    } else {
		if ($isdesc) {
		    $desc .= "$_\n";
		}
	    }
	}
	close CMD;
	if ($name) {
	    $o{$name} = {
		name => $name,
		version => "$ver-$rel",
		summary => $summary,
		packager => $packager,
		description => $desc,
		group => $group,
	    };
	}
    } elsif ($pkg eq "deb") {
	my @opkgs = &opkg_list_available(%scope);
	@opkgs = map { "opkg-$_" } @opkgs;
	#TODO# add show option to rapt
	my $cmd="/usr/bin/rapt $repo show ".join(" ", @opkgs);
	print "Running $cmd" if $verbose;
	open CMD, "$cmd |" or die "Error: $!";
	while (<CMD>) {
	    chomp;
	    if (/^Package: (.*)$/) {
		$name = $1;
		$isdesc = 0;
		$ver = $rel = $summary = $packager = $desc = $group = "";
		$conflicts = "";
	    } else if (/^Version: (.*)$/) {
		$ver = $1;
	    } else if (/^Section: (.*)$/) {
		$group = $1;
	    } else if (/^Maintainer: (.*)$/) {
		$packager = $1;
	    } else if (/^Conflicts: (.*)$/) {
		$conflicts = $1;
	    } else if (/^Description: (.*), server part$/) {
		$isdesc = 1;
		$summary = $1;
	    } else if (/^Bugs:/) {
		if ($name) {
		    $o{$name} = {
			name => $name,
			version => $ver,
			summary => $summary,
			packager => $packager,
			description => $desc,
			group => $group,
			conflicts => $conflicts,
		    };
		}
		$isdesc = 0;
	    } else {
		if ($isdesc) {
		    m/^ (.*)$/;
		    $desc .= "$1\n";
		}
	    }
	}
	close CMD;
	if ($name) {
	    $o{$name} = {
		name => $name,
		version => $ver,
		summary => $summary,
		packager => $packager,
		description => $desc,
		group => $group,
		conflicts => $conflicts,
	    };
	}
    } else {
	return undef;
    }
    return %o;
}

####
# make_repostring: Prepare arguments string with repository names for
#                  the passed os.
#
####
sub make_repostring {
    my ($os) = @_;

    my $drepo = OSCAR::PackagePath::distro_repo_url(os=>$os);
    my $orepo = OSCAR::PackagePath::oscar_repo_url(os=>$os);
    my $repo;
    for my $r (split /,/, "$drepo,$orepo") {
	$repo .= " --repo $r";
    }
    $repo =~ s/^ //;
    return $repo;
}

####
# opkg_list_installed: List opkgs of a certain type (api, server, client)
#                      which are installed locally.
#
# Argument:
#    type : "api", "server" or "client"
#
# Returns:
#    hash with key=<opkg name>
#              value=<opkg version>
####
sub opkg_list_installed {
    my ($type) = (@_);
    my %opkgs;

    my $os = OSCAR::OCA::OS_Detect::open();
    return () if !$os;

    my $pkg = $os->{pkg};
    if ($pkg eq "rpm") {
	my $cmd="/usr/bin/rpm -qa --qf='%{NAME} %{VERSION}-%{RELEASE}\n'";
	print "Running $cmd" if $verbose;
	open CMD, "$cmd |" or die "Error: $!";
	while (<CMD>) {
	    chomp;
	    if (m/^opkg-(.*) (.*)$/) {
		my $name = $1;
		my $version = $2;
		if ($type eq "api") {
		    next if ($name =~ m/-(client|server)$/);
		} else {
		    next if ($name !~ m/-($type)$/);
		    $name =~ m/^(.*)-($type)$/;
		    $name = $1;
		}
		$opkgs{$name} = $version;
	    }
	}
	close CMD;
    } elsif ($pkg eq "deb") {
	my $cmd="env COLUMNS=256 /usr/bin/dpkg -l \"opkg-*\"";
	print "Running $cmd" if $verbose;
	open CMD, "$cmd |" or die "Error: $!";
	while (<CMD>) {
	    if (m/^\S+\s+opkg-(.*)\s+(\S+)\s/) {
		my $name = $1;
		my $version = $2;
		if ($type eq "api") {
		    next if ($name =~ m/-(client|server)$/);
		} else {
		    next if ($name !~ m/-($type)$/);
		    $name =~ m/^(.*)-($type)$/;
		    $name = $1;
		}
		$opkgs{$name} = $version;
	    }
	}
	close CMD;
    } else {
	return undef;
    }
    return %opkgs;
}

####
# opkg_hash_installed
#
# Returns:
#   hash with info on all opkgs installed
#   key: opkg name
#   value: reference to subhash
#          subhash:
#              {name}        : short package name
#              {version}     : package version (and release)
#              {package}     : long package name (Summary)
#              {packager}    : packager info
#              {description} : package description
#              {group}       : group info (replaces class info?)
#              
####
sub opkg_hash_installed {
    my %olist = &opkg_list_installed("api");
    my %opkgs;

    my $os = OSCAR::OCA::OS_Detect::open();
    return () if !$os;

    my $pkg = $os->{pkg};
    for my $name (keys(%olist)) {
	if ($pkg eq "rpm") {
	    $opkgs{$name} = &opkg_localrpm_info($name);
	} elsif ($pkg eq "deb") {
	    $opkgs{$name} = &opkg_localdeb_info($name);
	}
    }
    return %opkgs;
}

sub opkg_localrpm_info {
    my ($name) = @_;
    my %h;

    my $p = "opkg-$name";
    $h{name} = $name;
    $h{version} = `rpm -q --qf '%{VERSION}-%{RELEASE}' $p`;
    $h{package} = `rpm -q --qf '%{SUMMARY}' $p`;
    $h{packager} = `rpm -q --qf '%{PACKAGER}' $p`;
    $h{description} = `rpm -q --qf '%{DESCRIPTION}' $p`;
    $h{group} = `rpm -q --qf '%{GROUP}' $p`;

    return \%h;
}

sub opkg_localdeb_info {
    my ($name) = @_;
    my %h;

    my $p = "opkg-$name";
    $h{name} = $name;
    #$h{version} = `rpm -q --qf '%{VERSION}-%{RELEASE}' $p`;
    #$h{package} = `rpm -q --qf '%{SUMMARY}' $p`;
    #$h{packager} = `rpm -q --qf '%{PACKAGER}' $p`;
    #$h{description} = `rpm -q --qf '%{DESCRIPTION}' $p`;
    #$h{group} = `rpm -q --qf '%{GROUP}' $p`;

    return \%h;
}

sub opkg_test {
    
}

1;
