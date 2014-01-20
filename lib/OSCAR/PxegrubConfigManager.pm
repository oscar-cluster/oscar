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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use warnings;
use OSCAR::Utils;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
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
        oscar_log(1, ERROR, "The configuration file does not exist ($config_file)");
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
    oscar_log(5, INFO, "\tDownload URL: $download_url");
    oscar_log(5, INFO, "\tFile defining supported NICs: $nics_deffile");
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
