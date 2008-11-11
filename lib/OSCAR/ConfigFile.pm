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
# This Perl module is a simple abstraction to handle configuration files,
# extending the AppConfig Perl module (typically adding write operations). The
# goal is typically to be able to easily get and set a given key value in a
# given configuration file.

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Logger;
use OSCAR::Utils;
use OSCAR::FileUtils;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use AppConfig;
use AppConfig::State;
use Data::Dumper;
use warnings "all";

use Data::Dumper;

@EXPORT = qw(
            get_value
            set_value
            get_all_values
            );

################################################################################
# Get the value of a given key in a given configuration file. For instance,    #
# get_value ("/etc/yum.conf", "gpgkey") returns the value of the key 'gpgkey'  #
# from the /etc/yum.conf configuration file.                                   #
#                                                                              #
# Input: config_file, full path to the configuration file we want to analyse.  #
#        block, configuration files may be arranged in blocks, in that case,   #
#               if you want to access a given key under a given block, specify #
#               the block name here; otherwise, use undef or ""/               #
#               [main]                                                         #
#                  gpgcheck = 1                                                #
#        key, key we want the value from.                                      #
# Return: the key value is the key exists, undef if the key does not exist.    #
################################################################################
sub get_value ($$$) {
    my ($config_file, $block, $key) = @_;

    if (!defined($config_file) || ! -f $config_file) {
        carp "ERROR: the configuration file does not exist ($config_file)\n";
        return undef;
    }

    if (defined ($block) && $block ne "") {
        $key = $block . "_" .$key;
    }

    use vars qw($config);
    $config = AppConfig->new({
            CREATE => '^*',
        },
        $key            => { ARGCOUNT => 1 },
        );
    if (!defined ($config)) {
        carp "ERROR: Impossible to parse configuration file ($config_file)";
        return undef;
    }
    $config->file($config_file);

    return $config->get($key);
}

sub get_block_list ($) {
    my $config_file = shift;

    if (! -f $config_file) {
        carp "ERROR: the config file ($config_file) does not exist";
        return undef;
    }

    my $list_blocks = `grep '\\[' $config_file`;
#    print "List blocks ($config_file): $list_blocks";    

    my @blocks = split ("\n", $list_blocks);
    for (my $i=0; $i < scalar(@blocks); $i++) {
        $blocks[$i] =~ s/\[//g;
        $blocks[$i] =~ s/\]//g;
    }
    return @blocks;
}

# Return: 0 if success, -1 else.
sub set_value ($$$$) {
    my ($config_file, $block, $key, $value) = @_;

    if (!defined($config_file) || ! -f $config_file) {
        carp "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    if (!is_a_valid_string ($key)) {
        carp "ERROR: the key we try to set is not valid";
        return -1;
    }

    open (FILE, $config_file) or (carp "ERROR: Impossible to open $config_file",
                                  return -1);
    #
    # We first search the target block (if defined)
    #
    my $position = -1;
    my $line;
    if (defined ($block)) {
        while ($line = <FILE>) {
            $position++;
            $line = OSCAR::Utils::trim ($line);
            if ($line =~ /^\[$block\]/) {
                last;
            }
        }
    }

    #
    # We look for the key
    #
    $position++;
    while ($line = <FILE>) {
        $line = OSCAR::Utils::trim ($line);
        if ($line =~ /^$key/) {
            last;
        }
        $position++;
    }

    #
    # Now we change the line
    #
    $line = "$key=$value";
    if (OSCAR::FileUtils::replace_line_in_file ($config_file,
                                                $position,
                                                $line)) {
        carp "ERROR: Impossible to replace the line";
        return -1;
    }
    close (FILE);

    return 0;
}

################################################################################
# Get the value of all keys from a given configuration file. This function is  #
# based on the get_value function, therefore it means we do not deal with the  #
# key namespace. In other terms, you have to explicitely expand the key name   #
# if the key is part of a section (see example in the get_value function       #
# description).                                                                #
#                                                                              #
# Input: config_file, full path to the configuration file we want to analyse.  #
# Return: a hash with all keys and values, undef if we cannot parse the        #
#         configuration file. For instance, if the configuration file looks    #
#         like:                                                                #
#           var1 = value1                                                      #
#           var2 = value2                                                      #
#         The hash will look like: ( "var1", "value1", "var2", "value2" ).     #
################################################################################
sub get_all_values ($) {
    my ($config_file) = @_;

    if (!defined($config_file) || ! -f $config_file) {
        print "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    use vars qw($config);
    $config = AppConfig->new({
            CREATE => '^*',
        },
        );
    $config->file ($config_file);
    my %vars = $config->varlist("^*");
    while ( my ($key, $value) = each(%vars) ) {
        $vars{$key} = get_value ($config_file, undef, $key);
    }
    return %vars;
}

1;

__END__

=head1 NAME

OSCAR::ConfigFile, an abstraction on top of AppConfig for the management of
configuration files (read and write).

=head1 SYNOPSIS

This module allows one to read variable from a configuration file, including
when files are organized "Windows-style", a.k.a., init style or with blocks.

=head1 EXPORT

=item get_value

=item set_value

=item get_all_values

=head1 EXAMPLES

The following example read the variable "cachedir" from the block "main" from
the "/etc/yum.conf" configuration file.

=over 8

my $source = OSCAR::ConfigFile::get_value ("/etc/yum.conf", "main", "cachedir");

=back



=head1 AUTHOR

Geoffroy Vallee <valleegr at ornl dot gov>

=cut