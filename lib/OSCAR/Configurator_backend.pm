package OSCAR::Configurator_backend;

##############################################################
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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# Copyright (c) 2002 National Center for Supercomputing Applications (NCSA)
#                    All rights reserved.
# Copyright (c) 2007-2008 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2008 Oak Ridge National Laboratory
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# Written by Terrence G. Fleury (tfleury@ncsa.uiuc.edu)
#
# Extensions for configurator data stored in OSCAR database were
# written by    Erich Focht <efocht@hpce.nec.com>
#               Copyright (c) 2006 Erich Focht
#
# $Id$
##############################################################

use strict;
use base qw(Exporter);
our @EXPORT = qw(readInConfigValues);
use Carp;

use OSCAR::Database;
use OSCAR::Database_generic;
use OSCAR::Configbox;
use OSCAR::Logger;

#########################################################################
#  Subroutine: readInConfigValues                                       #
#  Parameter : 1. the configurator.html file location                   #
#              2. the OSCAR package name                                #
#              3. context (see Packages_config table in ODA)            #
#              4. selection arguments e.g. noarray => 1                 #
#  Returns   : A HASH reference with all related variable names (as     #
#              keys) and their values (as anonymous array references)   #
#########################################################################
sub readInConfigValues { # ($filename) -> $values

    my ($conffile, $opkg, $context, %sel) = @_;

    $context = "" if ! $context;
    # If the OPKG is not in the database (e.g. excluded packages for a specific
    # distribution), we stop here.
    my (%options, @errors);
    my @result = ();
    my $sql = "SELECT Packages.package FROM Packages WHERE Packages.package='$opkg'";
    oscar_log_subsection ("Checking if the OPKG has to be excluded...");
    OSCAR::Database_generic::do_select($sql,\@result, \%options, \@errors);
    if (!@result) {
        oscar_log_subsection ("OPKG $opkg excluded from that type of system");
        return 0;
    } else {
        oscar_log_subsection ("OPKG $opkg: Analysing default values");
    }

    my @res = OSCAR::Database::get_pkgconfig_vars(opkg => "$opkg",
                                                  context => "$context");
    if (!@res) {
        &OSCAR::Configbox::defaultConfigToDB($conffile, $opkg, $context);
        @res = OSCAR::Database::get_pkgconfig_vars(opkg => "$opkg",
                                                   context => "$context");
    }

    my %values = OSCAR::Database::pkgconfig_values(@res);

    if (exists($sel{noarray})) {
        for my $k (keys(%values)) {
            if (scalar(@{$values{$k}}) <= 1) {
                $values{$k} = $values{$k}[0];
            }
        }
    }
    return \%values;
}

1;

__END__

=head1 NAME

Configurator_backend - A set of function used by Configurator. Those functions
are like a library, independent from the GUI.

=head1 Exported functions

=over 8

=item readInConfigValues

Read the values from a Configurator configuration file.

=back

=cut