package OSCAR::ConfigFile;

#
# Copyright (c) 2008 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
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
#
# This Perl module is a simple abstraction to handle configuration file. The
# goal is typically to be able to easily get and set a given key in a given
# configuration file.

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Logger;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use AppConfig;
use warnings "all";

@EXPORT = qw(
            get_value
            );

################################################################################
# Get the value of a given key in a given configuration file. For instance,    #
# get_value ("/etc/yum.conf", "gpgkey") returns the value of the key 'gpgkey'  #
# from the /etc/yum.conf configuration file.                                   #
#                                                                              #
# Input: config_file, full path to the configuration file we want to analyse.  #
#        key, key we want the value from.                                      #
# Return: the key value is the key exists, undef if the key does not exist.    #
################################################################################
sub get_value ($$) {
    my ($config_file, $key) = @_;

    if (!defined($config_file) || ! -f $config_file) {
        print "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    use vars qw($config);
    $config = AppConfig->new(
        $key            => { ARGCOUNT => 1 },
        );
    $config->file ($config_file);

    return $config->get ($key);
}

1;