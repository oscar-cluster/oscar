package OSCAR::Prereqs;

#
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#               All rights reserved
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy R. Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: Prereqs.pm 6690 2007-12-10 03:16:12Z valleegr $


use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::PackagePath;
use warnings "all";
use Carp;

@EXPORT = qw(
            check_installed
            check_removed
            get_config
            get_prereqs
            get_rawlist_prereqs
            show_prereqs_status
            );

my $verbose = $ENV{OSCAR_VERBOSE};

################################################################################
# Prerequisites config file. This is called prereq.cfg and should be located
# in the top directory of the otherwise generic-setup compatible prerequisites
# directory. Because prereqs are installed long before OSCAR is able to parse
# config.xml files, prereq.cfg is much simpler. The format is:
#
# [distro:version:architecture]
# package_name_or_rpm_file
# ...
# !package_name
# ...
# [distro2:version:architecture]
# ...
#
# The distro name, version or arch info can contain a "*". This matches
# like a .* regexp.
# Examples:
# [redhat-el*:3:*] matches all rhel3 architectures.
# [fedora:*:*]     matches all fedora core distros on all architectures
# [mandr*:*:*]     matches both mandrake and mandriva
# [*:*:*]          matches everything.
#
# Attention! The real distro names are used here, not the compat names!
#
# The lines after a distro identifier are package names or package file names
# (without the full path info). One package/filename per line is allowed!
# Lines starting with "!" specify packages which should be deleted. The lines
# are executed in the order of appearance.
# Processing of the prereq.cfg file stops after the parsing of the first
# matching block!
#
# Input: path, path where is the prereq config file.
#        distro, distro id we are looking for.
#        distrver, version of the distro we are looking for.
#        arch, hardware architecture we are looking for.
# Return: a reference to an array which contains the list of prereqs.
################################################################################
sub get_config ($$$$) {
    my ($path, $distro, $distver, $arch) = @_;
    local *IN;
    my (@config, $line, $match);

    open IN, "$path/prereq.cfg" or die "Could not open $path/prereq.cfg $!";
    while ($line = <IN>) {
        chomp $line;
        if ($line =~ /^\s*\[([^:]+):([^:]+):([^:]+)\]/) {
            my ($d,$v,$a) = ($1,$2,$3);
            $d =~ s/\*/\.*/g;
            $v =~ s/\*/\.*/g;
            $a =~ s/\*/\.*/g;
            my $str = "$distro:$distver:$arch";
            my $mstr = "($d):($v):($a)";
            $match = 0;
            if ($str =~ m/^$mstr$/) {
                $match = 1;
                print("found matching block [$d:$v:$a]\n") if ($verbose);
                last;
            }
        }
    }
    if ($match) {
        while ($line = <IN>) {
            chomp $line;
            last if ($line =~ /^\[([^:]+):([^:]+):([^:]+)\]/);
            next if ($line =~ /^\s*\#/);
            $line =~ s/^ *//g;
            next if ($line =~ /^$/);
            push @config, $line;
        }
    }
    close IN;
    if (@config) {
        return \@config;
    } else {
        return undef;
    }
}

sub get_prereqs (@) {
    my ($distro, $distrover, $arch, @paths) = @_;

    my $march = $arch;
    if ($arch eq "i386") {
        $march = "i?86";  # used for shell-like globbing
    } elsif($arch eq "ppc64") { # DIKIM added for supporting YDL-ppc64
        $march = "ppc64,ppc";
    }

    my (@removes, @installs, @shellcmds);
    for my $path (@paths) {
        # read in prereq.cfg file
        my $ref = OSCAR::Prereqs::get_config($path, $distro, $distrover, $arch);
        if (!$ref) {
            print "Couldn't match any config block in $path/prereq.cfg\n";
            next;
        }
        for my $line (@{$ref}) {
            $line =~ s/^\s*//g;
            next if ($line =~ /^\#/ && $line =~ /^$/);

            if ($line =~ /^sh:(.*)$/) {
                # shell script execution
                my $cmd = $1;
                $cmd =~ s/^\s*//;
                next if (!$cmd);
                push @shellcmds, $cmd;
            } else {
                # replace $arch with architecture in package config lines
                # this prevents packages to be interpreted as capabilities
                if ($line =~ /\$arch/) {
                $line =~ s:\$arch:$march:g;
                }
                my $remove = ($line =~ /^!/);
                if ($remove) {
                    $line =~ s/^!//g;
                }
                my ($pkg,$dummy) = split(/\s+/,$line);
                if ($remove) {
                    push (@removes, $pkg) if (is_package_installed($pkg));
                } else {
                    push (@installs, $pkg)  if (!is_package_installed($pkg));
                }
            }
        }
    }
    return (\@installs, \@removes, \@shellcmds);
}


sub get_rawlist_prereqs (@) {
    my ($distro, $distrover, $arch, @paths) = @_;

    my $march = $arch;
    if ($arch eq "i386") {
        $march = "i?86";  # used for shell-like globbing
    } elsif($arch eq "ppc64") { # DIKIM added for supporting YDL-ppc64
        $march = "ppc64,ppc";
    }

    my (@removes, @installs, @shellcmds);
    for my $path (@paths) {
        # read in prereq.cfg file
        my $ref = OSCAR::Prereqs::get_config($path, $distro, $distrover, $arch);
        if (!$ref) {
            print "Couldn't match any config block in $path/prereq.cfg\n";
            next;
        }
        for my $line (@{$ref}) {
            $line =~ s/^\s*//g;
            next if ($line =~ /^\#/ && $line =~ /^$/);

            if ($line =~ /^sh:(.*)$/) {
                # shell script execution
                my $cmd = $1;
                $cmd =~ s/^\s*//;
                next if (!$cmd);
                push @shellcmds, $cmd;
            } else {
                # replace $arch with architecture in package config lines
                # this prevents packages to be interpreted as capabilities
                if ($line =~ /\$arch/) {
                $line =~ s:\$arch:$march:g;
                }
                my $remove = ($line =~ /^!/);
                if ($remove) {
                $line =~ s/^!//g;
                }
                my ($pkg,$dummy) = split(/\s+/,$line);
                if ($remove) {
                    push (@removes, $pkg);
                } else {
                    push (@installs, $pkg);
                }
            }
        }
    }
    return (\@installs, \@removes, \@shellcmds);
}

sub is_package_installed ($) {
    my $p = shift;

    my $os = &OSCAR::PackagePath::distro_detect_or_die();
    my $suffix    = $os->{pkg};
    my $arch      = $os->{arch};

    my $rarch = $arch;
    if ($arch eq "i386") {
        $rarch = "i.86";  # used for regular expressions
    }elsif($arch eq "ppc64"){ # DIKIM added for supporting YDL-ppc64
        $rarch = "ppc64|ppc";
    }


    # strip suffix is argument is a complete package name
    if ($p =~ /\.$suffix$/) {
        $p =~ s/\.$suffix$//;
    }
    if ($p =~ /\.($rarch|noarch)$/) {
        $p =~ s/\.($rarch|noarch)$//;
    }
    if ($suffix eq "rpm") {
        if (!is_rpm_pkg_installed ($p)) {
            return 0;
        } else {
            return 1;
        }
    } elsif ($suffix eq "deb") {
        if (!is_deb_pkg_installed ($p)) {
            return 0;
        } else {
            return 1;
        }
    }

    # If we arrive there, something is wrong.
    return 0;
}

#
# Check whether packages were really installed or not
#
sub check_installed (@) {
    my (@pkgs) = @_;
    my $err = 0;
    for my $p (@pkgs) {
        if (!is_package_installed ($p)) {
            $err++;
            print "package $p is not installed\n";
        }
    }
    return $err;
}

sub check_removed (@) {
    my (@pkgs) = @_;
    my $err = 0;
    for my $p (@pkgs) {
        if (is_package_installed ($p)) {
            $err++;
        }
    }
    return $err;
}

# Function to verify if a debian package is installed
# @param: package name
# @return: 0 if installed
sub is_deb_pkg_installed ($) {
    my $pkg = shift;
    my $cmd = "dpkg-query -W -f='\${Status}\n' $pkg";
    my $ret = `$cmd`;
    chomp ($ret);
    if ($ret eq "install ok installed") {
        return 1;
    } else {
        return 0;
    }
}

# Function to verify if a RPM package is installed
# @param: package name
# @return: 0 if installed
sub is_rpm_pkg_installed ($) {
    my $p = shift;
    my $cmd = "rpm -q $p >/dev/null 2>&1";
    return (system($cmd));
}

sub show_prereqs_status {
    my ($distro, $distver, $arch, @paths) = @_;
    my $needed_actions = 0;
    my ($installs, $removes, $cmds) = 
        OSCAR::Prereqs::get_rawlist_prereqs($distro,
                                        $distver,
                                        $arch,
                                        @paths);
    print "Prereqs status (".join(",", @paths)."):\n";
    foreach my $p (@$installs) {
        if (!is_package_installed ($p)) {
            print "\t$p: \t\t\tneeds to be installed\n";
            $needed_actions++;
        } else {
            print "\t$p: \t\t\talready installed\n"
        }
    }
    foreach my $p (@$removes) {
        if (is_package_installed ($p)) {
            print "\t$p: \t\t\tneeds to be removed\n";
            $needed_actions++;
        } else {
            print "\t$p: \t\t\talready removed\n"
        }
    }
    print "\n\n";
    return $needed_actions;
}

1;
