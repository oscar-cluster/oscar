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
use OSCAR::Logger;
use OSCAR::LoggerDefs;

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
        oscar_log(1, ERROR, "Configuration file does not exist ($config_file)");
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
    oscar_log(5, INFO, "VM type: $type");
    oscar_log(5, INFO, "HostOS IP: $hostos_ip");
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

    oscar_log(5, INFO, "Creating config file ".$self->{config_file});
    oscar_log(6, INFO, "type = $cfg->{'type'}, hostos_ip = $cfg->{'hostos_ip'}");
    open (MYFILE, ">$self->{config_file}");
    print MYFILE "type\t\t = $cfg->{'type'}\n";
    print MYFILE "hostos_ip\t\t = ".$cfg->{'hostos_ip'}."\n";
    close (MYFILE);
}

1;

__END__
