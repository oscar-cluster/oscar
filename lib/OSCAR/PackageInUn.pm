package OSCAR::PackageInUn;
# 
#  $Id: PackageInUn.pm,v 1.12 2003/11/03 20:53:17 muglerj Exp $
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

#Things to do in general:
#1. get rid of the todo list
#2. more testing

use strict;

use lib "$ENV{OSCAR_HOME}/lib";
use Carp;
use OSCAR::Package;
use OSCAR::Database;
use OSCAR::Logger;
use English;

#this doesn't seem to effect the namespace of the calling script
use vars qw(@EXPORT);
use base qw(Exporter);
our @EXPORT = qw(install_uninstall_packages
                 package_install
                 package_uninstall
                 set_installed
                 set_uninstalled
                 is_selected
                 is_package_a_package
                 check_package_dependancy
                 check_dependant_package); 

my $C3_HOME = '/opt/c3-4'; #evil hack to fix pathing to c3

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
	my $imagenumber; # number of images on the system
	my %imagehash; #hash of imagename node range pairs
	my @imagename; #a list of all the images, allthough we fail unless we have only one
	my $success;  # Return code for database calls
	my $package;  # Name of a package to be installed/uninstalled
	my @packagesThatShouldBeInstalled;    # List of packages to install
	my @packagesThatShouldBeUninstalled;  # List of packages to uninstall
                                                                                
	# Get the lists of packages that need to be installed/uninstalled
	$success = OSCAR::Database::database_execute_command(
		"packages_that_should_be_installed",\@packagesThatShouldBeInstalled);
	$success = OSCAR::Database::database_execute_command(
		"packages_that_should_be_uninstalled",\@packagesThatShouldBeUninstalled);

	$imagenumber = get_image_info(\%imagehash);

	#we only support one image in this version
	if ($imagenumber != 1)
	{
		print "This program only supports one image\n";
		exit (0);
	}

	@imagename = keys(%imagehash);
	croak "Error: no imagename\n" if( !defined($imagename[0]) );

	# Loop through the list of packages to be INSTALLED and do the right thing
	foreach $package (@packagesThatShouldBeInstalled)
	{
		$success = package_install($package, "1", "1", "1", $imagename[0], "blah", "0");
		# If the installation was successful, set the 'installed' flag for
		# that package in the database.  Also, clear the 'should_be_installed'
		# flag for that package.
		if (!$success)
		{
			#bit is already set by underlying code
			#OSCAR::Database::database_execute_command(
			#  "package_mark_installed $package");
			OSCAR::Database::database_execute_command(
				"package_clear_should_be_installed $package")
		}
		else
		{
			print "Error: package $package failed to install.\n";
		}
	}
                                                                                
	#Loop through the list of packages to be UNINSTALLED and do the right
	# thing
	foreach $package (@packagesThatShouldBeUninstalled)
	{
		$success = package_uninstall($package, "1", "1", "1", $imagename[0], "blah", "0");
                                                                                
		# If the removal was successful, clear the 'installed' flag for
		# that package in the database.  Also, clear the
		# 'should_be_uninstalled'
		# flag for that package.
		if (!$success)
		{
			#already done by underlying functions
			#OSCAR::Database::database_execute_command(
			# "package_clear_installed $package");
			OSCAR::Database::database_execute_command(
				"package_clear_should_be_uninstalled $package")
		}
		else
		{
			print "Error: package $package failed to uninstall.\n";
		}
	}
                                                                                
	# we'll give a shot at avoiding this for now
	# OPTIONALLY clear all of the install/uninstall flags at the end
	#OSCAR::Database::database_execute_command(
	#  "packages_clear_all_should_be_installed");
	#OSCAR::Database::database_execute_command(
	#"packages_clear_all_should_be_uninstalled");
}

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
#   7 package is dependant on another package
#
#   Important Note:
#   also sets "installed" field in table packages 
#   to 1 (installed) for the package if
#   the return value is 0 (ONLY in this case)
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

	oscar_log_section("Running OSCAR package install");

	#add check to see if package exists
	if ((is_package_a_package($package_name)) =~ 1)
	{
		print "Error: package ($package_name) does not exist...\n";
		return 6;
	} 

	$test_value = is_installed($package_name);	

	if ($test_value =~ "1")
	{
		print "Error: package ($package_name) is installed already, aborting...\n";
		return (5);
	}

	#check to see if package is dependant on anything
	if( check_package_dependancy($package_name))
	{
		print "Error: package has dependancies\n";
		return (7);
	} 

	if (!$headnode && !$allnodes && !$image)
	{
		print "Error: no install target selected.\n";
		return (1);
	}

	if($allnodes)
	{
		if(!run_install_client($package_name, $testmode, $imagename, $range))
		{
			print "Error: cannot install to the nodes.\n";
			return (3);
		}
	}

	if($headnode)
	{
		if(!run_install_server($package_name, $testmode))
		{
			print "Error: cannot install on the server.\n";
			return (2);
		}
	}

	if($image)
	{
		if(!run_install_image($package_name, $testmode, $imagename))
		{
			print "Error: cannot install to the image:$image\n";
			return (4);
		}
	}

	if ($testmode != 1)
	{
		set_installed($package_name);
	}

	oscar_log_section("Finished running OSCAR package install");

	return (0);
}

#runs install scripts on a range of nodes (clients)
#currently does all nodes...range not yet used
#installs rpms as needed
#but also needs an imagename
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#	$imagename --> an imagename for these clients
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

	oscar_log_subsection("Running install on clients");

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
	my @rslts;

	my $imagepath = "/var/lib/systemimager/images/$imagename";

	if (!(-d $imagepath))
	{
		print "Error: image name is invalid\n";
		return (0);
	}

	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if( !defined($package_dir) )
	{
		print "Error: can't find the package\n";
		return (0);
	}

	$retval = get_rpm_list($package_name, $type, \@rpmlist);
	if($retval == 0)
	{
		if((check_rpm_list("image", \@rpmlist, \@newrpmlist, "/var/lib/systemimager/images/$imagename")) != 0)
		{
			print "Error: check_rpm_list() failed\n";
			return (0);
		}

		if (scalar(@newrpmlist) > 0)
		{
			$cmd_string1 = "$C3_HOME/cexec --pipe c3cmd-filter mkdir -p /tmp/tmpinstallrpm/";
			$all_rpms = "";
			foreach $rpm (@newrpmlist)
			{
				@temp_list = split(/\//,$rpm);
				#$all_rpms = "$all_rpms /tmp/tmpinstallrpm/$temp_list[$#temp_list]";
				my $rpm_name = $temp_list[$#temp_list];
				$all_rpms = "$all_rpms /tmp/tmpinstallrpm/$rpm_name";
			}
			$cmd_string3 = "$C3_HOME/cexec --pipe c3cmd-filter rpm -Uvh $all_rpms";
			$cmd_string4 = "$C3_HOME/cexec --pipe c3cmd-filter rm -rf /tmp/tmpinstallrpm/";

			if($testmode != 0)
			{
				print "executing: $cmd_string1\n";
				foreach $rpm (@newrpmlist)
				{
					$cmd_string2 = "$C3_HOME/cpush $rpm /tmp/tmpinstallrpm/";
					print "executing: $cmd_string2\n";
				}
				print "executing: $cmd_string3\n";
				print "executing: $cmd_string4\n";
			}
			else
			{
				$retval = cexec_open($cmd_string1, \@rslts); 
				print @rslts if($retval != 0);

				foreach $rpm (@newrpmlist)
				{
					$cmd_string2 = "$C3_HOME/cpush $rpm /tmp/tmpinstallrpm/";
					if ( run_command_general($cmd_string2) )
					{
						return 0;
					}

				}
				$retval = cexec_open($cmd_string3, \@rslts); 
				print @rslts if($retval != 0);
				$retval = cexec_open($cmd_string4, \@rslts); 
				print @rslts if($retval != 0);
			}
		}
		$flag = 1;
	}
	elsif ($retval == 2)
	{
		return (0); #error in rpms
	}

	##end rpms
	print "finished with rpms\n";
	
	$script_path = "$package_dir/scripts/post_client_rpm_install";
	if (-x $script_path)
	{
		$cmd_string1 = "$C3_HOME/cpush $script_path /tmp";
		$cmd_string2 = "$C3_HOME/cexec --pipe c3cmd-filter /tmp/post_client_rpm_install";
		$cmd_string3 = "$C3_HOME/cexec --pipe c3cmd-filter rm -f /tmp/post_client_rpm_install";
		if($testmode != 0)
		{
			print "executing: $cmd_string1\n";
			print "executing: $cmd_string2\n";
			print "executing: $cmd_string3\n";
		}
		else
		{
			if ( run_command_general($cmd_string1) )
			{
				return 0;
			}
			$retval = cexec_open($cmd_string2, \@rslts); 
			print @rslts if($retval != 0);
			$retval = cexec_open($cmd_string3, \@rslts); 
			print @rslts if($retval != 0);

		}
		$flag = 1;
	}

	$script_path = "$package_dir/scripts/post_client_install";
	if(-x $script_path)
	{
		$cmd_string1 = "$C3_HOME/cpush $script_path /tmp";
		$cmd_string2 = "$C3_HOME/cexec --pipe c3cmd-filter /tmp/post_client_install";
		$cmd_string3 = "$C3_HOME/cexec --pipe c3cmd-filter rm -f /tmp/post_client_install";
		if($testmode != 0)
		{
			print "executing: $cmd_string1\n";
			print "executing: $cmd_string2\n";
			print "executing: $cmd_string3\n";
		}
		else
		{
			if ( run_command_general($cmd_string1) )
			{
				return 0;
			}
			$retval = cexec_open($cmd_string2, \@rslts); 
			print @rslts if($retval != 0);
			$retval = cexec_open($cmd_string3, \@rslts); 
			print @rslts if($retval != 0);
		}
		$flag = 1;
	}

	oscar_log_subsection("Completed install on clients");

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

	oscar_log_subsection("Starting run_install_image.");	

	#hope those images are all in the same place
	if (!(-d "/var/lib/systemimager/images/$imagename"))
	{
		print "Error: image name ($imagename) is invalid\n";
		return (0);
	}

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if( !defined($package_dir) )
	{
		print "Error: can't find the package\n";
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

		if (scalar(@newrpmlist) > 0)
		{

			$all_rpms_full_path = "";
			foreach $rpm (@newrpmlist)
			{
				@temp_list = split(/\//,$rpm);
				$all_rpms_full_path = "$all_rpms_full_path $rpm";
				$all_rpms = "$all_rpms /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/$temp_list[$#temp_list]";
			}

			$cmd_string1 = "/bin/mkdir -p /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/";
			$cmd_string2 = "/bin/cp $all_rpms_full_path /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/";
			$cmd_string3 = "/bin/rpm -Uvh --root /var/lib/systemimager/images/$imagename  $all_rpms";
			$cmd_string4 = "/bin/rm -rf /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/*";
			$cmd_string5 = "/bin/rmdir /var/lib/systemimager/images/$imagename/tmp/tmpinstallrpm/";

			if ($testmode != 0)
			{
				print "executing: $cmd_string1\n";
				print "executing: $cmd_string2\n";
				print "executing: $cmd_string3\n";
				print "executing: $cmd_string4\n";
				print "executing: $cmd_string5\n";
			}
			else
			{
				if ( run_command_general($cmd_string1) )
				{
					return 0;
				}
				if ( run_command_general($cmd_string2) )
				{
					return 0;
				}
				if ( run_command_general($cmd_string3) )
				{
					return 0;
				}
				if ( run_command_general($cmd_string4) )
				{
					return 0;
				}
				if ( run_command_general($cmd_string5) )
				{
					return 0;
				}
			}

			$flag = 1;
		}
	}
	elsif ($retval == 2)
	{
		print "Error: finding rpms to install\n";
		return (0); 
	}

	#end rpms
	print "finished with rpms\n";

	if($testmode != 1)
	{
		if( OSCAR::Package::run_pkg_script_chroot($package_name, "/var/lib/systemimager/images/$imagename") )
		{
			#returns 1 it worked, sorta
			print "executed phase post_rpm_install on the image.\n";
			$flag = 1;
		}
		else
		{
			print "No image script ran in post_rpm_install phase.\n";
		}
	}
	else
	{
		print "run_pkg_script_chroot($package_name, /var/lib/systemimager/images/$imagename)\n";
	}

	oscar_log_subsection("Completed run_install_image."); 
	return ($flag);
}

#runs install scripts on server
#installs rpms as needed
#	package_name --> name of a package, scalar string
#	testmode --> if set to "1" run in testmode
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

	oscar_log_subsection("Starting run_install_server");

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if( !defined($package_dir) )
	{
		print "Error: can't find the package\n";
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

		if (scalar(@newrpmlist) != 0)
		{
			$cmd_string = "rpm -Uvh";
			foreach $rpm (@newrpmlist)
			{ 
				$cmd_string = "$cmd_string $rpm";
			}

			if($testmode != 0)
			{
				print "PackageInUn.run_install_server: $cmd_string\n";
			}
			else
			{	
				if ( run_command_general($cmd_string) )
				{
					return 0;
				}
			}
			$flag = 1;
		}
	}
	elsif($retval == 2)
	{
		return (0); #error in rpms
	}
	else
	{
		print "No RPMS to install on server for ($package_name)\n";
	}
	
	#end rpms section
	print "finished with rpms\n";

	if($testmode != 1)
	{
		if (OSCAR::Package::run_pkg_script($package_name, 'post_server_install', 1, '0'))
		{
			print "executing post_server_install phase on server\n";
			#ran something
			$flag = 1;
		}
		else
		{
			print "No server script ran in post_server_install\n";
		}
		
		if (OSCAR::Package::run_pkg_script($package_name, 'post_clients', 1, '0'))
		{
			print "executing post_clients phase on server\n";
			$flag = 1;
		}
		else
		{
			print "No server script ran in post_clients phase.\n";
		}
	}
	else
	{
		print "run_pkg_script($package_name, 'post_server_install', '0', '0')\n";
		print "run_pkg_script($package_name, 'post_clients', '0', '0')\n";
	}

	oscar_log_subsection("Completed run_install_server");
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
			#this is only supposed to be a string return...add a check to see
			#if it is more
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
		if (index($rpmname, $key) != 0)
		{
			${$new_rpmlistref}[$count] = $rpmhash{$key};
			$count++;
		}
	}

	print "RPMS that will be installed:\n";
	foreach my $val ( @{$new_rpmlistref} ) {
		print " - $val\n";
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

	my @tftprpmlist;

	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);
	@rpm_list_database = OSCAR::Database::database_rpmlist_for_package_and_group($package_name, $type);

	print "RPMS for Package ($package_name)\n"; 
	foreach my $pkgrpm (@rpm_list_database) { print "  - $pkgrpm\n"; }

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
		#we are hardcoded for x86 basically
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
			close(RPMCMD);
			chomp($rpmname);
			if (length($rpmname) != 0)
			{
				$rpmhash{$rpmname} = "$cmd_string$rpm";
			}
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

		if( exists( $rpmhash{$rpm} ) ) #if its not a key, its not on the system
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
					chomp($rpmname);
					if (length($rpmname) != 0)
					{
						$rpmhash{$rpm} = "/tftpboot/rpm/$rawrpm";
					}
					close(RPMCMD);
				}
			}
			#now see if it matches again if you found any
			if( exists( $rpmhash{$rpm} ) )
			{
				${$rpmlistref}[$count] = $rpmhash{$rpm};
				$count++; 
			}
			else
			{
				#no match even in /tftpboot/rpm...punt
				print "Error: No rpm found for:$rpm\n";
			}
		}
	}

	#if the number we found doesn't match the number we need
	if ($count != scalar(@rpm_list_database))
	{
		#in a sane world this should fail...
		#and now it does, because we are looking in /tftpboot/rpms also...whew...
		print "Error: number of rpms in database do not match number found on filesystem.\n";
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
#   1 no uninstall target
#   2 attempted uninstall on server, choked
#   3 attempted uninstall on clients, choked
#   4 attempted uninstall on image, choked
#   5 package is uninstalled already, taking no actions
#   6 package is not a package
#   7 other packages depend on this package
#
#   Important Note:
#   also sets "installed" field in table packages 
#   to 0 (uninstalled) for the package if
#   the return value is 0
#	this implies that no uninstall script found
#	means failure...is this badness?
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
	
	oscar_log_section("Running OSCAR package un-install");

	if ((is_package_a_package($package_name)) =~ 1)
	{
		print "Error: package ($package_name) does not exist...\n";
		return 6;
	} 

	$test_value = is_installed($package_name);	

	if ($test_value =~ "0")
	{
		print "Error: package ($package_name) is not installed, aborting...\n";
		return (6);
	}

	if (!$headnode && !$allnodes && !$image)
	{
		print "Error: no uninstall target selected\n";
		return (1);
	} 
	#check to see if other packages need it
	if( check_dependant_package($package_name))
	{
		print "Error: other packages depend on this package\n";
		return (7);
	} 

	if ($allnodes)
	{
		if (run_uninstall_client($package_name, $testmode, $imagename, $range))
		{
			print "Error: cannot uninstall on clients.\n";
			return (3);
		}
	}

	if ($headnode)
	{ 
		if (run_uninstall_server($package_name, $testmode))
		{
			print "Error: cannot uninstall on server.\n";
			return (2);
		}
	}

	if($image)
	{
		if(run_uninstall_image($package_name, $testmode, $imagename))
		{
			print "Error: cannot uninstall on the image.\n";
			return (4);
		}
	}

	if ($testmode != 1)
	{
		set_uninstalled($package_name);
	}

	oscar_log_section("Finished running OSCAR package un-install");

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
	#my $error_code = 1; #enable oda debug mode
	my $error_code;

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
	#my $error_code = 1; #enable oda debug mode
	my $error_code;

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
	#my $error_code = 1; #enable oda debug mode
	my $error_code; 

	my $cmdstring = "read_records packages installed name=\"$package_name\"";

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);

	return $my_result[0];
}

#runs uninstall script on the server
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#returns:
#	0 is success
#	1 for failure
#	note: if does nothing, returns 1
sub run_uninstall_server
{
	my ($package_name, $testmode) = @_;

	my $script_path;
	my $cmd_string1;
	my @temp_list;
	my $cmd_string2;
	my $cmd_string3;
	my @cmd_out;

	oscar_log_subsection("Running server un-install");

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	$script_path = "$package_dir/scripts/post_server_rpm_uninstall";
	if (-x $script_path)
	{
		$cmd_string1 = $script_path;

		if ($testmode != 0)
		{
			print "executing: $cmd_string1\n";
		}
		else
		{
			if ( run_command_general($cmd_string1))
			{
				return 1;
			}
		}
		oscar_log_subsection("Completed un-install on server");
		return (0);
	}
	else
	{
		oscar_log_subsection("Error $package_name has no un-install script");
	}

	oscar_log_subsection("Error on server un-install for $package_name");
	return (1);
}

#runs uninstall script on compute nodes or clients
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#	$imagename --> name of an image, scalar string
#	$range --> a range of nodes to act upon
#			note: currently unsupported
#returns:
#	0 is success
#	1 for failure
#	note: returns 1 if does nothing...
sub run_uninstall_client
{
	my ($package_name, $testmode, $imagename, $range) = @_;

	my $script_path;
	my $cmd_string1;
	my @temp_list;
	my $cmd_string2;
	my $cmd_string3;
	my @cmd_out;
	my $retval;
	my @rslts;

	oscar_log_subsection("Running client un-install");

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	$script_path = "$package_dir/scripts/post_client_rpm_uninstall";
	if (-x $script_path)
	{
		@temp_list = split(/\//,$script_path);
		my $imgdir = "/var/lib/systemimager/images/$imagename";

		if (!(-d $imgdir))
		{
			print "Error: not a valid image ($imagename)\n";
			return (1);
		}

		$cmd_string1 = "$C3_HOME/cpush $script_path /tmp/";
		$cmd_string2 = "$C3_HOME/cexec --pipe c3cmd-filter /tmp/$temp_list[$#temp_list]";
		$cmd_string3 = "$C3_HOME/cexec --pipe c3cmd-filter rm -f /tmp/$temp_list[$#temp_list]";

		if ($testmode != 0)
		{
			print "client uninstall actions:\n";
			print "executing: $cmd_string1\n";
			print "executing: $cmd_string2\n";
			print "executing: $cmd_string3\n";
		}
		else
		{
			if ( run_command_general($cmd_string1))
			{
				return 1;
			}
			$retval = cexec_open($cmd_string2, \@rslts); 
			print @rslts if($retval != 0);
			$retval = cexec_open($cmd_string3, \@rslts); 
			print @rslts if($retval != 0);
		}
		oscar_log_subsection("Completed un-install on client");
		return (0);
	}
	else 
	{
		oscar_log_subsection("Error $package_name has no un-install script");
	}

	oscar_log_subsection("Error on client un-install for $package_name");
	return 1;
}

#runs uninstall script on an image
#	$package_name --> name of a package, scalar string
#	$testmode --> if set to "1" run in testmode, scalar string
#	$imagename --> name of an image, scalar string
#returns:
#	1 is failure
#	0 is success
#	returns 1 if does nothing...
sub run_uninstall_image
{
	my ($package_name, $testmode, $imagename) = @_;

	my $script_path;
	my $cmd_string1;
	my @temp_list;
	my $cmd_string2;
	my $cmd_string3;
	my @cmd_out;

	oscar_log_subsection("Running image un-install");

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	$script_path = "$package_dir/scripts/post_client_rpm_uninstall";
	if (-x $script_path)
	{
		@temp_list = split(/\//,$script_path);
		if (!(-d "/var/lib/systemimager/images/$imagename"))
		{
			print "Error: not a valid imagename ($imagename)\n";
			return (1);
		}

		$cmd_string1 = "cp $script_path /var/lib/systemimager/images/$imagename/tmp/";
		$cmd_string2 = "chroot /var/lib/systemimager/images/$imagename /tmp/$temp_list[$#temp_list]";
		$cmd_string3 = "rm -f /var/lib/systemimager/images/$imagename/tmp/$temp_list[$#temp_list]";

		if ($testmode != 0)
		{
			print "executing: $cmd_string1\n";
			print "executing: $cmd_string2\n";
			print "executing: $cmd_string3\n";
		}
		else
		{
			if ( run_command_general($cmd_string1))
			{
				return 1;
			}
			if ( run_command_general($cmd_string2))
			{
				return 1;
			}
			if ( run_command_general($cmd_string3))
			{
				return 1;
			}
		}
		oscar_log_subsection("Completed un-install on image");
		return (0);
	}
	else
	{
		oscar_log_subsection("Error $package_name has no un-install script");
	}

	oscar_log_subsection("Error on image un-install for $package_name");

	return (1);
}

#invokes an mksimachine command to find out image info
#about the cluster.
#	$image_aa_ref --> a reference to an aa that contains 
#					image names as keys and node names as values
#	
#
#returns: number of images (note: this is the number of keys in $image_aa_ref
sub get_image_info
{
	my ($image_aa_ref) = @_;
	my $line;
	my @rslt;
	my $cmd_string = "mksimachine --parse";
	my @split_line;

	open(NEWCMD, "$cmd_string |") or Carp::croak "cannot run command:$!\n";
	@rslt = <NEWCMD>;
	chomp(@rslt);
	close(NEWCMD);

	foreach $line (@rslt)
	{
		if ($line =~ "#Adapter definitions")
		{
			#done
			last;
		}
		elsif ($line =~ "#Machine definitions")
		{
			#ignore
			next;

		}
		elsif ($line =~ "#Name:Hostname:Gateway:Image")
		{
			#ignore
			next;
		}
		else
		{
			#split the line, stick it in the ref
			@split_line = split(/:/,$line);
			$$image_aa_ref{$split_line[3]} = $split_line[0];
		}
	}
	return keys(%$image_aa_ref);
}

#runs a commandstring and uses the open()
#to do it...prints what it is trying to run, and 
#prints all stderr and stdout on a detected error
#	$cmd_string --> a string of a command to run
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
		print "Error executing:$cmd_string\n";
		return 1;
	} 

	if ($CHILD_ERROR == 0)
	{
		return 0;
	}
	else
	{
		#log results
		print "Error executing:$cmd_string\n:";
		foreach $aline (@cmd_out)
		{	
			print $aline."\n";
		}
		return 1;
	}
}

#checks to see if a package is dependant on another
#	$package_name --> a valid package name
#returns 1 if
#if it is and that package is already installed
#if it is not dependant on anything
#returns 0 otherwise
sub check_package_dependancy 
{
	my ($package_name) = @_;
	my $cmdstring = "read_records packages_requires name package=\"$package_name\"";
	my @my_result;
	my $error_code = 1;
	my $record;

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);

	foreach $record (@my_result)
	{
		if( !is_installed($record) )
		{
			print "Package $package_name needs $record to be installed first.\n";
			return (1);
		}
	}
	return (0);
} 

#checks to see if a package has other packages
#that depend on it
#	$package_name --> a valid package name
#returns 1 if other packages depend on it
#returns 0 otherwise
sub check_dependant_package
{
	my ($package_name) = @_;
	my $cmdstring = "read_records packages_requires package name=\"$package_name\"";
	my @my_result;
	my $error_code = 1;
	my $record;

	OSCAR::Database::database_execute_command($cmdstring, \@my_result, $error_code);

	foreach $record (@my_result)
	{
		if( is_installed($record) )
		{
			print "Package $package_name is needed by package $record.\n";
			return (1);
		}
	}
	return (0);
}

#--------------------------------------------------------------------
# FIXME: Note, it might make since to just get the full command
#        and internally prepend the 'cexec --pipe c3cmd-filter'
#        since it must be used for the function to work properly at all!
#--------------------------------------------------------------------
#  Descr: Wrapper to perform a C3 cexec command w/ error checking.
#         Return a boolean code for success/errors & upon error pass
#         the command output back for logging, etc.
#  Input: Command to execute (cexec --pipe c3cmd-filter ...)
#         Array reference to hold error output
# Output: Result array containing command output 
# Return: 0 (success), 1 (errors)
#  Usage:  my $rc = cexec_open($cmd, \@rslts); 
#          print @rslts if($rc != 0);
#
#   Note: Requires 'c3cmd-filter' to determine node errors.
#   Note: Returns all output upon error, use trimmer function to trim
#         to only the problem nodes, ie. only get node that failed.
#--------------------------------------------------------------------
sub cexec_open
{
	my $cmd  = shift;
	my $aref = shift;
	my @rslt;

	if( defined( open(CMD, "$cmd 2>&1 |")) ) { # Redirect STDERR to STDOUT
		@rslt = <CMD>;
		close(CMD);

		if( $CHILD_ERROR == 0 ) {
			# C3 cmd went fine, process results from 'c3cmd-filter'
			if( eval_c3cmd_filter(@rslt) == 0 ) {
				# Success: No node errors
				@{$aref} = ();
				return(0);
			}
			else {
				# Errors: Node(s) had errors
				push @{$aref}, @rslt;
				return(1); 
			}
        	}
		else {
			# C3 Command had an erroneous result
			push @{$aref}, @rslt;
			return($CHILD_ERROR);
		}
	}
	else {
		# Open failed
		push @{$aref}, "Error: Open failed ($cmd) $!\n";
		return(1);
	}

	# Should never get here.
	return(0);
}


#--------------------------------------------------------------------
#  Descr: Walk over output from 'cexec --pipe c3cmd-filter CMD' and
#         return a boolean code for success/errors.
#  Input: Array containing output from 'cexec --pipe c3cmd-filter'
# Output: n/a
# Return: 0 (success), 1 (errors)
#  Usage:  $rc = eval_c3cmd_filter(@rslt);
#   Note: Requires 'c3cmd-filter' to determine node errors.
#--------------------------------------------------------------------
sub eval_c3cmd_filter
{
	my @rslt = @_;
	my $e = 0;

	foreach my $ln (@rslt) {
		my ($node, $output) = split(/:(.*)$/, $ln);
		if($output) {
			$e = 1;
			last;
		}
	}	

	return( $e );
}



#--------------------------------------------------------------------
# FIXME: I still have to code this method.  The main reason I've not done
#        this yet is b/c I want to make sure I don't skip blank lines from
#        commands, even when they are erroneous, ie. error lines but have '\n\n' :)
#        Likely use a HoL, and keys() is the num nodes & then flatten to array
#        upon return for easy caller usage.
#--------------------------------------------------------------------
#  Descr: Trims 'cexec --pipe' output to remove blank responses from nodes.
#  Input: Array reference for trimmed results,
#         Array containing output from a 'cexec --pipe'
# Output: Array reference containing trimmed output 
# Return: Number of unique nodes remaining in output
#  Usage:  $n = trim_cexec-pipe_output(\@trim_rslts, @output);
#--------------------------------------------------------------------
sub trim_cexec_pipe_output
{
	my $trslts = shift;  # Array ref (output variable)
	my $rslts  = @_;  
	my $n = 0; 

	print "STUB: THIS IS NOT READY YET.\n";
	return(-1);
}


1;
