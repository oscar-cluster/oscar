package OSCAR::Database;

# Copyright 2003 NCSA
#       Neil Gorsuch <ngorsuch@ncsa.uiuc.edu>
# 

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

use strict;
use vars qw(@EXPORT $VERSION @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);

# oda may or may not be installed and initialized
eval " use oda; ";
my $oda_available = ! $@;
my $database_available = 0;

@EXPORT = qw( database_connect database_disconnect database_execute_command );

#
# Connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized.
# This function is not needed before executing any ODA 
# database functions, since they automatically connect to 
# the database if needed, but it is more effecient to call this
# function at the start of your program and leave the database
# connected throughout the execution of your program.
#

sub database_connect {

    # if the database is already available and connected, success
    return 1 if $database_available;

    # if oda was not installed the last time that 
    # this was called, try to load in the module again
    if ( ! $oda_available ) {
	eval "use OSCAR::oda";
	$oda_available = ! $@;
    }

    # if oda is still not installed, done with failure
    return 0 if ! $oda_available;

    # try to connect to the database
    if ( oda::connect( undef, undef ) ) {

	# then try to execute an oscar shortcut command
	$database_available = 
	    oda::execute_command( undef, "packages", undef, undef );

	# disconnect from the database if no shortcuts
        oda::disconnect( undef, undef )
	    if ! $database_available;
    }

    return $database_available;
}

#
# connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized
#

sub database_disconnect {

    # if the database is not connected, done
    return 1 if ! $database_available;

    # disconnect from the database
    oda::disconnect( undef, undef );
    $database_available = 0;

    return 1;
}

#
# call oda::execute command to execute a database command or shortcut,
# this is only needed to avoid having calling code have to do the
# conditional "use OSCAR::oda" in case they are executing at a point
# when the oda has not been installed yet
#

sub database_execute_command {

    my ( $options_ref,
         $command_args_ref,
         $results_ref,
         $error_strings_ref ) = @_;

    return oda::execute_command( $options_ref,
				 $command_args_ref,
				 $results_ref,
				 $error_strings_ref );
}

1;
