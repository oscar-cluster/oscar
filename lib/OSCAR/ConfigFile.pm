package OSCAR::ConfigFile;

#
# Copyright (c) 2008-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::Logger;
use OSCAR::Utils;
use OSCAR::FileUtils;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use AppConfig;
use AppConfig::State;
use warnings "all";

@EXPORT = qw(
            get_all_values
            get_block_list
            get_value
            set_value
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
            CREATE => '1',
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

# Return the list of blocks within a config file. To get more details about
# what is a block, please refer to the AppConfig documentation (perldoc
# AppConfig).
#
# Input: the path to the config file to parse.
# Return: an array with blocks' names or undef if no blocks or errors.
sub get_block_list ($) {
    my $config_file = shift;

    if (! -f $config_file) {
        carp "ERROR: the config file ($config_file) does not exist";
        return undef;
    }

    my $list_blocks = `grep '\\[' $config_file`;
#    print "List blocks ($config_file): $list_blocks";    

    my @blocks = split ("\n", $list_blocks);
    my @final_blocks = ();
    for (my $i=0; $i < scalar(@blocks); $i++) {
        if (!OSCAR::Utils::is_a_valid_string ($blocks[$i]) 
            || OSCAR::Utils::is_a_comment($blocks[$i])) {
            next;
        }
        $blocks[$i] =~ s/\[//g;
        $blocks[$i] =~ s/\]//g;
        push (@final_blocks, $blocks[$i]);
    }
    return @final_blocks;
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
    my @file_data = <FILE>;
    close (FILE);
    #
    # We first search the target block (if defined)
    #
    my $block_start = -1;
    my $block_end = -1;
    my $pos = -1;
    my $line;
    if (defined ($block)) {
        foreach $line (@file_data) {
            $pos++;
            $line = OSCAR::Utils::trim ($line);
            if ($block_start != -1 && $line =~ /^\[(.*)\]/) {
                $block_end = $pos;
            }
            if ($line =~ /^\[$block\]/) {
                $block_start = $pos;
            }
        }
        # If the block is the last block in the file, we reach the end of the
        # file and in that case, the end of the block is the last line of the
        # file.
        if ($block_end == -1) {
            $block_end = $pos;
        }
    } else {
        # If no block is defined, the block is actually the full file.
        $block_end = scalar (@file_data);
        $block_start = 0;
    }

    #
    # We look for the key
    #
    my $position = 0;
    foreach $line (@file_data) {
        # We look for the line within the block
        $line = OSCAR::Utils::trim ($line);
        if ($position >= $block_start && $position <= $block_end &&
            $line =~ /^$key/) {
            last;
        }
        # if we reach the end of the block, we exit
        last if ($position == $block_end);
        $position++;
    }
    # If the key is not there, we add the key at the beginning of the block
    if ($position == $block_end) {
        $position = $block_start;
        $line = OSCAR::FileUtils::get_line_in_file ($config_file, $position);
        $line = "$key=$value\n".$line;
    } else {
        $line = "$key=$value";
    }

    # Otherwise we change the line
    if (OSCAR::FileUtils::replace_line_in_file ($config_file,
                                                $position,
                                                $line)) {
        carp "ERROR: Impossible to add \"$key=$value\" to $config_file";
        return -1;
    }

    return 0;
}

################################################################################
# Get the value of all keys from a given configuration file. This function is  #
# based on the get_value function, therefore it means we do not deal with the  #
# key namespace. In other terms, you have to explicitely expand the key name   #
# if the key is partof a section (see example in the get_value function       #
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
sub get_all_values ($$) {
    my ($config_file, $block) = @_;
    my %ret;

    if (!defined($config_file) || ! -f $config_file) {
        print "ERROR: the configuration file does not exist ($config_file)\n";
        return -1;
    }

    use vars qw($config);
    $config = AppConfig->new({
            CREATE => '^.*',
        },
        );
    $config->file ($config_file);
    my %vars = $config->varlist("^.*");
    my ($key, $value);
    while ( ($key, $value) = each(%vars) ) {
        if (defined ($block) ){
            if ($key !~ /$block\_(.*)/) {
                next;
            } else {
                $key = $1;
                $ret{$key} = get_value ($config_file, $block, $key);
            }
        } else {
            $ret{$key} = get_value ($config_file, undef, $key);
        }
    }
    return %ret;
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

=over 8

=item get_value

=item set_value

=item get_all_values

Returns all the values from a block of a given configuration file (if the block
is undef, it will return all the key/value pairs of the configuration file).

=item get_block_list

my @blocks = get_block_list ($my_config_file).

=back

=head1 EXAMPLES

The following example reads the variable "cachedir" from the block "main" from
the "/etc/yum.conf" configuration file.

=over 8

my $source = OSCAR::ConfigFile::get_value ("/etc/yum.conf", "main", "cachedir");

=back

The following example returns all the key/value pairs of the block "main" from "/etc/oscar/supported_distros.txt".

=over 8

my %hash = OSCAR::ConfigFile::get_all_values ("/etc/oscar/supported_distros.txt", "main");

=back

The following example sets the variable gpgcheck in the main section of the /etc/yum.conf file to 1,

=over 8

OSCAR::ConfigFile::set_value ("/etc/yum.conf", "main", "gpgcheck", "1")

=back

=head1 AUTHOR

Geoffroy Vallee <valleegr at ornl dot gov>

=cut
