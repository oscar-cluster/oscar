package OSCAR::PackageInUn;
# 
#  $Id: PackageInUn.pm,v 1.4 2003/10/31 00:00:30 muglerj Exp $
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
                                                                                


#Things to do in general:
#1. start using the oscar logger...log errors...check open command results and internal errors
#2. grep cexec rpm-filter result array 
#10. grep out any non pc rpms from any readdir

#installs a package to either
#all clients, the server, an image, or any
#combination of the 3.
#	$package_name --> a valid package name, string
#	$testmode --> 1 or 0, sets testmode, string
#	$image  --> if it has a value installs into the imagea
#	$imagename --> a valid imagename
#		note: image name only, not full path		
#	$allnodes --> if has a value install on all nodes
#	$headnode --> if has a value install on headnode
#	$range --> a range of valid nodes to install to
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
		$imagename,
		$range,
		$testmode) = @_;

	my $test_value;

	set_uninstalled($package_name);

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
		if(!run_install_client($package_name, $testmode, $imagename, $range))
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
		if(!run_install_image($package_name, $testmode, $imagename))
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

#runs install scripts on a range of nodes (clients)
#installs rpms as needed
#but also needs an imagename
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#	$imagename --> an imagename for this client
#	$range --> a range of clients to run this command on
#	if this field is not null, and $where is set to client
#	the image is acted on
#returns: (an integer)
#	2 is did nothing
#	1 is success
#	0 for failure
sub run_install_client
{
	my ($package_name,
		$testmode,
		$imagename,
		$range) = @_;

	my $type = "oscar_clients";

	my $script_path;
	my $cmd_string1;
	my $cmd_string2;
	my $cmd_string3;
	my $cmd_string4;
	my $cmd_string5;

	my $rpm;

	my @temp_list;

	my $flag = 2;
	my @rpmlist;
	my @newrpmlist;
	my $all_rpms_full_path;
	my $all_rpms;

	my $retval;

	my $imagepath;
	my $command_out;
	
	if($testmode != 0)
	{
		print "client install starts:\n";
	}

	my $imagepath = "/var/lib/systemimager/images/$imagename";

	if (!(-d $imagepath))
	{
		print "image name is invalid\n";
		return (0);
	}

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if($package_dir eq undef)
	{
		print "can't find the package\n";
		return (0);
	}

	$retval = get_rpm_list($package_name, $type, \@rpmlist);
	if($retval == 0)
	{
		if((check_rpm_list("image", \@rpmlist, \@newrpmlist, "/var/lib/systemimager/images/$imagename")) != 0)
		{
			print "check_rpm_list() failed\n";
			return (0);
		}

		if (scalar(@rpmlist) > 0)
		{
			$cmd_string1 = "cexec mkdir -p /tmp/tmpinstallrpm/";
			foreach $rpm (@rpmlist)
			{
				@temp_list = split(/\//,$rpm);
				$all_rpms = "$all_rpms /tmp/tmpinstallrpm/$temp_list[$#temp_list]";
			}
			$cmd_string3 = "cexec rpm-filter $package_name rpm -U $all_rpms";
			$cmd_string4 = "cexec rm -rf /tmp/tmpinstallrpm/";

			if($testmode != 0)
			{
				print "PackageInUn.run_install_client: $cmd_string1\n";
				foreach $rpm (@rpmlist)
				{
					$cmd_string2 = "cpush $rpm /tmp/tmpinstallrpm/";
					print "PackageInUn.run_install_client: $cmd_string2\n";
				}
				print "PackageInUn.run_install_client: $cmd_string3\n";
				print "PackageInUn.run_install_client: $cmd_string4\n";
			}
			else
			{
				open(NEWCMD, "$cmd_string1 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				foreach $rpm (@rpmlist)
				{
					$cmd_string2 = "cpush $rpm /tmp/tmpinstallrpm/";
					open(NEWCMD, "$cmd_string2 |") or Carp::croak "cannot run command:$!\n";
					#add logging or sanity check
					$command_out = <RPMCMD>;
					close(NEWCMD);
				}

				open(NEWCMD, "$cmd_string3 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string4 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);
			}
			
		}
		$flag = 1;
	}
	elsif ($retval == 2)
	{
		return (0); #error in rpms
	}
	
	$script_path = "$package_dir/scripts/post_client_rpm_install";
	if (-x $script_path)
	{
		$cmd_string1 = "cpush $script_path /tmp";
		$cmd_string2 = "cexec /tmp/post_client_rpm_install";
		$cmd_string3 = "cexec rm -f /tmp/post_client_rpm_install";
		if($testmode != 0)
		{
			print "PackageInUn.run_install_client: $cmd_string1\n";
			print "PackageInUn.run_install_client: $cmd_string2\n";
			print "PackageInUn.run_install_client: $cmd_string3\n";
		}
		else
		{
				open(NEWCMD, "$cmd_string1 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string2 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string3 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);
		}
		$flag = 1;
	}

	$script_path = "$package_dir/scripts/post_client_install";
	if(-x $script_path)
	{
		$cmd_string1 = "cpush $script_path /tmp";
		$cmd_string2 = "cexec /tmp/post_client_install";
		$cmd_string3 = "cexec rm -f /tmp/post_client_install";
		if($testmode != 0)
		{
			print "PackageInUn.run_install_client: $cmd_string1\n";
			print "PackageInUn.run_install_client: $cmd_string2\n";
			print "PackageInUn.run_install_client: $cmd_string3\n";
		}
		else
		{
			open(NEWCMD, "$cmd_string1 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);

			open(NEWCMD, "$cmd_string2 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);

			open(NEWCMD, "$cmd_string3 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);
		}
		$flag = 1;
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

	my $script_path;
	my $cmd_string1;
	my $cmd_string2;
	my $cmd_string3;
	my $cmd_string4;
	my $cmd_string5;

	my $all_rpms;
	my $all_rpms_full_path;
	my $rpm;
	my @temp_list;

	my $flag = 2;
	my @rpmlist;
	my @newrpmlist;
	my $retval;
	my $command_out;
	
	#hope those images are all in the same place
	if (!(-d "/var/lib/systemimager/images/$imagename"))
	{
		print "image name is invalid\n";
		return (0);
	}

	if($testmode != 0)
	{
		print "image install starts:\n";
	}

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if($package_dir eq undef)
	{
		print "can't find the package\n";
		return (0);
	}
	
	$retval = get_rpm_list($package_name, $type, \@rpmlist);
	if($retval == 0)
	{
		if((check_rpm_list("image", \@rpmlist, \@newrpmlist, "/var/lib/systemimager/images/$imagename")) != 0)
		{
			print "check_rpm_list failed\n";
			return (0);
		}

		if (scalar(@rpmlist) > 0)
		{

			foreach $rpm (@rpmlist)
			{
				@temp_list = split(/\//,$rpm);
				$all_rpms_full_path = "$all_rpms_full_path $rpm";
				$all_rpms = "$all_rpms /tmp/tmpinstallrpm/$temp_list[$#temp_list]";
			}

			$cmd_string1 = "/bin/mkdir -p /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/";
			$cmd_string2 = "/bin/cp $all_rpms_full_path /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/";
			$cmd_string3 = "/bin/rpm --root /var/lib/systemimager/images/$imagename -U $all_rpms";
			$cmd_string4 = "/bin/rm -rf /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/*";
			$cmd_string5 = "/bin/rmdir /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/";

			if ($testmode != 0)
			{
				print "PackageInUn.run_install_image: $cmd_string1\n";
				print "PackageInUn.run_install_image: $cmd_string2\n";
				print "PackageInUn.run_install_image: $cmd_string3\n";
				print "PackageInUn.run_install_image: $cmd_string4\n";
				print "PackageInUn.run_install_image: $cmd_string5\n";
				exit (0);
			}
			else
			{
				open(NEWCMD, "$cmd_string1 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string2 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string3 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string4 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);

				open(NEWCMD, "$cmd_string5 |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);
			}

			$flag = 1;
		}
	}
	elsif ($retval == 2)
	{
		print "error finding rpms to install\n";
		return (0); 
	}

	$script_path = "$package_dir/scripts/post_client_rpm_install";
	$cmd_string1 = "/bin/cp $script_path /var/lib/systemimager/images/$imagename/tmp";
	$cmd_string2 = "/usr/sbin/chroot /var/lib/systemimager/images/$imagename /tmp/post_client_rpm_install";
	$cmd_string3 = "/bin/rm -f /var/lib/systemimager/images/$imagename/tmp/post_client_rpm_install";

	if (-x $script_path)
	{
		if($testmode != 0)
		{
			print "PackageInUn.run_install_image: $cmd_string1\n";
			print "PackageInUn.run_install_image: $cmd_string2\n";
			print "PackageInUn.run_install_image: $cmd_string3\n";
		}
		else
		{
			open(NEWCMD, "$cmd_string1 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);

			open(NEWCMD, "$cmd_string2 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);

			open(NEWCMD, "$cmd_string3 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);
		}
		$flag = 1;
	}

	$script_path = "$package_dir/scripts/post_client_install";
	$cmd_string1 = "/bin/cp $script_path /var/lib/systemimager/images/$imagename/tmp";
	$cmd_string2 = "/usr/sbin/chroot /var/lib/systemimager/images/$imagename /tmp/post_client_install";
	$cmd_string3 = "/bin/rm -f /var/lib/systemimager/images/$imagename/tmp/post_client_install";

	if(-x $script_path)
	{
		if($testmode != 0)
		{
			print "PackageInUn.run_install_image: $cmd_string1\n";
			print "PackageInUn.run_install_image: $cmd_string2\n";
			print "PackageInUn.run_install_image: $cmd_string3\n";
		}
		else
		{
			open(NEWCMD, "$cmd_string1 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);

			open(NEWCMD, "$cmd_string2 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);

			open(NEWCMD, "$cmd_string3 |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);
		}
		$flag = 1;
	}
	return ($flag);
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
	my $cmd_string;
	my $script_path;
	my $flag = 2;

	my @rpmlist;
	my @newrpmlist;
	my $rpm;
	my $retval;

	my $command_out;

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if($package_dir eq undef)
	{
		print "can't find the package\n";
		return (0);
	}

	if ($testmode != 0)
	{
		print "server install starts:\n";
	}
	
	$retval = get_rpm_list($package_name, "oscar_server", \@rpmlist);
	if($retval == 0)
	{
		if((check_rpm_list("server", \@rpmlist, \@newrpmlist)) != 0)
		{
			print "check_rpm_list failed\n";
			return (0);
		}

		if (scalar(@rpmlist) != 0)
		{
			$cmd_string = "rpm -U";
			foreach $rpm (@rpmlist)
			{ 
				$cmd_string = "$cmd_string $rpm";
			}

			if($testmode != 0)
			{
				print "PackageInUn.run_install_server: $cmd_string\n";
			}
			else
			{	
				open(NEWCMD, "$cmd_string |") or Carp::croak "cannot run command:$!\n";
				#add logging or sanity check
				$command_out = <RPMCMD>;
				close(NEWCMD);
			}
			$flag = 1;
		}
	}
	elsif($retval == 2)
	{
		return (0); #error in rpms
	}
	
	$script_path = "$package_dir/scripts/post_server_rpm_install";
	if (-x $script_path)
	{
		if($testmode != 0)
		{
			print "PackageInUn.run_install_server: $script_path\n";
		}
		else
		{
			open(NEWCMD, "$script_path |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);
		}
		$flag = 1;
	}

	$script_path = "$package_dir/scripts/post_clients";
	if (-x $script_path)
	{
		if($testmode!= 0)
		{
			print "PackageInUn.run_install_server: $script_path\n";
		}
		else
		{
			open(NEWCMD, "$script_path |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);
		}
		$flag = 1;
	}

	$script_path = "$package_dir/scripts/post_server_install";
	if (-x $script_path)
	{
		if($testmode!= 0)
		{
			print "PackageInUn.run_install_server: $script_path\n";
		}
		else
		{
			open(NEWCMD, "$script_path |") or Carp::croak "cannot run command:$!\n";
			#add logging or sanity check
			$command_out = <RPMCMD>;
			close(NEWCMD);
		}
		$flag = 1;
	}
	return ($flag);
}

#checks to see if rpms are already installed
#either on the clients, an image, or on the server
#	$location --> can be one of 3 strings
#		"server"
#		"client"
#		"image"
#	$old_rpmlistref_old --> reference to a list of fully 
#							qualified rpms that need installation
#	$new_rpmlistref --> reference to a list of fully qualified 
#						rpms that are not installed yet and need
#						installation
#	$image --> a complete path to image root, if defined, string
#	 
#returns 0 if it successfully modifies the
#$rpmlistref or does nothing
#returns 1 on error
sub check_rpm_list
{
	my ($location,
		$old_rpmlistref,
		$new_rpmlistref,
		$image) = @_;

	my $rpmcmd;
	my $rpm;

	my $openstring;
	my $rpmstring = "/bin/rpm -q --nosignature --queryformat=\"%{NAME}\" -p ";
	my $rpmname;
	my %rpmhash;

	my $key;
	my $count;

	my $flag = 1;

	#build an aa out of the current rpmlist
	foreach $rpm (@{$old_rpmlistref})
	{
		$openstring = "$rpmstring $rpm";
		if (-f "$rpm")
		{
			open(RPMCMD, "$openstring |") or Carp::croak "cannot run rpm command:$!\n";
			$rpmname = <RPMCMD>;
			if (length($rpmname) != 0)
			{
				$rpmhash{$rpmname} = $rpm;
			}
			close(RPMCMD);
		}
	}

	if($location =~ "server")
	{
		$rpmcmd = "rpm -q  ";
		$flag = 0;
	}
	elsif(($location =~ "client") or ($location =~ "image"))
	{
		$rpmcmd = "rpm -q --root $image ";
		$flag = 0;
	}
	else
	{
		return ($flag);
	}

	$rpmname = "";
	$count = 0;

	#for every rpmname, rpm -q it
	foreach $key (keys %rpmhash)
	{
		$openstring = "$rpmcmd$key";
		open(RPMCMD, "$openstring |") or Carp::croak "cannot run rpm command:$!\n";
		$rpmname = <RPMCMD>;
		close(RPMCMD);

		#if it is on the system
		#the key will match the rpmname at pos 0
		#so if no 0, include the rpm in the new_rpmlistref
		#print "rpmname is:$rpmname.....key is:$key\n";
		if (index($rpmname, $key) != 0)
		{
			${$new_rpmlistref}[$count] = $rpmhash{$key};
		}
		$count++;
	}
		
	return ($flag);

}

#finds the rpms to install
#checks to make sure there are rpms to be installed
#checks to make sure each rpm is on the system
#even looks in /tftpboot/rpm for the rpm...no extra charge
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
	my $rawrpm;
	my %rpmhash;
	my $rpmstring = "/bin/rpm -q --nosignature --queryformat=\"%{NAME}\" -p ";
	my $rpmname;
	my $count;
	my $openstring;

	my @temp;

	my @tftprpmlist;

	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);
	@rpm_list_database = OSCAR::Database::database_rpmlist_for_package_and_group($package_name, $type);

	#make sure there is supposed to be at least 1 rpm
	if (scalar(@rpm_list_database) == 0)
	{
		print "no rpms in database\n";
		return (1);
	}
 
	$cmd_string = "$package_dir/RPMS/";
	if (-d $cmd_string)
	{
		opendir(DNAME, $cmd_string) or Carp::croak "cannot read directory: $!\n";
		@temp = readdir(DNAME) or Carp::croak "cannot read directory: $!\n";
		#add strip out all .ia64.rpm or non-good rpms
		@dirlist = grep( !/^\.{1,2}$/ && /\.rpm$/ && !/ia64\.rpm$/, @temp);
		closedir(DNAME);
	}

	#stick the rpms from the readdir in package/RPMS into an aa
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

	#Stick the rpms from /tftpboot/rpm into a list in case we need them later
	opendir(DNAME, "/tftpboot/rpm") or Carp::croak "cannot read directory: $!\n";
	@temp = readdir(DNAME) or Carp::croak "cannot read directory: $!\n";
	@tftprpmlist = grep( !/^\.{1,2}$/ && /\.rpm$/ && !/ia64\.rpm$/, @temp);
	closedir(DNAME);


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
			#AH-HA...time to look at /tftpboot/rpm for the missing rpm
			#put all possible matches in the aa
			foreach $rawrpm (@tftprpmlist)
			{
				if(index($rawrpm, $rpm) == 0)
				{
					#found the name...read it in with its full path
					$openstring = "$rpmstring /tftpboot/rpm/$rawrpm";
					open(RPMCMD, "$openstring |") or Carp::croak "cannot run rpm command:$!\n";
					$rpmname = <RPMCMD>;
					if (length($rpmname) != 0)
					{
						$rpmhash{$rpm} = "/tftpboot/rpm/$rawrpm";
					}
					close(RPMCMD);
				}
			}
			#now see if it matches again...this is getting ugly
			if(length($rpmhash{$rpm}) > 0)
			{
				${$rpmlistref}[$count] = $rpmhash{$rpm};
				$count++; 
			}
			else
			{
				#no match even in /tftpboot/rpm...punt
				print "No rpm found for:$rpm\n";
			}
		}
	}

	#if the number we found doesn't match the number we need
	if ($count != scalar(@rpm_list_database))
	{
		#in a sane world this should fail...
		#and now it does, because we are looking in /tftpboot/rpms also...whew...
		print "number of rpms in database do not match number found on filesystem.\n";
		return 2;
	}
	return (0);
}

#uninstalls a package from all clients, the server, optionally an image
#	$package_name --> a valid package name, string
#	$testmode --> 1 or 0, sets testmode, string
#	$image  --> if it has a value installs into the imagea
#	$imagename --> a valid imagename
#		note: image name only, not full path		
#	$allnodes --> if has a value install on all nodes
#	$headnode --> if has a value install on headnode
#	$range --> a range of valid nodes to install to
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
		$imagename,
		$range,
		$testmode) = @_;

	my $test_value;
	
	set_installed($package_name);
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

	if ($allnodes)
	{
		if (!run_uninstall_script($package_name, $testmode, "image", $imagename))
		{
			print "cannot uninstall on clients...\n";
			return (3);
		}
	}

	if ($headnode)
	{ 
		if (!run_uninstall_script($package_name, $testmode, "server"))
		{
			print "cannot uninstall on server...\n";
			return (2);
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
#	$imagename --> name of an image, scalar string
#returns:
#	1 is success
#	0 for failure

#
#sub run_uninstall_image
#{
#	my ($package_name, $testmode, $imagename) = @_;
#
#	my $script_path = "";
#	my $cmd_string1 = "cpush";
#	my @temp_list;
#	my $cmd_string2 = "cexec";
#	my $cmd_string3;
#
#	#get the package dir sanely
#	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);
#
#	$script_path = "$package_dir/scripts/post_client_rpm_uninstall";
#	if (-x $script_path)
#	{
#		@temp_list = split(/\//,$script_path);
#		if ($where =~ "image")
#		{
#			if (!(-d "/var/lib/systemimager/images/$imagename"))
#			{
#				return (0);
#			}
#
#			$cmd_string1 = "cp $script_path /var/lib/systemimager/images/$imagename/tmp";
#			$cmd_string2 = "chroot /var/lib/systemimager/images/$imagename /tmp/$temp_list[$#temp_list]";
#			$cmd_string3 = "rm -f /var/lib/systemimager/images/$imagename/tmp/$temp_list[$#temp_list]";
#
#			if ($testmode != 0)
#			{
#				print "image uninstall actions:\n";
#				print "PackageInUn.run_uninstall_image: $script_path\n";
#				print "run this command:$cmd_string1\n";
#				print "run this command:$cmd_string2\n";
#				print "run this command:$cmd_string3\n";
#			}
#			else
#			{
#				#sanity check...
#				system($cmd_string1);
#				system($cmd_string2);
#				system($cmd_string3);
#			}
#			return (1);
#		}
#	}
#}
#
#
#			elsif (($where =~ "client") && (!$imagename))
#			{
#				$cmd_string1 = "$cmd_string1 $script_path /tmp/$temp_list[$#temp_list]";
#				$cmd_string2 = "$cmd_string2 /tmp/$temp_list[$#temp_list]";
#				$cmd_string3 = "cexec rm -f /tmp/$temp_list[$#temp_list]";
#				
#				if ($testmode != 0)
#				{
#					print "client uninstall actions:\n";
#					print "Push this to the nodes:$cmd_string1\n";
#					print "Run this on the nodes:$cmd_string2\n";
#					print "Run this on the nodes:$cmd_string3\n";
#				}
#				else
#				{
#					#sanity check...
#					system($cmd_string1);
#					system($cmd_string2);
#					system($cmd_string3);
#				} 
#				return (1);
#			}
#			elsif($where =~ "server")
#			{
#				if ($testmode != 0)
#				{
#					print "server uninstall actions:\n";
#					print "run this script:system($script_path)\n";
#				}
#				else
#				{
#					system($script_path);
#				}
#				return (1);
#			}
#			else
#			{
#				return (0);
#			}
#		}
#	}
#}
#
1;
