package OSCAR::ConfigManager;

#
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy R. Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#

#
# The file is the implementation of the ConfigManager class. This class allows
# the creation of object that represents the content of the OSCAR configuration
# file
#

#
# TODO: the current implementation only grabs few information from the 
# configuration file and therefore we do not have a generic API to access each
# different values. That could be improved in order to avoid an uncontroled
# growing the list of functions in the API.
#

#
# $Id$
#

use strict;
use warnings;
use Carp;

##########################################################
# A bunch of variable filled up with creating the object #
##########################################################
# Specify where Packman is
our $packman_path;
# Specify where rapt is
our $rapt_path;
# Specify where rapt is
our $yume_path;
# Specify where the prereqs are
our $prereqs_path;
# Specify the network interface used by OSCAR
our $nioscar;
# Specify where the OSCAR scripts are
our $oscarbinaries_path;
# Specify the db type (flat files or real db)
our $db_type;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { 
        config_file => "/etc/oscar/oscar.conf", 
        @_,
    };
    bless ($self, $class);
    load_oscar_config ($self);
    return $self;
}

sub load_oscar_config ($) {
    my $self = shift;
    my $config_file = $self->{config_file};

    require AppConfig;

    if (!defined($config_file) || ! -f $config_file) {
        print "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    use vars qw($config);
    $config = AppConfig->new(
        'OSCAR_NETWORK_INTERFACE'   => { ARGCOUNT => 1 },
        'OSCAR_SCRIPTS_PATH'        => { ARGCOUNT => 1 },
        'PREREQS_PATH'              => { ARGCOUNT => 1 },
        'RAPT_PATH'                 => { ARGCOUNT => 1 },
        'YUME_PATH'                 => { ARGCOUNT => 1 },
        'ODA_TYPE'                  => { ARGCOUNT => 1 },
        );
    $config->file ($config_file);

    # Load configuration values
    $rapt_path          = $config->get('RAPT_PATH');
    $yume_path          = $config->get('YUME_PATH');
    $prereqs_path       = $config->get('PREREQS_PATH');
    $packman_path       = $config->get('PREREQS_PATH') . "/packman";
    $nioscar            = $config->get('OSCAR_NETWORK_INTERFACE');
    $oscarbinaries_path = $config->get('OSCAR_SCRIPTS_PATH');
    $db_type            = $config->get('ODA_TYPE');
}

sub get_config () {
    my $self = shift;
    my %cfg = (
                'rapt_path'         => $rapt_path,
                'yume_path'         => $yume_path,
                'prereqs_path'      => $prereqs_path,
                'packman_path'      => $packman_path,
                'nioscar'           => $nioscar,
                'binaries_path'     => $oscarbinaries_path,
                'db_type'           => $db_type
              );
    return \%cfg;
}

1;

__END__