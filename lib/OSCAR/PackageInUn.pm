package OSCAR::PackageInUn;
# 
#  $Id: PackageInUn.pm,v 1.1 2003/10/24 21:39:16 muglerj Exp $
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

use lib "$ENV{OSCAR_HOME}/lib";
use strict;
use OSCAR::Database;
use OSCAR::Package;

#i have no clue what this does
#but all the cool kids are doing it
use vars qw(@EXPORT);
use base qw(Exporter);
@EXPORT = qw(package_install,
             package_uninstall,
             set_installed,
             set_uninstalled,
             is_selected); 

#installs a package to either
#all clients, the server, an image, or any
#combination of the 3.
#	$package_name --> a valid package name, string
#	$testmode --> 1 or 0, sets testmode, string
#	$image  --> an image name, string, if it has a value
			#installs into the image
#	note: image name only, not full path		
#	$allnodes --> if has a value install on all nodes
#	$headnode --> if has a value install on headnode
#
#returns:
#   0 no install target
#   1 success (added to clients, server, and an image)	
#   2 installed on server(success)
#   3 installed on client(success)
#   4 installed on image(success)
#   5 installed on server and client(success)
#   6 installed on server and image(success)
#   7 installed on client and image(success)
#   -4 attempted install on server, choked
#   -5 attempted install on clients, choked
#   -6 attempted install on image, choked
#   -9 package is installed already, taking no actions
#
#   Important Note:
#   also sets "installed" field in table packages 
#   to 0 (uninstalled) for the package if
#   the return value is 1 (ONLY in this case)
sub package_install
{
	my ($package_name,
		$headnode,
	    $allnodes,
		$image,
		$testmode) = @_;

	set_uninstalled($package_name);
	my $test_value = is_installed($package_name);	

	if ($test_value =~ "1")
	{
		print "package is installed already, aborting...\n";
		return (-9);
	}

	if (!$headnode && !$allnodes && !$image)
	{
		print "no uninstall target selected\n";
		return (0);
	} 

	if($allnodes)
	{
		if(!run_install_client($package_name, $testmode))
		{
			print "cannot install to the nodes\n";
			return (-5);
		}
		else
		{
			if(!$headnode && !$image)
			{
				return (3);
			}
		}
	}
	if($headnode)
	{
		if(!run_install_server($package_name, $testmode))
		{
			print "cannot install on the server\n";
			return (-4);
		}
		else
		{
			if(!$allnodes && !$image)
			{
				return (2);
			}
		}
	}
	if($image)
	{
		if(!run_install_image($package_name, $testmode, $image))
		{
			print "cannot install to the image:$image\n";
			return (-6);
		}
		else
		{
			if(!$headnode && !$allnodes)
			{
				return (4);
			}
		}
	}

	if($image && $allnodes && !$headnode)
	{
		return (7);
	}
	elsif($headnode && $allnodes && !$image)
	{
		return (5);
	}
	elsif($headnode && $image && !$allnodes)
	{
		return (6);
	}

	if (!$testmode)
	{
		set_installed($package_name);
	}
	return (1);
}

#runs install scripts on all nodes (clients)
#installs rpms as needed
#	$package_name --> name of a package, scaler string
#	$testmode --> if set to "1" run in testmode, scaler string
#	if this field is not null, and $where is set to client
#	the image is acted on
#returns:
#	2 is did nothing
#	1 is success
#	0 for failure
sub run_install_client
{
	my ($package_name,
		$testmode) = @_;

	my $type = "oscar_clients";

	my $cmd_string;
	my $script_path;

	my @rpm_array;
	my $rpm;

	my @temp_list;

	my $flag = 0;
	
	if($testmode)
	{
		print "client install starts:\n";
	}

	$cmd_string = find_rpms($package_name, $type);
	if(length($cmd_string) > 3)
	{
		@rpm_array = split(/^\s/, $cmd_string);
		@rpm_array = split(/\s/, $rpm_array[1]);
		for $rpm (@rpm_array)
		{
			@temp_list = split(/\//,$rpm);
			if($testmode)
			{
				print "run this command:system(cpush $rpm /tmp)\n";
				print "run this command:system(cexec rpm -U /tmp/$temp_list[$#temp_list]\n";
			}
			else
			{
				#need to add some kind of sanity check here
				#$flag is never set to -1
				#clean up the nodes filesystem
				system("cpush $rpm /tmp");
				system("cexec rpm -U /tmp/$temp_list[$#temp_list]");
			}
		}
		$flag = 1;
	}
	
	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path = "$var/$package_name/scripts/post_client_rpm_install";

		if (-x $script_path)
		{
			if($testmode)
			{
				print "run this command:system(cpush $script_path /tmp)\n";
				print "run this command:system(cexec /tmp/post_client_rpm_install)\n";
			}
			else
			{
				system("cpush $script_path /tmp");
				system("cexec /tmp/post_client_rpm_install");
				#clean up the nodes filesystem
			}
			$flag = 1;
		}
	}
	return $flag;
}

#runs install scripts on an image (a client)
#installs rpms as needed
#	$package_name --> name of a package, scaler string
#	$testmode --> if set to "1" run in testmode, scaler string
#   $imagename --> string that is a valid imagename
#returns:
#	2 for did nothing
#	1 is success
#   0 is failure
sub run_install_image
{
	my ($package_name,
		$testmode,
		$imagename) = @_;

	my $type = "oscar_clients";

	my $cmd_string;
	my $cmd_string1;
	my $cmd_string2;
	my $script_path;

	my @rpm_array;
	my $rpm;

	my @temp_list;

	my $flag = 0;
	
	if (!(-d "/var/lib/systemimager/images/$imagename"))
	{
		print "image name is invalid\n";
		return (-1);
	}

	if($testmode)
	{
		print "image install starts:\n";
	}

	$cmd_string = find_rpms($package_name, $type);
	if(length($cmd_string) > 3)
	{
		@rpm_array = split(/^\s/, $cmd_string);
		@rpm_array = split(/\s/, $rpm_array[1]);
		for $rpm (@rpm_array)
		{
			@temp_list = split(/\//,$rpm);

			$cmd_string1 = "cp $rpm /var/lib/systemimager/images/$imagename/tmp";
			$cmd_string2 = "chroot /var/lib/systemimager/images/$imagename rpm -U /tmp/$temp_list[$#temp_list]";

			if ($testmode)
			{
				print "run this command:$cmd_string1\n";
				print "run this command:$cmd_string2\n";
			}
			else
			{
				#need some sanity checking here
				#add rpm removal here
				system($cmd_string1);
				system($cmd_string2);
			}
		}
		$flag = 1;
	}
	
	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path = "$var/$package_name/scripts/post_client_rpm_install";
		if (-x $script_path)
		{
			if($testmode)
			{
				print "run this command:system(cp $script_path /var/lib/systemimager/images/$imagename/tmp)\n";
				print "run this command:system(chroot /var/lib/systemimager/images/$imagename /tmp/post_client_rpm_install)\n";
			}
			else
			{
				#need some sanity checking here
				#need to clean up the filespace: insert rm
				system("cp $script_path /var/lib/systemimager/images/$imagename/tmp");
				system("chroot /var/lib/systemimager/images/$imagename /tmp/post_client_rpm_install");
			}
			$flag = 1;
		}
	}
	return $flag;
}

#runs install scripts on server
#installs rpms as needed
#	package_name --> name of a package, scaler string
#	testmode --> if set to "1" run in testmode, scaler string
#	if this field is not null, and where is set to client
#	the image is acted on
#returns:
#	2 for did nothing
#	1 is success
#   0 is failure
sub run_install_server
{
	my ($package_name,
		$testmode) = @_;

	my $type = "oscar_server";
	my $cmd_string1;
	my $cmd_string2;
	my $script_path1;
	my $script_path2;
	my $flag = 0;
	
	$cmd_string1 = find_rpms($package_name, "oscar_server");
	if(length($cmd_string1) > 1)
	{
		$cmd_string2 = "rpm -U $cmd_string1";
		if($testmode)
		{
			print "Do this on the server filesystem:\n";
			print "run this command:system($cmd_string2)\n";
		}
		else
		{
			print "system($cmd_string2)\n";
		}
		$flag = 1;
	}

	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path1 = "$var/$package_name/scripts/post_server_rpm_install";
		if (-x $script_path1)
		{
			if($testmode)
			{
				print "run this command:system($script_path1)\n";
			}
			else
			{
				#need some sanity checking here
				system($script_path1);
			}
			$flag = 1;
		}
		$script_path2 = "$var/$package_name/scripts/post_clients";
		if (-x $script_path2)
		{
			if($testmode)
			{
				print "run this command:system($script_path2)\n";
			}
			else
			{
				#need some sanity checking here
				system($script_path2);
			}
			$flag = 1;
		}
	}
	return ($flag);
}

#determines the rpms to install
#	$package_name --> a valid package, string
#	$type --> one of 2 strings
#		"oscar_server"
#		"oscar_client"
#returns: a string of rpms
sub find_rpms
{
	my ($package_name,
		$type) = @_;

	my $cmd_string1;
	my $cmd_string2;

	my @rpm_list_database;
	my @rpm_split;
	my $total_length;
	my $rpm;

	my @dirlist;
	my @dir_split;
	my $adir;

	my $pos;
	my $pos2;
	my $pos3;
	my $pos4;
	my $past;

	#get the stuff from the package RPMS dir
	$cmd_string1 = "$ENV{OSCAR_HOME}/packages/$package_name/RPMS/";

	opendir(DNAME, $cmd_string1) || die "cannot read directory: $!\n";
	@dirlist = grep( !/^\.{1,2}$/, readdir(DNAME));
	closedir(DNAME);

	@rpm_list_database = OSCAR::Database::database_rpmlist_for_package_and_group($package_name, $type);

	#figure out which rpms to install
	#Doh, rpm --queryformat "%{NAME}
	for $rpm (@rpm_list_database)
	{
		@rpm_split = split(/-/,$rpm);
		for $adir (@dirlist)
		{
			@dir_split = split(/-/,$adir);
			$pos = index($adir, $rpm);
			if ($pos == 0)
			{
				if ($#rpm_split > 0)
				{
					$pos2 = index($rpm_split[$#rpm_split], $dir_split[$#rpm_split]);
					if($pos2 == 0)
					{
						$past = $#rpm_split + 1;
						$pos3 = index($dir_split[$past], ".");
						if($pos3 > 0)
						{	 
							$cmd_string2 = "$cmd_string2 $cmd_string1$adir";
						}
					}
				}
				$pos4 = index($dir_split[1], ".");
				if($pos4 > 0)
				{
					$cmd_string2 = "$cmd_string2 $cmd_string1$adir";
				}
			}
		} 
	}
	return ($cmd_string2);
}



#uninstalls a package from all clients, the server, optionally an image
#	$package_name --> a valid package name, string
#	$testmode --> 1 or 0, sets testmode, string
#   $image  --> an image name, string
#	$allnodes --> if has a value uninstall on all nodes
#	$headnode --> if has a value, uninstall on headnode
#
#returns:
#   0 no uninstall target
#   1 success (removed from clients, server, and an image)	
#   2 uninstalled on server(success)
#   3 uninstalled on client(success)
#   4 uninstalled on image(success)
#   5 uninstalled on server and client(success)
#   6 uninstalled on server and image(success)
#   7 uninstalled on client and image(success)
#   -4 attempted uninstall on server, choked
#   -5 attempted uninstall on client, choked
#   -6 attempted uninstall on image, choked
#   -9 package is not installed, taking no actions
#
#   Important Note:
#   also sets "installed" field in table packages 
#   to 0 (uninstalled) for the package if
#   the return value is 1 (ONLY in this case)
sub package_uninstall
{
	my ($package_name,
		$headnode,
	    $allnodes,
		$image,
		$testmode) = @_;
	
	my $test_value = is_installed($package_name);	

	if ($test_value =~ "0")
	{
		print "package is not installed, aborting...\n";
		return (-9);
	}

	if (!$headnode && !$allnodes && !$image)
	{
		print "no uninstall target selected\n";
		return (0);
	} 

	if ($headnode)
	{ 
		if (!run_uninstall_script($package_name, $testmode, "server"))
		{
			print "cannot uninstall on server...no script found\n";
			return (-4);
		}
		else
		{
			if(!$allnodes && !$image)
			{
				return (2);
			}
		}
	}

	if ($allnodes)
	{
		if (!run_uninstall_script($package_name, $testmode, "client"))
		{
			print "cannot uninstall on clients...no script found\n";
			return (-5);
		}
		else
		{
			if(!$headnode && !$image)
			{
				return (3);
			}
		}
	}

	if($image)
	{
		if(!run_uninstall_script($package_name, $testmode, "client", $image))
		{
			print "cannot uninstall on the image\n";
			return (-6);
		}
		else
		{
			if(!$headnode && !$allnodes)
			{
				return (4);
			}
		}
	}

	if($image && $allnodes && !$headnode)
	{
		return (7);
	}
	elsif($headnode && $allnodes && !$image)
	{
		return (5);
	}
	elsif($headnode && $image && !$allnodes)
	{
		return (6);
	}
	if (!$testmode)
	{
		set_uninstalled($package_name);
	}
	return (1);
}

#this sets the installed field in table packages to 1
#takes as input a scaler string that is a package name
#does set oda's error code to verbose
#returns nothing, as nothing gets returned to me from oda
sub set_installed
{
	my ($package_name) = @_;	
	my @my_result;
	my $error_code = 1;

	my $cmdstring = "modify_records packages name=\"$package_name\" installed~1";

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);
}

#this sets the installed field in table packages to 0
#takes as input a scaler string that is a package name
#does set oda's error code to verbose
#returns nothing, as nothing gets returned to me from oda
sub set_uninstalled
{
	my ($package_name) = @_;	

	my @my_result;
	my $error_code = 1;

	my $cmdstring = "modify_records packages name=\"$package_name\" installed~0";

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);
}

#queries oda to see if a package is installed
#takes as input a scaler string that is a package name
#returns 1 if the package is installed, 0 otherwise
#does set oda's error code to verbose
sub is_installed
{
	my ($package_name) = @_;	

	my @my_result;
	my $error_code = 1;

	my $cmdstring = "read_records packages installed name=\"$package_name\"";

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);

	return $my_result[0];
}

#runs uninstall script on selected target
#	$package_name --> name of a package, scaler string
#	$test --> if set to "1" run in testmode, scaler string
#	$where --> string which describes one of 2 uninstalls
#		server or client
#	$imagename --> name of an image, scaler string
#	if this field is not null, and $where is set to client
#	the image is acted on
#returns:
#	1 is success
#	0 for failure
sub run_uninstall_script
{
	my ($package_name, $test, $where, $imagename) = @_;

	my $script_path = "";
	my $cmd_string1 = "cpush";
	my @temp_list;
	my $cmd_string2 = "cexec";

	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path = "$var/$package_name/scripts/post_$where\_rpm_uninstall";
		if (-x $script_path)
		{
			@temp_list = split(/\//,$script_path);
			if ($imagename)
			{
				if (!(-d "/var/lib/systemimager/images/$imagename"))
				{
					return (0);
				}

				$cmd_string1 = "cp $script_path /var/lib/systemimager/images/$imagename/tmp";
				#note: need to rm this from image
				$cmd_string2 = "chroot /var/lib/systemimager/images/$imagename /tmp/$temp_list[$#temp_list]";
				

				if ($test =~ "1")
				{
					print "image uninstall actions:\n";
					print "run this command:$cmd_string1\n";
					print "run this command:$cmd_string2\n";
				}
				else
				{
					#sanity check...
					system($cmd_string1);
					system($cmd_string2);
				}
				return (1);
			}
			elsif (($where =~ "client") && (!$imagename))
			{
				$cmd_string1 = "$cmd_string1 $script_path /tmp/$temp_list[$#temp_list]";
				$cmd_string2 = "$cmd_string2 /tmp/$temp_list[$#temp_list]";
				
				if ($test =~ "1")
				{
					print "client uninstall actions:\n";
					print "Push this to the nodes:$cmd_string1\n";
					print "Run this on the nodes:$cmd_string2\n";
				}
				else
				{
					#sanity check...
					system($cmd_string1);
					#need a crm command to clean up on the nodes fs
					system($cmd_string2);
				} 
				return (1);
			}
			elsif($where =~ "server")
			{
				if ($test =~ "1")
				{
					print "server uninstall actions:\n";
					print "run this script:system($script_path)\n";
				}
				else
				{
					system($script_path);
				}
				return (1);
			}
			else
			{
				return (0);
			}
		}
	}
}

1;
