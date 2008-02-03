package OSCAR::NodeConfigManager;

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
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Utils;
use AppConfig;
use vars qw($config);
use Carp;

##########################################################
# A bunch of variable filled up with creating the object #
##########################################################
our $name;
our $ip;
our $mac;
our $partition;
our @opkgs;
our $hostname;
our $type;

$config = AppConfig->new(
    'NAME'      => { ARGCOUNT => 1 },
    'HOSTNAME'  => { ARGCOUNT => 1 },
    'IP'        => { ARGCOUNT => 1 },
    'MAC'       => { ARGCOUNT => 1 },
    'PARTITION' => { ARGCOUNT => 1 },
    'TYPE'      => { ARGCOUNT => 1 },
    'OPKGS'     => { ARGCOUNT => 1 },
    );

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

    if (!defined($config_file) || ! -f $config_file) {
        print "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    $config->file ($config_file);

    # Load configuration values
    $name               = $config->get('NAME');
    $ip                 = $config->get('IP');
    $mac                = $config->get('MAC');
    $partition          = $config->get('PARTITION');
    @opkgs              = split (" ", $config->get('OPKGS'));
    $hostname           = $config->get('HOSTNAME');
    $type               = $config->get('TYPE');
}

sub print_config ($) {
    my $self = shift;

    load_config($self);
    print "Node Configuration:\n";
    print "\tName: $name\n";
    print "\thostname: $hostname\n";
    print "\tType: $type\n";
    print "\tIP: $ip\n";
    print "\tMAC: $mac\n";
    print "\tPartition: $partition\n";
    print "\tOPKGS: @opkgs\n";
}

sub get_config ($) {
    my $self = shift;

    load_config($self);
    my %cfg = ( 'name'      => $name,
                'hostname'  => $hostname,
                'ip'        => $ip,
                'mac'       => $mac,
                'type'      => $type,
                'partition' => $partition,
                'opkgs'     => \@opkgs);
    return \%cfg;
}

sub set_config ($$) {
    my ($self, $cfg) = @_;

    print "Creating config file ".$self->{config_file}."\n";
    open (MYFILE, ">$self->{config_file}");
    print MYFILE "name\t\t = $cfg->{'name'}\n";
    print MYFILE "ip\t\t = $cfg->{'ip'}\n";
    print MYFILE "mac\t\t = $cfg->{'mac'}\n";
    print MYFILE "partition\t\t = $cfg->{'partition'}\n";
    print MYFILE "hostname\t\t = $cfg->{'hostname'}\n";
    print MYFILE "type\t\t = $cfg->{'type'}\n";
    print MYFILE "opkgs\t\t = ";
    my $opkgs = $cfg->{'opkgs'};
    OSCAR::Utils::print_array (@$opkgs);
    for (my $i=0; $i < scalar (@$opkgs); $i++) {
        if ($i != 0) {
            print MYFILE "\t\t\t$$opkgs[$i]";
        } else {
            print MYFILE "\t$$opkgs[$i]";
        }
        print MYFILE " \\ \n" if ($i != scalar (@$opkgs) - 1);
    }
    print MYFILE "\n";
    close (MYFILE);
}

1;

__END__