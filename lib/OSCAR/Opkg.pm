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
# $Id$
#
# OSCAR Package module
#
# This package contains subroutines for common operations related to
# the handling of OSCAR Packages (opkg)

use vars qw(@EXPORT);
use base qw(Exporter);
use File::Basename;
@EXPORT = qw(
            get_list_opkg_dirs
            opkg_print
            );

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
        or die ("ERROR: Impossible to open $package_set_dir");
    foreach my $dir (sort readdir(DIRHANDLER)) {
        if ($dir ne "." && $dir ne ".." && $dir ne ".svn" 
            && $dir ne "package.dtd") {
            push (@opkgs, $dir);
        }
    }
    return @opkgs;
}

1;
