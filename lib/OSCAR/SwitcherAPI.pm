package OSCAR::SwitcherAPI;

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Copyright (c) 2008, Geoffroy Vallee <valleegr@ornl.gov>
#                     Oak Ridge National Laboratory.
#                     All rights reserved.
#

#
# $Id: SwitcherAPI.pm 7035 2008-06-17 02:31:41Z valleegr $
# This module makes the interface between ODA and switcher. ODA is used to store
# data necessary for switcher.
#

# TODO: - Write a function to delete switcher data for a given package.
#       - Support the flat file ODA mode.

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use Carp;
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);
use OSCAR::Logger;
use OSCAR::Database_generic;

@EXPORT = qw(
            get_switcher_data
            set_switcher_data
            store_opkgs_switcher_data
            );

my $configxml_path = "/var/lib/oscar/packages/";

################################################################################
# Store Switcher data into ODA.                                                #
#                                                                              #
# Param: opkg, name of OPKG for which we need to store switcher data.          #
#        tag, identifier of the "virtual package" provided by a given real     #
#             package. For instance, OpenMPI and MPICH provide both the tag    #
#             "mpi".                                                           #
#        name, package name following the pattern <name>-<version>.            #
#              Example: lam-7.1.2.                                             #
# Return: -1 if error, 0 if success.                                           #
################################################################################
sub set_switcher_data ($$$) {
    my ($opkg, $tag, $name) = @_;
    my %field_value_hash = ( "package_id"=>"$opkg",
                             "switcher_name"=>$name,
                             "switcher_tag"=>$tag );
    my %options = ();
    my @error_strings = ();
    insert_into_table (\%options,
                       "Packages_switcher",
                       \%field_value_hash,
                       \@error_strings);
    return 0;
}

################################################################################
# Get switcher data from ODA.                                                  #
#                                                                              #
# Param: - results_ref, reference to an array that stores switcher data about  #
#                       all registered OPKG. For each package, we have a hash  #
#                       with the following format:                             #
#                           package => <OPKG name>                             #
#                           switcher_tag => package tag (e.g., mpi).           #
#                           switcher_name => service name providing the tag    #
#                                            (e.g., lam-2.7.1).                #
#                       Each element of the array is such a hash.              #
#        - options_ref, reference to a array specifying query options (can be  #
#                       empty).                                                #
#        - errors_ref, reference to a array used to store error messages.      #
# Return: -1 if error, 0 if success.                                           #
################################################################################
sub get_switcher_data {
    my ($results_ref,
        $options_ref,
        $errors_ref) = @_;

    my $sql = "SELECT P.package, S.switcher_tag, S.switcher_name " .
              "FROM Packages P, Packages_switcher S " .
              "WHERE P.package=S.package";

    oscar_log_subsection "DB_DEBUG>$0:\n".
                         "===> in Database::get_packages_switcher SQL : $sql\n"
        if $$options_ref{debug};

    my $ret = OSCAR::Database_generic::do_select($sql,
                                                 $results_ref,
                                                 $options_ref,
                                                 $errors_ref);

    if ($ret == 1) {
        return 0;
    } elsif ($ret == 0) {
        return -1;
    } else {
        carp "ERROR: Unknow do_select return code ($ret)\n";
        return -1;
    }
}

################################################################################
# Store switcher data for a list of OPKG (if the OPKG has switcher data).      #
#                                                                              #
# Input: opkgs, list of OPKGs (their name) for which we want to store switcher #
#               data.                                                          #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub store_opkgs_switcher_data (@) {
    my (@opkgs) = @_;

    if (scalar (@opkgs) == 0) {
        oscar_log_subsection "INFO: we do not store any switcher data into ".
                             "ODA, the list of OPKGs is empty";
        return 0;
    }

    oscar_log_subsection "Storing switcher data for packages: ". 
        join(", ", @opkgs);

    foreach my $opkg (@opkgs) {
        my $xmlfile = "$configxml_path/$opkg/config.xml";
        if (! -f $xmlfile) {
            carp "ERROR: Impossible to access the config.xml file for $opkg";
            return -1;
        }
        else {
            # Is the config.xml file has a switcher data?
            my $tag = 
                OSCAR::Opkg::get_data_from_configxml ($xmlfile, "provide");
            if (!defined $tag) {
                print "INFO: OPKG $opkg does no have switcher info\n";
                return 0;
            }

            my $version =
                OSCAR::Opkg::get_opkg_version_from_configxml($xmlfile);
            if (!defined $version) {
                carp "ERROR: Impossible to get OPKG version from config XML ".
                     "file ($opkg)";
                return -1;
            }
            if (set_switcher_data ($opkg, "$opkg-$version", "$tag")) {
                carp "ERROR: Impossible to save switcher data ($opkg)";
                return -1;
            }
        }
    }
    return 0;
}

1;
