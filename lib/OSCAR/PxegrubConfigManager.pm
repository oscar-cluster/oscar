package OSCAR::PxegrubConfigManager;

#
# Copyright (c) 2008 Oak Ridge National Laboratory.
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
our $download_url;
our $nics_deffile;

$config = AppConfig->new(
    'DOWNLOAD_URL' => { ARGCOUNT => 1 },
    'NICS_DEFFILE'      => { ARGCOUNT => 1 },
    );

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {
        config_file => "/etc/oscar/pxegrub/pxegrub.conf",
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
    $download_url       = $config->get('DOWNLOAD_URL');
    $nics_deffile       = $config->get('NICS_DEFFILE');
}

sub print_config ($) {
    my $self = shift;

    load_config($self);
    print "\tDownload URL: $download_url\n";
    print "\tFile defining supported NICs: $nics_deffile\n";
}

sub get_config ($) {
    my $self = shift;

    load_config($self);
    my %cfg = (
                'download_url'  => $download_url,
                'nics_deffile'  => $nics_deffile,
              );
    return \%cfg;
}

;

__END__