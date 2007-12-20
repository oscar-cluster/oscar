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
# $Id: Configurator 5017 2006-06-16 15:00:26Z valleegr $
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
        );
    $config->file ($config_file);

    # Load configuration values
    $rapt_path          = $config->get('RAPT_PATH');
    $yume_path          = $config->get('YUME_PATH');
    $prereqs_path       = $config->get('PREREQS_PATH');
    $packman_path       = $config->get('PREREQS_PATH') . "/packman";
    $nioscar            = $config->get('OSCAR_NETWORK_INTERFACE');
    $oscarbinaries_path = $config->get('OSCAR_SCRIPTS_PATH');
}


sub get_scripts_path () {
    my $self = shift;
    return $oscarbinaries_path;
}

sub get_packman_path () {
    my $self = shift;
    return $packman_path;
}

sub get_yume_path () {
    my $self = shift;
    return $yume_path;
}

sub get_rapt_path () {
    my $self = shift;
    return $rapt_path;
}

sub get_prereqs_path () {
    my $self = shift;
    return $prereqs_path;
}

1;

__END__