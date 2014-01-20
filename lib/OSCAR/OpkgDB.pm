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
use OSCAR::Env;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::OCA::OS_Detect;
use OSCAR::PackagePath;
use Data::Dumper;
use File::Basename;
use Carp;

@EXPORT = qw(
	     opkg_list_available
	     opkg_hash_available
	     opkg_list_installed
	     opkg_hash_installed
         opkg_api_path
         oscar_repostring
	     );

#$verbose = 1;

####
# List all opkgs which are available in the accessible repositories.
#
# Arguments: scope hash for detecting targetted distro
#            empty: local node
#            chroot => image_path : detect distro of specific image
#            fake=>{distro=>distroname, version=>distrover, arch=>arch}
#                don't detect distro, use passsed values
# 
# Returns array of API opkg names, undef if error.
####
sub opkg_list_available {
    my %scope = @_;
    my %opkgs;

    my $os;
    if (defined($scope{os})) {
        $os = $scope{os};
    } else {
        if (defined $scope{fake}) {
            $os = OSCAR::OCA::OS_Detect::open($scope{fake});
        } elsif (defined $scope{chroot}) {
            $os = OSCAR::OCA::OS_Detect::open($scope{chroot});
        } else {
            $os = OSCAR::OCA::OS_Detect::open();
        }
    }
    return undef if !$os;

    my $repo = make_repostring($os);
    my $pkg = $os->{pkg};
    if ($pkg eq "rpm") {
	my $verbose_switch="";
	$verbose_switch="--verbose" if $OSCAR::Env::oscar_verbose;
    	my $cmd="/usr/bin/yume $repo $verbose_switch --repoquery --nevra opkg-*-server";
        oscar_log(7, ACTION, "About to run: $cmd");
    	open CMD, "$cmd |" or die "Error: $!";
	    while (<CMD>) {
    	    if (m/^opkg-(.*)-server-(.*).noarch/) {
	    	    $opkgs{$1} = $2;
	        }
    	}
	    close CMD;
    } elsif ($pkg eq "deb") {
    	my $cmd="/usr/bin/rapt $repo --names-only search 'opkg-.*-server'";
        oscar_log(7, ACTION, "About to run: $cmd");
    	open CMD, "$cmd |" or die "Error: $!";
	    while (<CMD>) {
	        if (m/^opkg-(.*)-server/) {
    	    	$opkgs{$1} = 1;
    	    }
	    }
    	close CMD;
    } else {
	    return undef;
    }
    if (keys(%opkgs) == 0) {
        oscar_log(5, ERROR, "Impossible to find any OSCAR package");
        return undef;
    }

    # We remove the "opkg-" prefix in front of all OPKGs' name.
#     my %res;
#     foreach my $prefixed_name (keys %opkgs) {
#         if ($prefixed_name =~ m/^opkg-(.*)$/) {
#             $res{$1} = $opkgs{$prefixed_name};
#             print "---> $1 => $opkgs{$prefixed_name}\n";
#         }
#     }

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
#            For only returning opkgs of a certain class pass (in addition
#            to the normal scope selectors):
#            class => value
# Example:
#       %h = opkg_hash_available(class => "core");
#
# Returns hash of API opkgs.
#   key: opkg name
#   value: reference to subhash
#          subhash:
#              {package}     : short package name
#              {version}     : package version (and release)
#              {summary}     : long package name (Summary)
#              {packager}    : packager info
#              {description} : package description
#              {class}       : class info (multiplexed into group info)
#              {group}       : group info from native pkg mgr
#              {distro}      : compat distro string (e.g. rhel-5-i386)
#              {conflicts}   : list of conflicting packages
#   Returns undef if error.
####
sub opkg_hash_available {
    my %scope = @_;
    my %o;

    # filter class?
    my $class_filter;
    oscar_log(9, INFO, "opkg_hash_available: scope =");
    print Dumper(%scope) if($OSCAR::Env::oscar_verbose >= 9);
    if (defined($scope{class})) {
        $class_filter = $scope{class};
        delete $scope{class};
        oscar_log(9, INFO, "opkg_hash_available: class_filter = $class_filter");
    }
    my $os = $scope{os} if (defined($scope{os}));

    if (!$os) {
        if (defined $scope{fake}) {
            $os = OSCAR::OCA::OS_Detect::open($scope{fake});
        } elsif (defined $scope{chroot}) {
            $os = OSCAR::OCA::OS_Detect::open($scope{chroot});
        } else {
            $os = OSCAR::OCA::OS_Detect::open();
        }
    }

    return undef if !$os;

    my $repo = oscar_repostring($os);
    my $dist = os_cdistro_string($os);
    my $pkg = $os->{pkg};
    my $isdesc = 1;
    my ($name, $prefixed_name, $rel, $ver, $packager, $summary, $desc, $class, 
        $conflicts);
    my $group;
    if ($pkg eq "rpm") {
        my $verbose_switch="";
        $verbose_switch="--verbose" if $OSCAR::Env::oscar_verbose;
        my $cmd="/usr/bin/yume $repo $verbose_switch --repoquery --info opkg-*-server";
        %o = hash_from_cmd_rpm($cmd, $dist);
    } elsif ($pkg eq "deb") {
        my @opkgs = &opkg_list_available(%scope);
        require OSCAR::Utils;
        OSCAR::Utils::print_array (@opkgs);
        if (scalar (@opkgs) == 0) {
            carp "ERROR: did not found any OSCAR package";
            return undef;
        }
        @opkgs = map { "opkg-$_" } @opkgs;
        my $cmd="/usr/bin/rapt $repo show ".join(" ", @opkgs);
        oscar_log(7, ACTION, "About to run: $cmd");
        open CMD, "$cmd |" or die "Error: $!";
        while (<CMD>) {
            chomp;
            if (/^Package: (.*)$/) {
                $prefixed_name = $1;
                if ($prefixed_name =~ m/^opkg-(.*)$/) {
                    $name = $1;
                } else {
                    $name = $prefixed_name;
                }
                $isdesc = 0;
                $ver = $rel = $summary = $packager = $desc = $class = "";
                $conflicts = "";
            } elsif (/^Version: (.*)$/) {
                $ver = $1;
            } elsif (/^Section: (.*)$/) {
                $group = $1;
                $class = "";
                if ($group =~ m/^([^:]*):([^:]*)/) {
                    $group = $1;
                    $class = $2;
                }
            } elsif (/^Maintainer: (.*)$/) {
                $packager = $1;
            } elsif (/^Conflicts: (.*)$/) {
                $conflicts = $1;
            } elsif (/^Description: (.*), server part$/) {
                $isdesc = 1;
                $summary = $1;
            } elsif (/^Bugs:/) {
                $isdesc = 0;
            } else {
                if ($isdesc) {
                    m/^ (.*)$/;
                    $desc .= "$1\n";
                }
            }
            if ($name) {
                $o{$name} = {
                    "package" => $name,
                    version => $ver,
                    summary => $summary,
                    packager => $packager,
                    description => $desc,
                    class => $class,
                    group => $group,
                    distro => $dist,
                    conflicts => $conflicts,
                };
            }
        }
        close CMD;
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
        chomp(my $rpm_cmd = `which rpm`);
	my $cmd="$rpm_cmd -qa --qf='%{NAME} %{VERSION}-%{RELEASE}\n'";
    oscar_log(7, ACTION, "About to run: $cmd");
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
    # FIXME, should test return code.
    } elsif ($pkg eq "deb") {
	my $cmd="env COLUMNS=256 /usr/bin/dpkg -l \"opkg-*\"";
    oscar_log(7, ACTION, "About to run: $cmd");
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
    # FIXME, should test return code.
    } else {
	return undef;
    }
    return %opkgs;
}

####
# opkg_hash_installed
#
#            For only returning opkgs of a certain class pass (in addition
#            to the normal scope selectors):
#            class => value
# Example:
#       %h = opkg_hash_installed(class => "core");
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
#              {class}       : class info (multiplexed into group info)
#
####
sub opkg_hash_installed ($%) {
    my ($type, %scope) = @_;

    my %olist = &opkg_list_installed($type);
    my %opkgs;

    # filter class?
    my $class_filter;
    if (defined($scope{class})) {
	$class_filter = $scope{class};
	delete $scope{class};
    }

    my $os = OSCAR::OCA::OS_Detect::open();
    my $dist = &os_cdistro_string($os);

    my $pkg = $os->{pkg};
    if ($pkg eq "rpm") {
        my $qf = 
            "Name: %{NAME}\\n".
            "Version: %{VERSION}\\n".
            "Release: %{RELEASE}\\n".
            "Group: %{GROUP}\\n".
            "Packager: %{PACKAGER}\\n".
            "Summary: %{SUMMARY}\\n".
            "Description:\\n%{DESCRIPTION}\\n";

        my $cmd = "rpm -q --qf '".$qf."' ";
        map { $cmd .= "opkg-$_ " } (keys(%olist));
        %opkgs = &hash_from_cmd_rpm($cmd, $dist);

    } elsif ($pkg eq "deb") {
        for my $name (keys(%olist)) {
            $opkgs{$name} = &opkg_localdeb_info($name);
        }
    }

    # go through result and apply the class filter, if needed
    if ($class_filter) {
        oscar_log(9, INFO, "Filtering for class = \"$class_filter\"");
        for my $p (keys(%opkgs)) {
            my %h = %{$opkgs{$p}};
            oscar_log(9, NONE, "      $p -> class: $h{class}");
            if ($h{class} ne $class_filter) {
                delete $opkgs{$p};
                oscar_log(9, NONE, "      $p -> class: $h{class}i ... deleted");
            }
        }
    }
    return %opkgs;
}

####
# opkg_api_path
#
# Returns the path where the opkg API stuff for a given OPKG is installed, by
# querying the local RPM/DEB database for the location of the config.xml file
# (the config.xml file is allways there).
# The opkg-API package must be installed locally!
#
# Input: name of the OPKG we are looking for.
# Return: path name (where the config.xml file is), undef if error.
####
sub opkg_api_path ($) {
    my ($name) = @_;
    my $p = "opkg-$name";

    my $os = &distro_detect_or_die();

    my $path;
    if ($os->{pkg} eq "rpm") {
        chomp($path = `rpm -ql $p | grep config.xml`);
    } elsif ($os->{pkg} eq "deb") {
        chomp($path = `dpkg -L $p | grep config.xml`);
    } else {
        oscar_log(5, ERROR, "ERROR: Unsupported packaging type: $os->{pkg}");
        return undef;
    }
    return dirname($path) if $path;
}

####
# oscar_repostring: Prepare arguments string with repository names for
#                  the passed os.
#
# Only querying the OSCAR repository, not the distro repository!
####
sub oscar_repostring {
    my ($os) = @_;

    my $orepo = OSCAR::PackagePath::oscar_repo_url(os=>$os);
    my $repo;
    for my $r (split /,/, $orepo) {
        $repo .= " --repo $r";
    }
    $repo =~ s/^ //;
    return $repo;
}

##########################################################################
### Helper functions, not exported
##########################################################################

################################################################################
# Return, undef if error.                                                      #
#                                                                              #
# TODO: looks like a lot of code dupliction with opkg_hash_available           #
################################################################################
sub hash_from_cmd_rpm ($$) {
    my ($cmd, $dist) = @_;

    my %o;
    my $isdesc = 1;
    my ($name, $rel, $ver, $packager, $summary, $desc, $class, $group);
    my ($conflicts);
    oscar_log(7, ACTION, "About to run: $cmd");
    open CMD, "$cmd |" or die "Error: $!";
    while (<CMD>) {
    chomp;
    if (/^Name\s*: (.*)$/) {
        if ($name) {
        $o{$name} = {
            package => $name,
            version => "$ver-$rel",
            summary => $summary,
            packager => $packager,
            description => $desc,
            class => $class,
            group => $group,
            distro => $dist,
        };
        }
        my $name_string = $1;
        if (($name_string =~ /^opkg-(.*)-(server|client)$/) ||
        ($name_string =~ /^opkg-(.*)$/)) {
        $name = $1;
        } else {
            oscar_log(5, ERROR, "Unexpected package name: $name_string");
            return undef;
        }
        $isdesc = 0;
        $ver = $rel = $summary = $packager = $desc = $class = "";
        $conflicts = "";
    } elsif (/^Version\s*:\s*(.*)\s*$/) {
        $ver = $1;
    } elsif (/^Release\s*:\s*(.*)\s*$/) {
        $rel = $1;
    } elsif (/^Packager\s*:\s*(.*)\s*$/) {
        $packager = $1;
    } elsif (/^Group\s*:\s*(.*)\s*$/) {
        $group = $1;
        $class = "";
        if ($group =~ m/^([^:]*):([^:]*)/) {
        $group = $1;
        $class = $2;
        }
    } elsif (/^Summary\s*:\s*(.*)\s*$/) {
        $summary = $1;
        $summary =~ s/, server part$//;
    } elsif (/^Description\s*:/) {
        $isdesc = 1;
    } elsif ($isdesc) {
        $desc .= "$_\n";
    }
    }
    close CMD;
    if ($name) {
    $o{$name} = {
        package => $name,
        version => "$ver-$rel",
        summary => $summary,
        packager => $packager,
        description => $desc,
        class => $class,
        group => $group,
        distro => $dist,
    };
    }
    return %o;
}


####
# Get information from a RPM package.
#
# Argument: package name.
#
# Return: hash with package related info.
####
sub opkg_localrpm_info {
    my ($name) = @_;
    my %h;

    my $p = "opkg-$name";
    $h{name} = $name;
    $h{version} = `rpm -q --qf '%{VERSION}-%{RELEASE}' $p`;
    $h{package} = `rpm -q --qf '%{SUMMARY}' $p`;
    $h{packager} = `rpm -q --qf '%{PACKAGER}' $p`;
    $h{description} = `rpm -q --qf '%{DESCRIPTION}' $p`;
    my $class = `rpm -q --qf '%{GROUP}' $p`;
    $class =~ s/^[^:]*://g;
    $h{class} = $class;

    return \%h;
}

####
# Get information from a Debian package.
#
# Argument: package name.
#
# Return: hash with package related info.
####
sub opkg_localdeb_info {
    my ($name) = @_;
    my %h;

    my $p = "opkg-$name";
    $h{name} = $name;
    # Remember with Debian package we do not have two different entries for
    # summary and description, the two are in "Description": the first line
    # is the summary and the other lines are the full description.
    my $description = `dpkg-query -W -f='\${Description}' $p`;
    my @summary = split("\n", $description);
    $h{version} = `dpkg-query -W -f='\${VERSION}' $p`;
    $h{package} = $summary[0];
    $h{packager} = `dpkg-query -W -f='\${Maintainer}' $p`;
    $description =~ s/$summary[0]//;
    $h{description} = $description;
    $h{group} = `dpkg-query -W -f='\${Section}' $p`;

    return \%h;
}

sub opkg_test {
    
}

1;
