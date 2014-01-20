package OSCAR::Opkg;

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# (C)opyright Bernard Li <bli@bcgsc.ca>.
#             All Rights Reserved.
#
# (C)opyright Oak Ridge National Laboratory
#             Geoffroy Vallee <valleegr@ornl.gov>
#             All rights reserved
#
# (C)opyright Erich Focht <efocht@hpce.nec.com>.
#             All Rights Reserved.
#
# $Id: Opkg.pm 7035 2008-06-17 02:31:41Z valleegr $
#
# OSCAR Package module
#
# This package contains subroutines for common operations related to
# the handling of OSCAR Packages (opkg).
# [EF]: Some of the stuff in Packages.pm should be moved here!

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use File::Basename;
use OSCAR::Env;
use OSCAR::Database;
use OSCAR::PackagePath;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use Carp;

@EXPORT = qw(
            create_list_selected_opkgs
            get_data_from_configxml
            get_list_core_opkgs
            get_list_opkg_dirs
            get_opkg_version_from_configxml
            opkg_print
            opkgs_install
            write_pgroup_files
            );


# name of OSCAR Package
my $opkg = basename($ENV{OSCAR_PACKAGE_HOME}) if defined ($ENV{OSCAR_PACKAGE_HOME});

# location of OPKGs shipped with OSCAR
my $opkg_dir;
if (defined $ENV{OSCAR_HOME}) {
    $opkg_dir = $ENV{OSCAR_HOME} . "/packages";
}

# Prefix print statements with "[package name]" 
sub opkg_print {
	my $string = shift;
	print("[$opkg] $string");
}

###############################################################################
# Get the list of OPKG available in $(OSCAR_HOME)/packages                    #
# Parameter: None.                                                            #
# Return:    Array of OPKG names. (Empty Array if problem)                    #
###############################################################################
sub get_list_opkg_dirs {
    my @opkgs = ();
    oscar_log(5, ERROR, "The OPKG directory does not exist ".
        "($opkg_dir).") if ( ! -d $opkg_dir );
    if ( ! -d $opkg_dir ) {
        oscar_log(5, ERROR, "The OPKG directory does not exist ($opkg_dir).");
        return (@opkgs);
    }

    opendir (DIRHANDLER, "$opkg_dir")
        or (oscar_log(5, ERROR, "Impossible to open $opkg_dir"), return(@opkgs));

    foreach my $dir (sort readdir(DIRHANDLER)) {
        if ($dir ne "." && $dir ne ".." && $dir ne ".svn" 
            && $dir ne "package.dtd") {
            push (@opkgs, $dir);
        }
    }
    return @opkgs;
}

# Return: 0 if success, -1 else.
sub opkgs_remove ($@) {
    my ($type, @opkgs) = (@_);

    if (!scalar(@opkgs)) {
        oscar_log(5, ERROR, "No opkgs passed!");
        return -1;
    }

    my $distro_id = OSCAR::PackagePath::get_distro();
    require OSCAR::RepositoryManager;
    my $rm = OSCAR::RepositoryManager->new(distro=>$distro_id); 

    my @olist;
    if ($type eq "api") {
        @olist = map { "opkg-".$_ } @opkgs;
    } elsif ($type =~ /^(client|server)$/) {
        @olist = map { "opkg-".$_."-$type" } @opkgs;
    } else {
        oscar_log(5, ERROR, "Unsupported opkg type: $type");
        return -1;
    }
    oscar_log(3, INFO, "Need to remove the following packages: " . join (", ", @olist));
    my ($err, @out) = $rm->remove_pkg("/", @olist);
    if ($err) {
        oscar_log(5, ERROR, "Problem occured during smart_remove ($err):");
        print join("\n",@out)."\n" if($OSCAR::Env::oscar_verbose >= 6);
        return -1;
    }

    return 0;
}

###############################################################################
# Install the server part of the passed OPKGs on the local system             #
# Parameters:                                                                 #
#            type of opkg to be installed (one of api, server, client)        #
#            list of OPKGs.                                                   #
# Return:    -1 is error, 0 else.                                             #
###############################################################################
sub opkgs_install ($@) {
    my ($type, @opkgs) = (@_);

    if (!scalar(@opkgs)) {
        oscar_log(5, ERROR, "No opkgs passed!");
        return -1;
    }

    my $distro_id = OSCAR::PackagePath::get_distro();
    require OSCAR::RepositoryManager;
    my $rm = OSCAR::RepositoryManager->new(distro=>$distro_id);
    
    my @olist;
    if ($type eq "api") {
        @olist = map { "opkg-".$_ } @opkgs;
    } elsif ($type =~ /^(client|server)$/) {
        @olist = map { "opkg-".$_."-$type" } @opkgs;
    } else {
        oscar_log(5, ERROR, "Unsupported opkg type: $type");
        return -1;
    }
    oscar_log(3, INFO, "Need to install the following packages: " . join (", ", @olist));
    my ($err, @out) = $rm->install_pkg("/", @olist);
    if ($err) {
        oscar_log(5, ERROR, "Problem occured during smart_install ($err):");
        print join("\n",@out)."\n" if($OSCAR::Env::oscar_verbose >= 6);
        return -1;
    }
    return 0;
}

###############################################################################
# Get a list of the client binary packages that we want to install.  Make a   #
# new file containing the names of all the binary packages to install.        #
# This is used for the creation of a temporary file when we build a new       #
# image.                                                                      #
# Input: file where the list has to be written.                               #
# Return: 0: Ok, -1: Failure.
###############################################################################
sub create_list_selected_opkgs ($) {
    my $outfile = shift;

    my @opkgs = list_selected_packages();
    open(OUTFILE, ">$outfile")
        or (oscar_log(5, ERROR, "Could not open $outfile"), return -1);
    foreach my $opkg_ref (@opkgs) {
        my $opkg = $$opkg_ref{package};
        my $pkg = "opkg-".$opkg."-client";
        print OUTFILE "$pkg\n";
    }
    close(OUTFILE);
    return 0;
}

#
# Write group files which are ready to be used by SystemInstaller as
# additional package files.
#
sub write_pgroup_files {
    my (@pgroups, @groups_list, @errors);
    OSCAR::Database::get_groups_for_packages(\@groups_list, {}, \@errors, undef);
    foreach my $groups_ref (@groups_list){
	    push @pgroups, $$groups_ref{group_name};
    }
    foreach my $pset (@pgroups) {
	    my (@res, @errs);
	    &get_group_packages($pset, \@res, {}, \@errs);
	    my $file = $OSCAR::PackagePath::PGROUP_PATH."/$pset.pgroup";
	    oscar_log(5, INFO, "Writing package group file for client installation: $file");
	    local *OUT;
	    open OUT, "> $file" or (oscar_log(5, ERROR, "Could not write $file : $!"), return -1);
	    for my $p (@res) {
	       print OUT "opkg-".$p->{package}."-client\n";
    }
	close OUT;
    }
    return 0;
}

################################################################################
# Gets the version of a give OPKG parsing a config.xml file. For that we need  #
# to parse the OPKG changelog for that.                                        #
#                                                                              #
# Input: configxml, path to the config.xml file we need to parse in order to   #
#                   extract data.                                              #
# Return: the OPKG version, undef if error.                                    #
################################################################################
sub get_opkg_version_from_configxml ($) {
    my ($configxml) = @_;

    require OSCAR::FileUtils;
    my $ref = OSCAR::FileUtils::parse_xmlfile ($configxml);
    if (!defined $ref) {
        oscar_log(5, ERROR, "Impossible to parse XML file ($configxml)");
        return undef;
    }

    my $changelog_ref = $ref->{changelog}->{versionEntry};
    my @versions;
    foreach my $entry (@$changelog_ref) {
        push (@versions, "$entry->{version}") if defined $entry->{version};
    }

    require OSCAR::Utils;
    require OSCAR::VersionParser;
    my $max = $versions[0];
    foreach my $v (@versions) {
        if (OSCAR::VersionParser::version_compare (
            OSCAR::VersionParser::parse_version($max),
            OSCAR::VersionParser::parse_version($v)) < 0) {
            $max = $v;
        }
    }
    return $max;
}

################################################################################
# Get the value of a specific tag from a config.xml file. Note that this is a  #
# basic function, the tag has to be a first level tag, if not it won't work.   #
#                                                                              #
# Input: configxml, path to the config.xml file we need to parse.              #
#        key, XML tag we are to look for.                                      #
# Return: the value of the XML tag, undef if errors.                           #
################################################################################
sub get_data_from_configxml ($$) {
    my ($configxml, $key) = @_;

    require OSCAR::FileUtils;
    my $ref = OSCAR::FileUtils::parse_xmlfile ($configxml);
    if (!defined $ref) {
        oscar_log(5, ERROR, "Impossible to parse XML file ($configxml)");
        return undef;
    }

    my $provide = $ref->{$key};
    return $provide;
}

################################################################################
# Give the list of core OPKGs from the config file (/etc/oscar/opkgs/core.conf #
# This allow us to simplify the bootstrapping: with a single file, we can get  #
# the list of all core OPKGs, which is not available by default if you use     #
# remote repositories.                                                         #
#                                                                              #
# Input: None.                                                                 #
# Return: list of core OSCAR packages (array of OPKGs' name), undef if error.  #
################################################################################
sub get_list_core_opkgs () {
    my $path = "/etc/oscar/opkgs/core.conf";
    if (! -f $path) {
        oscar_log(5, ERROR, "Config file for core OPKGs not available ($path)");
        return undef;
    }
    my @core_opkgs = ();
    my $p;
    open(DAT, $path) 
        or (oscar_log(5, ERROR, "Could not open file ($path)."), return undef);
    while ($p = <DAT>) {
        chomp($p);
        unshift (@core_opkgs, $p);
    }
    close (DAT);
    oscar_log(5, INFO, "Available core packages: ");
    OSCAR::Utils::print_array (@core_opkgs) if($OSCAR::Env::oscar_verbose >= 5);
    if (scalar (@core_opkgs) == 0) {
        return undef;
    } else {
        return @core_opkgs;
    }
}

1;
