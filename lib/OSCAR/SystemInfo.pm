package OSCAR::SystemInfo;

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Copyright (c) 2008, Geoffroy Vallee <valleegr@ornl.gov>
#                     Oak Ridge National Laboratory.
#                     All rights reserved.
#

#
# $Id$
#

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Utils;
use OSCAR::FileUtils;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use Carp;
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { 
        output_file => "",
        @_,
    };
    bless ($self, $class);
    return $self;
}

sub read_proc_entry ($$) {
    my $self = shift;
    my $entry = shift;

    my %data;
    open(DAT, $entry) || (oscar_log(5, ERROR, "Unable to read $entry"), return undef);
    foreach my $line (<DAT>) {
        my ($key, $value) = split(":", $line);
        $key = OSCAR::Utils::trim ($key);
        $value = OSCAR::Utils::trim ($value);
        $data{$key} = $value;
    }
    close (DAT);

    return %data;
}

sub get_proc_info ($) {
    my $self = shift;

    return read_proc_entry ($self, "/proc/cpuinfo");
}


sub proc_info ($) {
    my $self = shift;

    my %data = get_proc_info ($self);
    if(%data) {
        oscar_log(5, INFO, "Processor(s) infos:");
        oscar_log(5, NONE, "    Number of CPU(s): $data{'processor'}");
        oscar_log(5, NONE, "    Number of cores: $data{'cpu cores'}");
        oscar_log(5, NONE, "    Clock speed: $data{'cpu MHz'} MHz");
    } else {
        oscar_log(5, ERROR, "Failed to get processor info.");
    }
}

sub get_number_of_cache_levels ($) {
    my $self = shift;
    my $dir = "/sys/devices/system/cpu/cpu0/cache";
    my @dirs = OSCAR::FileUtils::get_dirs_in_path ($dir);
    return scalar @dirs;
}

sub cache_info ($) {
    my $self = shift;

    oscar_log(5, INFO, "Processor(s) cache infos:");
    my %cpu_data = get_proc_info ($self);
    if(! %cpu_data) {
        oscar_log(5, ERROR, "Failed to get cpu cache info.");
        return;
    }
    for (my $ncpu = 0; 
         $ncpu < ($cpu_data{'processor'} * $cpu_data{'cpu cores'});
         $ncpu++) {
        my $dir = "/sys/devices/system/cpu/cpu$ncpu/cache";
        oscar_log(5, INFO, "CPU/Core ($ncpu) cache info:");
        for (my $i=0; $i<get_number_of_cache_levels($self); $i++) {
            my $path = "$dir/index$i";
            open(FILE, "$path/level") || (oscar_log(5, ERROR, "Failed to get cache level."), return);
            my $level = <FILE>;
            chomp $level;
            close (FILE);
            open(FILE, "$path/type") || (oscar_log(5, ERROR, "Failed to get cache type."), return);
            my $type = <FILE>;
            chomp $type;
            $type = "Shared" if ($type eq "Unified");
            close (FILE);
            open(FILE, "$path/size") || (oscar_log(5, ERROR, "Failed to get cache size."), return);
            my $size = <FILE>;
            chomp $size;
            close (FILE);
            oscar_log(5, NONE, "    L".$level." cache ($type): $size");
        }
        #my %data = read_proc_entry
    }
}
1;

__END__

