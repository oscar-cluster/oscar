package OSCAR::PackageInUn;
# 
#  $Id: PackageInUn.pm,v 1.3 2003/10/30 03:38:42 tfleury Exp $
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

use strict;

use lib "$ENV{OSCAR_HOME}/lib";
use Carp;
use OSCAR::Package;
use OSCAR::Database;

#this doesn't seem to effect the namespace of the calling script
use vars qw(@EXPORT);
use base qw(Exporter);
our @EXPORT = qw(install_uninstall_packages
                 package_install
                 package_uninstall
                 set_installed
                 set_uninstalled
                 is_selected); 


#Things to do in general:
#1. start using the oscar logger...log errors
#2. figure out an rpm command better than -U, this will not work, -f sucks
#3. look for rpm's on system also (dependancy stuff), /tftpboot/rpm
#4. need to glob all the rpm's on one commandline, not install one at a time
#5. use run_pkg_script in Package.pm where and if possible




#########################################################################
#  Subroutine: install_uninstall_packages                               #
#  Parameters: None                                                     #
#  Returns   : Nothing                                                  #
#  Call this subroutine after you have run the GUI for install/         #
#  uninstall packages (which is basically the 'Selector' run with the   #
#  command line argument of '-installuninstall'.  This subroutine       #
#  gets two lists from oda: (1) packages to be installed (that are      #
#  not currently installed) and (2) packages to be uninstalled (that    #
#  are currently installed).  It loops through the two lists and        #
#  Does The Right Thing(tm) for each package.  At the end of the        #
#  function, all of the flags should be updated appropriately in oda.   #
#########################################################################
sub install_uninstall_packages
{
  my $success;  # Return code for database calls
  my $package;  # Name of a package to be installed/uninstalled
  my @packagesThatShouldBeInstalled;    # List of packages to install
  my @packagesThatShouldBeUninstalled;  # List of packages to uninstall
                                                                                
  # Get the lists of packages that need to be installed/uninstalled
  $success = OSCAR::Database::database_execute_command(
    "packages_that_should_be_installed",\@packagesThatShouldBeInstalled);
  $success = OSCAR::Database::database_execute_command(
    "packages_that_should_be_uninstalled",\@packagesThatShouldBeUninstalled);
                                                                                
  # Loop through the list of packages to be INSTALLED and do the right thing
  foreach $package (@packagesThatShouldBeInstalled)
    {
      # INSERT APPROPRIATE CODE HERE, maybe something like this:
      # $success = install_package($package);
                                                                                
      # If the installation was successful, set the 'installed' flag for
      # that package in the database.  Also, clear the 'should_be_installed'
      # flag for that package.
      if ($success)
        {
          OSCAR::Database::database_execute_command(
            "package_mark_installed $package");
          OSCAR::Database::database_execute_command(
            "package_clear_should_be_installed $package")
        }
    }
                                                                                
  # Loop through the list of packages to be UNINSTALLED and do the right
  # thing
  foreach $package (@packagesThatShouldBeUninstalled)
    {
      # INSERT APPROPRIATE CODE HERE, maybe something like this:
      # $success = uninstall_package($package);
                                                                                
      # If the removal was successful, clear the 'installed' flag for
      # that package in the database.  Also, clear the
      # 'should_be_uninstalled'
      # flag for that package.
      if ($success)
        {
          OSCAR::Database::database_execute_command(
            "package_clear_installed $package");
          OSCAR::Database::database_execute_command(
            "package_clear_should_be_uninstalled $package")
        }
    }
                                                                                
  # OPTIONALLY clear all of the install/uninstall flags at the end
  OSCAR::Database::database_execute_command(
    "packages_clear_all_should_be_installed");
  OSCAR::Database::database_execute_command(
    "packages_clear_all_should_be_uninstalled");
}
                                                                                

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
#   0 success (added to clients, server, or an image)	
#   1 no install target
#   2 attempted install on server, choked
#   3 attempted install on clients, choked
#   4 attempted install on image, choked
#   5 package is installed already, taking no actions
#   6 package is not a package
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

	my $test_value;

	#add check to see if package exists
	if ((is_package_a_package($package_name)) =~ 1)
	{
		print "package does not exist...\n";
		return 6;
	} 

	$test_value = is_installed($package_name);	

	if ($test_value =~ "1")
	{
		print "package is installed already, aborting...\n";
		return (5);
	}

	if (!$headnode && !$allnodes && !$image)
	{
		print "no install target selected...\n";
		return (1);
	}

	if($allnodes)
	{
		if(!run_install_client($package_name, $testmode))
		{
			print "cannot install to the nodes...\n";
			return (3);
		}
	}

	if($headnode)
	{
		if(!run_install_server($package_name, $testmode))
		{
			print "cannot install on the server...\n";
			return (2);
		}
	}

	if($image)
	{
		if(!run_install_image($package_name, $testmode, $image))
		{
			print "cannot install to the image:$image\n";
			return (4);
		}
	}

	if ($testmode != 1)
	{
		set_installed($package_name);
	}

	return (0);
}

#runs install scripts on all nodes (clients)
#installs rpms as needed
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#	if this field is not null, and $where is set to client
#	the image is acted on
#returns: (an integer)
#	2 is did nothing
#	1 is success
#	0 for failure
sub run_install_client
{
	my ($package_name,
		$testmode) = @_;

	my $type = "oscar_clients";

	my $script_path;
	my $rpm;

	my @temp_list;

	my $flag = 2;
	my @rpmlist;
	my $retval;
	
	if($testmode != 0)
	{
		print "client install starts:\n";
	}

	$retval = get_rpm_list($package_name, $type, \@rpmlist);

	if($retval == 0)
	{
		foreach $rpm (@rpmlist)
		{
			@temp_list = split(/\//,$rpm);
			if($testmode != 0)
			{
				print "run this command:system(cpush $rpm /tmp)\n";
				print "run this command:system(cexec rpm -U /tmp/$temp_list[$#temp_list]\n";
				print "run this command:system(cexec rm -f /tmp/$temp_list[$#temp_list])\n";
			}
			else
			{
				#need to add some kind of sanity check here
				#run_pkg_script will not work here
				system("cpush $rpm /tmp");
				system("cexec rpm -U /tmp/$temp_list[$#temp_list]");
				system("cexec rm -f /tmp/$temp_list[$#temp_list]");
			}
		}
		$flag = 1;
	}
	elsif ($retval == 2)
	{
		return (0); #error in rpms
	}
	
	
	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path = "$var/$package_name/scripts/post_client_rpm_install";
		if (-x $script_path)
		{
			if($testmode != 0)
			{
				print "run this command:system(cpush $script_path /tmp)\n";
				print "run this command:system(cexec /tmp/post_client_rpm_install)\n";
				print "run this command:system(cexec rm -f /tmp/post_client_rpm_install\n";
			}
			else
			{
				#add some sanity checking here
				#run_pkg_script will not work here
				system("cpush $script_path /tmp");
				system("cexec /tmp/post_client_rpm_install");
				system("cexec rm -f /tmp/post_client_rpm_install");
			}
			$flag = 1;
		}
		$script_path = "$var/$package_name/scripts/post_client_install";
		if(-x $script_path)
		{
			if($testmode != 0)
			{
				print "run this command:system(cpush $script_path /tmp)\n";
				print "run this command:system(cexec /tmp/post_client_install)\n";
				print "run this command:system(cexec rm -f /tmp/post_client_install\n";
			}
			else
			{
				#run_pkg_script will not work here
				#add some sanity checking here
				system("cpush $script_path /tmp");
				system("cexec /tmp/post_client_install");
				system("cexec rm -f /tmp/post_client_install");
			}
			$flag = 1;
		}
	}
	return $flag;
}

#runs install scripts on an image (a client)
#installs rpms as needed
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
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

	my $cmd_string1;
	my $cmd_string2;
	my $script_path;

	my @rpm_array;
	my $rpm;

	my @temp_list;

	my $flag = 2;
	my @rpmlist;
	my $retval;
	
	if (!(-d "/var/lib/systemimager/images/$imagename"))
	{
		print "image name is invalid\n";
		return (0);
	}

	if($testmode != 0)
	{
		print "image install starts:\n";
	}

	$retval = get_rpm_list($package_name, $type, \@rpmlist);

	if($retval == 0)
	{
		foreach $rpm (@rpmlist)
		{
			@temp_list = split(/\//,$rpm);

			$cmd_string1 = "/bin/cp $rpm /var/lib/systemimager/images/$imagename/tmp";
			$cmd_string2 = "/bin/rpm --root /var/lib/systemimager/images/$imagename -U /tmp/$temp_list[$#temp_list]";

			if ($testmode != 0)
			{
				print "run this command:$cmd_string1\n";
				print "run this command:$cmd_string2\n";
			}
			else
			{
				#need some sanity checking here
				system($cmd_string1);
				system($cmd_string2);
			}
		}
		$flag = 1;
	}
	elsif ($retval == 2)
	{
		return (0); #error in rpms
	}

	#modify this to use run_pkg_script in Package.pm 
	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path = "$var/$package_name/scripts/post_client_rpm_install";
		if (-x $script_path)
		{
			if($testmode != 0)
			{
				print "run this command:system(cp $script_path /var/lib/systemimager/images/$imagename/tmp)\n";
				print "run this command:system(chroot /var/lib/systemimager/images/$imagename /tmp/post_client_rpm_install)\n";
				print "run this command:system(rm -f /var/lib/systemimager/images/$imagename/tmp/post_client_rpm_install)\n";
			}
			else
			{
				#need some sanity checking here
				system("cp $script_path /var/lib/systemimager/images/$imagename/tmp");
				system("chroot /var/lib/systemimager/images/$imagename /tmp/post_client_rpm_install");
				system("rm -f /var/lib/systemimager/images/$imagename/tmp/post_client_rpm_install");
			}
			$flag = 1;
		}

		$script_path = "$var/$package_name/scripts/post_client_install";
		if(-x $script_path)
		{
			if($testmode != 0)
			{
				print "run this command:system(cp $script_path /var/lib/systemimager/images/$imagename/tmp)\n";
				print "run this command:system(chroot /var/lib/systemimager/images/$imagename /tmp/post_client_install)\n";
				print "run this command:system(rm -f /var/lib/systemimager/images/$imagename/tmp/post_client_install)\n";
			}
			else
			{
				system("cp $script_path /var/lib/systemimager/images/$imagename/tmp");
				system("chroot /var/lib/systemimager/images/$imagename /tmp/post_client_install");
				system("rm -f /var/lib/systemimager/images/$imagename/tmp/post_client_install");
			}
		}
	}
	return $flag;
}

#runs install scripts on server
#installs rpms as needed
#	package_name --> name of a package, scalar string
#	testmode --> if set to "1" run in testmode, scalar string
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
	my $script_path3;
	my $flag = 2;

	my @rpmlist;
	my $rpm;
	my $retval;
	
	$retval = get_rpm_list($package_name, "oscar_server", \@rpmlist);

	if($retval == 0)
	{
		if ($testmode != 0)
		{
			print "Do this on the server filesystem:\n";
		}
		foreach $rpm (@rpmlist)
		{ 
			$cmd_string1 = "rpm -U $rpm";
			if($testmode != 0)
			{
				print "run this command:system($cmd_string1)\n";
			}
			else
			{
				system($cmd_string1);
			}
			$flag = 1;
		}
	}
	elsif($retval == 2)
	{
		return (0); #error in rpms
	}


	#modify this to use run_pkg_script in Package.pm 
	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$script_path1 = "$var/$package_name/scripts/post_server_rpm_install";
		if (-x $script_path1)
		{
			if($testmode != 0)
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
			if($testmode!= 0)
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

		$script_path3 = "$var/$package_name/scripts/post_server_install";
		if (-x $script_path3)
		{
			if($testmode!= 0)
			{
				print "run this command:system($script_path3)\n";
			}
			else
			{
				#need some sanity checking here
				system($script_path3);
			}
			$flag = 1;
		}
	}
	return ($flag);
}

#finds the rpms to install
#checks to make sure there are rpms to be installed
#checks to make sure each rpm is on the system
#	$package_name --> a valid package, string
#	$type --> one of 2 strings
#		"oscar_server"
#		"oscar_clients"
#	$rpmlistref --> reference to a list of rpms to be installed
#returns: 0 for success
#		1 for failure (nothing to do)
#		2 for failure, error
#if 0 is returned there will be 
#at least 1 rpm in @rpmlist to be installed
#note: includes the full path to the rpm
sub get_rpm_list
{
	my ($package_name,
		$type,
		$rpmlistref) = @_;

	my $cmd_string;
	my @rpm_list_database;
	my @dirlist;
	my @temp;

	my $rpm;
	my %rpmhash;
	my $rpmstring = "/bin/rpm -q --queryformat=\"%{NAME}\" -p ";
	my $rpmname;
	my $count;
	my $openstring;

	@rpm_list_database = OSCAR::Database::database_rpmlist_for_package_and_group($package_name, $type);

	#make sure there is supposed to be at least 1 rpm
	if (scalar(@rpm_list_database) == 0)
	{
		print "no rpms in database\n";
		return (1);
	}
 
	foreach my $var (@{OSCAR::Package::PKG_SOURCE_LOCATIONS})
	{
		$cmd_string = "$var/$package_name/RPMS/";
		if (-d $cmd_string)
		{
			opendir(DNAME, $cmd_string) or Carp::croak "cannot read directory: $!\n";
			my @temp = readdir(DNAME) or Carp::croak "cannot read directory: $!\n";
			@dirlist = grep( !/^\.{1,2}$/ && /\.rpm$/, @temp);
			closedir(DNAME);
			last;
		}
	}

	#make sure we have at least 1 rpm
	if (scalar(@dirlist) == 0)
	{
		print "no rpms on system\n";
		return (2);
	}

	#stick the rpms from the readdir into an aa
	foreach $rpm (@dirlist)
	{
		$openstring = "$rpmstring $cmd_string$rpm";
		if (-f "$cmd_string$rpm")
		{
			open(RPMCMD, "$openstring |") or Carp::croak "cannot run rpm command:$!\n";
			$rpmname = <RPMCMD>;
			if (length($rpmname) != 0)
			{
				$rpmhash{$rpmname} = "$cmd_string$rpm";
			}
			close(RPMCMD);
		}
	}

	#make sure we have all of them...one real file per
	#rpm from the database
	$count = 0;
	foreach $rpm (@rpm_list_database)
	{
		if (length($rpmhash{$rpm}) > 0 ) #if its not a key, its not on the system
		{
			#since it is a key, put the rpm in the list 
			${$rpmlistref}[$count] = $rpmhash{$rpm};
			$count++; 
		}
		else
		{
			print "Missing this rpm on system:$rpm\n";
		}
	}

	#if the number we found doesn't match the number we need
	if ($count != scalar(@rpm_list_database))
	{
		#number of rpms found do not match number needed (according to the database)
		#in a sane world this should fail, but in oscar we print to the log
		#this cannot be a failure case...see c3 --> /RPMS/rsync case
		print "number of rpms in database do not match number found on filesystem.\n";
		return 2;
	}
	return (0);
}

#uninstalls a package from all clients, the server, optionally an image
#	$package_name --> a valid package name, string
#	$testmode --> 1 or 0, sets testmode, string
#   $image  --> an image name, string
#	$allnodes --> if has a value uninstall on all nodes
#	$headnode --> if has a value, uninstall on headnode
#
#returns:
#   0 success (removed from clients, server, or image)	
#   1 no install target
#   2 attempted install on server, choked
#   3 attempted install on clients, choked
#   4 attempted install on image, choked
#   5 package is installed already, taking no actions
#   6 package is not a package
#
#   Important Note:
#   also sets "installed" field in table packages 
#   to 0 (uninstalled) for the package if
#   the return value is 0
sub package_uninstall
{
	my ($package_name,
		$headnode,
	    $allnodes,
		$image,
		$testmode) = @_;

	my $test_value;
	
	#check added to see if package exists
	if ((is_package_a_package($package_name)) =~ 1)
	{
		print "package does not exist...\n";
		return 6;
	} 

	$test_value = is_installed($package_name);	

	if ($test_value =~ "0")
	{
		print "package is not installed, aborting...\n";
		return (6);
	}

	if (!$headnode && !$allnodes && !$image)
	{
		print "no uninstall target selected\n";
		return (1);
	} 

	if ($headnode)
	{ 
		if (!run_uninstall_script($package_name, $testmode, "server"))
		{
			print "cannot uninstall on server...\n";
			return (2);
		}
	}

	if ($allnodes)
	{
		if (!run_uninstall_script($package_name, $testmode, "client"))
		{
			print "cannot uninstall on clients...\n";
			return (3);
		}
	}

	if($image)
	{
		if(!run_uninstall_script($package_name, $testmode, "client", $image))
		{
			print "cannot uninstall on the image...\n";
			return (4);
		}
	}

	if ($testmode != 1)
	{
		set_uninstalled($package_name);
	}
	return (0);
}

#checks to see if a package exists
#returns 0 if it does 
#1 otherwise
#does set oda's error code to verbose
sub is_package_a_package
{
	my ($package_name) = @_;

	my $cmdstring = "read_records packages name name=\"$package_name\"";
	my @my_result;
	my $error_code = 1;

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);

	if ($my_result[0] =~ $package_name)
	{
		return (0);
	}

	return (1);
}	

#this sets the installed field in table packages to 1
#takes as input a scalar string that is a package name
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
#takes as input a scalar string that is a package name
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
#takes as input a scalar string that is a package name
#returns 1 if the package is installed, 0 otherwise
#does set oda's error code to verbose
#
#note: actually returns the value of the installed field
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
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#	$where --> string which describes one of 2 uninstalls
#		server or client
#	$imagename --> name of an image, scalar string
#	if this field is not null, and $where is set to client
#	the image is acted on
#returns:
#	1 is success
#	0 for failure
sub run_uninstall_script
{
	my ($package_name, $testmode, $where, $imagename) = @_;

	my $script_path = "";
	my $cmd_string1 = "cpush";
	my @temp_list;
	my $cmd_string2 = "cexec";
	my $cmd_string3;

	#modify this to use run_pkg_script in Package.pm 
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
				$cmd_string3 = "rm -f /var/lib/systemimager/images/$imagename/tmp/$temp_list[$#temp_list]";
				

				if ($testmode != 0)
				{
					print "image uninstall actions:\n";
					print "run this command:$cmd_string1\n";
					print "run this command:$cmd_string2\n";
					print "run this command:$cmd_string3\n";
				}
				else
				{
					#sanity check...
					system($cmd_string1);
					system($cmd_string2);
					system($cmd_string3);
				}
				return (1);
			}
			elsif (($where =~ "client") && (!$imagename))
			{
				$cmd_string1 = "$cmd_string1 $script_path /tmp/$temp_list[$#temp_list]";
				$cmd_string2 = "$cmd_string2 /tmp/$temp_list[$#temp_list]";
				$cmd_string3 = "cexec rm -f /tmp/$temp_list[$#temp_list]";
				
				if ($testmode != 0)
				{
					print "client uninstall actions:\n";
					print "Push this to the nodes:$cmd_string1\n";
					print "Run this on the nodes:$cmd_string2\n";
					print "Run this on the nodes:$cmd_string3\n";
				}
				else
				{
					#sanity check...
					system($cmd_string1);
					system($cmd_string2);
					system($cmd_string3);
				} 
				return (1);
			}
			elsif($where =~ "server")
			{
				if ($testmode != 0)
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
