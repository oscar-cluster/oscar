package OSCAR::VMConfigManager;

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
# $Id$
#

use strict;
use warnings;
use Carp;
use AppConfig;

##########################################################
# A bunch of variable filled up when creating the object #
##########################################################
our $type;
our $hostos_ip;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { 
        config_file => "", 
        @_,
    };
    bless ($self, $class);
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
        'TYPE'            => { ARGCOUNT => 1 },
        'HOSTOS_IP'       => { ARGCOUNT => 1 },
        );
    $config->file ($config_file);

    # Load configuration values
    $type              = $config->get('TYPE');
    $hostos_ip         = $config->get('HOSTOS_IP');
}

sub print_config ($) {
    my $self = shift;

    load_config($self);
    print "\tVM type: $type\n";
    print "\tHostOS IP: $hostos_ip\n";
}

sub get_config ($) {
    my $self = shift;

    load_config($self);
    my %cfg = ( 
                'type'              => $type,
                'hostos_ip'         => $hostos_ip,
              );
    return \%cfg;
}

sub set_config ($$) {
    my ($self, $cfg) = @_;

    print "Creating config file ".$self->{config_file}."\n";
    print "$cfg->{'type'}, $cfg->{'hostos_ip'}\n";
    open (MYFILE, ">$self->{config_file}");
    print MYFILE "type\t\t = $cfg->{'type'}\n";
    print MYFILE "hostos_ip\t\t = ".$cfg->{'hostos_ip'}."\n";
    close (MYFILE);
}

1;

__END__
