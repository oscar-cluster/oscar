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
# $Id: Opkg.pm 5884 2007-06-08 07:35:50Z valleegr $
#
# OSCAR Package module
#
# This package contains subroutines for common operations related to
# the handling of OSCAR Packages (opkg)

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use vars qw(@EXPORT);
use base qw(Exporter);
use File::Basename;
use XML::Simple;
use Data::Dumper;
use OSCAR::Database;
use OSCAR::PackageSmart;
use Carp;

@EXPORT = qw(
            create_list_selected_opkgs
            get_list_opkg_dirs
            opkg_print
            opkgs_install_server
            prepare_distro_pools
            );

my $verbose = $ENV{OSCAR_VERBOSE};

# name of OSCAR Package
my $opkg = basename($ENV{OSCAR_PACKAGE_HOME}) if defined ($ENV{OSCAR_PACKAGE_HOME});

# location of OPKGs shipped with OSCAR
my $opkg_dir = $ENV{OSCAR_HOME} . "/packages";

# Prefix print statements with "[package name]" 
sub opkg_print {
	my $string = shift;
	print("[$opkg] $string");
}

###############################################################################
# Get the list of OPKG available in $(OSCAR_HOME)/packages                    #
# Parameter: None.                                                            #
# Return:    Array of OPKG names.                                             #
###############################################################################
sub get_list_opkg_dirs {
    my @opkgs = ();
    die ("ERROR: The OPKG directory does not exist ".
        "($opkg_dir)") if ( ! -d $opkg_dir );

    opendir (DIRHANDLER, "$opkg_dir")
        or die ("ERROR: Impossible to open $opkg_dir");
    foreach my $dir (sort readdir(DIRHANDLER)) {
        if ($dir ne "." && $dir ne ".." && $dir ne ".svn" 
            && $dir ne "package.dtd") {
            push (@opkgs, $dir);
        }
    }
    return @opkgs;
}

###############################################################################
# Install the server part of the passed OPKGs on the local system             #
# Parameter: list of OPKGs.                                                   #
# Return:    none.                                                            #
###############################################################################
sub opkgs_install_server {
    my (@opkgs) = (@_);

    if (!scalar(@opkgs)) {
	croak("No opkgs passed!");
    }

    #
    # Detect OS of master node.
    #
    # Fails HERE if distro is not supported!
    #
    my $os = &OSCAR::PackagePath::distro_detect_or_die();
    my $pm = OSCAR::PackageSmart::prepare_distro_pools ($os);

    my @olist = map { "opkg-".$_."-server" } @opkgs;
    my ($err, @out) = $pm->smart_install(@olist);
    if (!$err) {
        print "Error occured during smart_install:\n";
        print join("\n",@out)."\n";
        exit 1;
    }
}

###############################################################################
# Get a list of the client binary packages that we want to install.  Make a   #
# new file containing the names of all the binary packages to install.        #
# This is used for the creation of a temporary file when we build a new       #
# image.                                                                      #
# Input: file where the list has to be written.                               #
# Return: none.
###############################################################################
sub create_list_selected_opkgs {
    my $outfile = shift;

    my @opkgs = list_selected_packages("all");
    open(OUTFILE, ">$outfile") or croak("Could not open $outfile");
    foreach my $opkg_ref (@opkgs) {
        my $opkg = $$opkg_ref{package};
        my $pkg = "opkg-".$opkg."-client";
        print OUTFILE "$pkg\n";
    }
    close(OUTFILE);
}

#
# Write group files which are ready to be used by SystemInstaller as
# additional package files.
#
sub write_pgroup_files {
    my (@pgroups, @groups_list, @errors);
    OSCAR::Database::get_groups_for_packages(\@groups_list, {}, \@errors);
    foreach my $groups_ref (@groups_list){
	push @pgroups, $$groups_ref{group_name};
    }
    foreach my $pset (@pgroups) {
	my (@res, @errs);
	&get_group_packages($pset, \@res, {}, \@errs);
	my $file = $OSCAR::PackagePath::PGROUP_PATH."/$pset.pgroup";
	print "Writing package group file for client installation: $file\n";
	local *OUT;
	open OUT, "> $file" or die "Could not write $file : $!";
	for my $p (@res) {
	    print OUT "opkg-".$p->{package}."-client\n";
	}
	close OUT;
    }
}


1;
