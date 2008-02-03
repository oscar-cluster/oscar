package OSCAR::PartitionConfigManager;

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
# $Id: PartitionConfigManager.pm 6774 2007-12-21 14:42:07Z valleegr $
#

use strict;
use warnings;
use Carp;
use AppConfig;

##########################################################
# A bunch of variable filled up with creating the object #
##########################################################
our $name;
our $arch;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { 
        config_file => "", 
        @_,
    };
    bless ($self, $class);
    load_config ($self);
    return $self;
}

sub load_config ($) {
    my $self = shift;
    my $config_file = $self->{config_file};

    require AppConfig;

    if (!defined($config_file) || ! -f $config_file) {
        print "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    use vars qw($config);
    $config = AppConfig->new(
        'NAME'      => { ARGCOUNT => 1 },
        'ARCH'      => { ARGCOUNT => 1 },
        );
    $config->file ($config_file);

    # Load configuration values
    $name              = $config->get('NAME');
    $arch              = $config->get('ARCH');
}

sub print_config {
    print "Partition Configuration:\n";
    print "\tName: $name\n";
}

sub get_config {
    my %cfg = ('name' => $name, 'arch' => $arch );
    return \%cfg;
}

1;

__END__
