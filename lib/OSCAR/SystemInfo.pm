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
    open(DAT, $entry) || die("Could not open file!");
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
    print "Number of CPU(s): $data{'processor'}\n";
    print "Number of cores: $data{'cpu cores'}\n";
    print "Clock speed: $data{'cpu MHz'} MHz\n";
}

sub get_number_of_cache_levels ($) {
    my $self = shift;
    my $dir = "/sys/devices/system/cpu/cpu0/cache";
    my @dirs = OSCAR::FileUtils::get_dirs_in_path ($dir);
    return scalar @dirs;
}

sub cache_info ($) {
    my $self = shift;

    my %cpu_data = get_proc_info ($self);
    for (my $ncpu = 0; 
         $ncpu < ($cpu_data{'processor'} * $cpu_data{'cpu cores'});
         $ncpu++) {
        my $dir = "/sys/devices/system/cpu/cpu$ncpu/cache";
        print "\nCPU/Core ($ncpu) cache info:\n";
        for (my $i=0; $i<get_number_of_cache_levels($self); $i++) {
            my $path = "$dir/index$i";
            open(FILE, "$path/level") || die("Could not open file!");
            my $level = <FILE>;
            chomp $level;
            close (FILE);
            open(FILE, "$path/type") || die("Could not open file!");
            my $type = <FILE>;
            chomp $type;
            $type = "Shared" if ($type eq "Unified");
            close (FILE);
            open(FILE, "$path/size") || die("Could not open file!");
            my $size = <FILE>;
            chomp $size;
            close (FILE);
            print "\tL".$level." cache ($type): $size\n";
        }
        #my %data = read_proc_entry
    }
}
1;

__END__

