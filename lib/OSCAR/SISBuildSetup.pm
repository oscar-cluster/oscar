package OSCAR::SISBuildSetup;
#   $Id: SISBuildSetup.pm,v 1.2 2004/05/03 21:02:08 brechin Exp $
#
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
#
# Copyright (c) 2003 Oak Ridge National Laboratory.
#                    All rights reserved.

#general notes, todo list
#1. add in a method for adding global options to the dhcpd.conf
#2. Load @node_info with data from ODA
#3. retest the dhcpd.conf file with no global options

use strict;
use English;
use Carp;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Logger;

#export main for use
use vars qw(@EXPORT);
use base qw(Exporter);
our @EXPORT = qw(invoke);

#permanent vars
#files
my $conf_file_dhcp = "/etc/dhcpd.conf"; #location of the dhcpd.conf
my $conf_file_etchosts = "/etc/hosts"; #sim /etc/hosts
my $conf_file_sishosts = "/var/lib/systemimager/scripts/hosts"; #sim /var/lib/systemimager/hosts
my $data_file = "/tmp/data"; #raw data
my $SIS_dir = "/var/lib/systemimager/scripts/"; #systemimager scripts directory

#markers
my $front_marker = "#OSCAR machine generated...Do not edit this line or below (ODA/SIS)";
my $back_marker = "#OSCAR machine generated...Do not edit this line or above(ODA/SIS)";

#global data structures
my @in_array_dhcp; #global array containing the incoming dhcpd.conf file
my @temp_array_dhcp; #global array containing the new dhcpd.conf entries 
my @node_info; #global array containing the raw data for each compute node
my @error_array; #global array containing error information
my @dhcp_conf_info;#array containing extra values for dhcpd.conf entries
my @hosts_array; #array containing host info to write out to files, /etc/hosts and SIS/hosts
my %iphash; #global hash containing a hash for each subnet

sub invoke
#this gets everything running, the only method
#available to external callers
#returns 0 on success, 1 on a failure
#when one is returned, error output is printed
{
	oscar_log_section("Running ODA/SIS updater.");

	oscar_log_subsection("Reading from database.");
	read_from_database();
	oscar_log_subsection("Completed database read.");

	oscar_log_subsection("Loading node information.");
	load_node_mac_ip_info();
	oscar_log_subsection("Completed loading node information.");
	
	oscar_log_subsection("Generating dhcp entries.");
	generate_dhcpd_entries();
	oscar_log_subsection("Dhcp entries complete.");
	
	oscar_log_subsection("Redoing /etc/dhcpd.conf file.");
	if ( redo_file($conf_file_dhcp, $front_marker, $back_marker, @temp_array_dhcp) == 1)
	{
		print_errors();	
		return 1;
	}
	oscar_log_subsection("Redoing /etc/dhcpd.conf file complete.");

	oscar_log_subsection("Setting up SIS stuff.");
	if (setup_sis_stuff() == 1)
	{
		print_errors();	
		return 1;
	}
	if ( redo_file($conf_file_etchosts, $front_marker, $back_marker, @hosts_array) == 1)
	{
		print_errors();	
		return 1;
	}
	if ( redo_file($conf_file_sishosts, $front_marker, $back_marker, @hosts_array) == 1)
	{
		print_errors();	
		return 1;
	}
	oscar_log_subsection("SIS stuff setup complete.");

	oscar_log_subsection("Restarting dhcpd.");
	if ( restart_dhcpd() == 1)
	{
		print_errors();
		return 1;
	}
	oscar_log_subsection("Completed restarting dhcpd.");

	oscar_log_section("Completed running ODA/SIS updater.");
}

sub read_from_database
#currently opens up a text file and reads it into @node_info
#this method will be converted to an ODA read
{
	open(YADDA, "$data_file");
	@node_info = <YADDA>;
	chomp (@node_info);
	close(YADDA);
}

sub load_node_mac_ip_info
#loads the raw data from @node_info into %iphash, both global vars
#assumes the order of info to be (for each line in @node_info):
#nodename;ip;netmask;network;mac;imagename;domainname;bootkernel;routerip
#no return code 
{
	my $line;
	my @one_node;

	foreach $line (@node_info)
	{
		@one_node = split /;/, $line;
		$iphash{"$one_node[3]/$one_node[2]"}{$one_node[1]} = "$one_node[0],$one_node[4],$one_node[5],$one_node[6],$one_node[7],$one_node[8]";
	}
}

sub generate_dhcpd_entries
#builds the oscar entries into the output array for writing out 
#a new dhcpd.conf. Uses @iphash for the raw info, and @temp_array_dhcp 
#for the entries themselves
#no return code, nothing to check
{
	my $key;
	my $record;
	my @key_array;	
	my @record_array;
	my $line;

	foreach $key (keys %iphash)
	{
		@key_array = split /\//, $key;

		$line = "subnet $key_array[0] netmask $key_array[1] {\n";	
		push @temp_array_dhcp, $line;

		$line = "    group {\n";
		push @temp_array_dhcp, $line;

		foreach $record (keys %{$iphash{$key}})
		{
			@record_array = split /,/, $iphash{$key}{$record};

			$line = "        host $record_array[0] {\n";
			push @temp_array_dhcp, $line;

			$line = "            hardware ethernet $record_array[1];\n";
			push @temp_array_dhcp, $line;

			$line = "            fixed address $record;\n";
			push @temp_array_dhcp, $line;

			$line = "            filename \"$record_array[4]\";\n";
			push @temp_array_dhcp, $line;

			$line = "            option routers $record_array[5];\n";
			push @temp_array_dhcp, $line;

			$line = "            option domain-name \"$record_array[3]\";\n";
			push @temp_array_dhcp, $line;

			$line = "        }\n";
			push @temp_array_dhcp, $line;
		}

		$line = "    }\n";
		push @temp_array_dhcp, $line;

		$line = "}\n";
		push @temp_array_dhcp, "$line\n";
	}
}

sub restart_dhcpd
#restarts the dhcpd by calling a 'service restart'
#returns 0 if successfull restarting the daemon, 1 otherwise
{
	my $command = "/etc/init.d/dhcpd restart"; 
	return (run_command_general($command));
}

sub setup_sis_stuff
#sets up all the symlinks and makes entries 
#into the necessary hosts files 
#loads hosts_array with data to add to the hosts files later
{
	#makes use of iphash, $SIS_dir, hosts_array
	my @temp; #readdir on the SIS symlinks
	my @dirlist; #SIS symlinks with some stuff removed

	#all temp storage vars for looping
	my $line;
	my $record;
	my $key;
	my @record_array;
	my $match;

	if (-d $SIS_dir)
	{
		opendir(DNAME, $SIS_dir) or Carp::croak "error: cannot open directory ($SIS_dir) - $!\n";
		@temp = readdir(DNAME) or Carp::croak "error: cannot read directory ($SIS_dir) - $!\n";
	}
	else
	{
		my $e_string = "error in redo_file(): directory $SIS_dir does not exist.\n";
		print $e_string;
		add_error($e_string);
		return 1;
	}

	@dirlist = grep( !/^\.{1,2}$/, @temp); #remove the ...
	chomp(@dirlist);

	#iphash is global
	foreach $key (keys %iphash)
	{
		foreach $record (keys %{$iphash{$key}})
		{
			@record_array = split /,/, $iphash{$key}{$record};
			chomp($record);
			chomp(@record_array);
			#example 192.168.0.1  foobar.foodomain   foobar 
			push @hosts_array,"$record $record_array[0].$record_array[3] $record_array[0]\n";

			 # PATH_to_SIS/scripts/*
			foreach $line (@dirlist)
			{
				#$line =~ /^$record_array[0]/
				#basically, looking to see if the hostname exists as a symlink	
				if (index($line, "$record_array[0].sh") == 0)
				{
					$match = 1;
					last;
				}
			}

			if ($match == 0)
			{
				#Create symlink to SIS master script
				if (-f "$SIS_dir$record_array[2].master")
				{
					if ( (symlink("$SIS_dir$record_array[2].master", "$SIS_dir$record_array[0].sh")) == 0)
					{
						my $e_string = "error symlink failed for $SIS_dir$record_array[0].sh\n";
						print $e_string;
						add_error($e_string);
						return 1;
					}
				}
				else
				{
					my $e_string = "error Master script $SIS_dir$record_array[2].master does not exist for $record_array[0]\n";
					print $e_string;
					add_error($e_string);
					return 1;
				}
			}
			$match = 0;
		}
	}
	return 0;
}

sub redo_file
#generic method to reform a file, given 2 markers and an array of information thats formatted
#returns 1 if an error is encountered, 0 otherwise
#	$filename: file to be doctered
#	$my_front_marker: first marker in file
#	$my_back_marker: end marker in file
#	@info: array of info to write between the markers
{
	my ($filename, $my_front_marker, $my_back_marker, @info) = @_;
	my $status = 0;
	my $line;
	my @in_array;
	my @out_array;

	if (-e $filename)
	{
		open(YADDA, "$filename") or Carp::croak "cannot open file $filename:$!\n";
		@in_array = <YADDA>;
		chomp (@in_array);
		close(YADDA);
	}
	else
	{
		my $e_string = "error in redo_file(): file $filename does not exist.\n";
		print $e_string;
		add_error($e_string);
	}
		
	foreach $line (@in_array)
	{
		if(index ($line, $my_front_marker) >= 0) #front marker found
		{
			$status = 1;
			#move front marker to output array
			#call generating function
			push @out_array, "$line\n\n"; #pushing the marker
			
			#now push the built up entries
			push @out_array, @info;
		}
	
		if(index ($line, $my_back_marker) >= 0) #back marker found
		{
			if ($status != 1)
			{
				my $e_string = "error in redo_file(): back marker found, no front marker.\n";
				print $e_string;
				add_error($e_string);
				return 1;
			}
			$status = 2;
		}

		if ($status != 1)
		{
			#basically, push the line if the beginning marker has
			#not been found, or if the ending marker has been found
			push @out_array, "$line\n";
		}
	}

	if ($status == 1)
	{
		#error case, front marker found, no back marker
		#log error
		my $e_string = "error in redo_file(): front marker found in $filename, but no back marker.\n";
		print $e_string;
		add_error($e_string);
		return 1;
	}

	#no markers found
	if ($status == 0)
	{
		push @out_array, "\n$my_front_marker\n\n"; #pushing the front marker
		push @out_array, @info; #push the entries
		push @out_array, "$my_back_marker\n"; #pushing the back marker
	}

	open(YADDA, ">$filename") or Carp::croak "cannot open file $filename:$!\n";
	print YADDA @out_array;	
	close(YADDA);

	return 0;
}

#runs a commandstring and uses the open()
#to do it...prints what it is trying to run, and
#prints all stderr and stdout on a detected error
#	$cmd_string --> a string of a command to run
#returns 0 on success, one otherwise
sub run_command_general
{
	my ($cmd_string) = @_;

	my $aline;
	my @cmd_out;

	if (defined (open (CMD, "$cmd_string 2>&1 |")))
	{
		print "executing:$cmd_string\n";
		@cmd_out = <CMD>;
		chomp(@cmd_out);
		close(CMD);
	}
	else
	{
		my $e_string = "error executing:$cmd_string\n";
		print $e_string;
		add_error($e_string);
		return 1;
	}

	if ($CHILD_ERROR == 0)
	{
		return 0;
	}
	else
	{
		#log results
		my $e_string = "error executing:$cmd_string:\n";
		print $e_string;
		add_error($e_string);
		foreach $aline (@cmd_out)
		{
			print $aline."\n";
		}
		return 1;
	}
}


#this function adds an error to the global list
#@error_list...and thats it
#returns nothing
sub add_error
{
	my $error_string = shift;
	push @error_array, $error_string;
}

#this method prints out the global list
#@error_list
#returns nothing
sub print_errors
{
	my $error;
	foreach $error (@error_array)
	{
		print $error;
	}
}

1;
