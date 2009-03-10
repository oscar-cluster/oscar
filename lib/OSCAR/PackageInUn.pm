package OSCAR::PackageInUn;
# 
#  $Id$
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
# Copyright (c) 2005-2007 The Trustees of Indiana University.  
#                    All rights reserved.

use strict;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
        unshift @INC, "$ENV{OSCAR_HOME}/lib/Qt";
    }
}

use Carp;
use Cwd;

use SIS::DB;

use OSCAR::Package;
use OSCAR::Database;
use OSCAR::Logger;
use OSCAR::Configurator;
use Tk::Dialog;
use English;
use OSCAR::PackMan;
use OSCAR::WizardEnv;

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
                 check_package_dependency
                 check_dependent_package
                 uninstall_rpms_patch);

my $C3_HOME = '/opt/c3-4'; #evil hack to fix pathing to c3
my @error_list = ();
my %options = ();
my $OSCAR_SERVER_NODE = "oscar_server";

#########################################################################
#  Subroutine: install_uninstall_packages                               #
#  Parameters: Reference to the main Tk window                          #
#  Returns   : 0, which generally means success                         #
#              1 in the event of a failure...but we currently           #
#              never return 1                                           #
#  This subroutine pops up the "Updater" (which is simply the Selector  #
#  run in a different mode).  This allows the user to select packages   #
#  to install/uninstall.  When the Updater exits, we check to see if    #
#  any packages selected for installation have optional configuration   #
#  associated with them.  If so, we prompt the user if he wants to      #
#  run the Configurator.  After that, we get the lists of packages      #
#  to be installed/uninstalled and take appropriate action.  At the     #
#  end of the subroutine, all of the flags should be updated            #
#  appropriately in oda.                                                #
#########################################################################
sub install_uninstall_packages
{
  my $mainwindow = shift;

	my $imagenumber; # number of images on the system
	my %imagehash; #hash of imagename node range pairs
	my @imagename; #a list of all the images, but we fail unless we have only one
	my $success;  # Return code for database calls
	my $package;  # Name of a package to be installed/uninstalled
	my @packagesThatShouldBeInstalled;    # List of packages to install
	my @packagesThatShouldBeUninstalled;  # List of packages to uninstall
	my @all_packages; #list of all packages
	my $flag = 0; #set to one if one package got installed

  # First, bring up the "Updater", which is the "Selector" run with the
  # command line option of '--installuninstall'.
  my $olddir = Cwd::cwd();
  chdir($ENV{OSCAR_HOME} . '/lib/Qt');
  system('/usr/bin/perl Selector.pl -i');
  chdir($olddir);

    # 
    # dikim commented out the LOCKING codes here because he believes
    # that InnoDB type can handle the all the crossing locking issues.
    # He does not want to remove these codes because he easily forgets
    # what files have locking codes and where they are and he may need
    # them in case innodb works as we expected.
	# START LOCKING FOR NEST
	my @tables = ("Packages", "Groups", "Group_Packages");
	
	#locking("read", \%options, \@tables, \@error_list);
	
	# Get the lists of packages that need to be installed/uninstalled
    my @selected = ();
    my @unselected = ();
    
    $success = OSCAR::Database::get_selected_packages(\@selected,
                                                      \%options,
                                                      \@error_list,
                                                      undef);
    $success = OSCAR::Database::get_unselected_packages(\@unselected,
                                                        \%options,
                                                        \@error_list,
                                                        undef);
    foreach my $selected_ref (@selected){
        push @packagesThatShouldBeInstalled, $$selected_ref{package};
    }    
    foreach my $unselected_ref (@unselected){
        push @packagesThatShouldBeUninstalled, $$unselected_ref{package};
    }    
	# UNLOCKING FOR NEST
	#unlock(\%options, \@error_list);


  # If the user selected any packages for installation, prompt to see if he
  # wants to run the Configurator.
  if (@packagesThatShouldBeInstalled)
    {
      my $response = $mainwindow->messageBox(
        -title=>"Configure?",
        -message=>"You have selected packages for installation. " .
                  "Do you want to run the Configurator?",
        -type=>'YesNo',
        -default=>'yes',
        -icon=>'question');
      if ($response =~ /yes/i)
        {
          oscar_log_subsection("PLEASE WAIT!  Bring up the Configurator...\n");
          my $configwindow = OSCAR::Configurator::displayPackageConfigurator(
                             $mainwindow,2);
          $configwindow->waitWindow;  # Wait for the Configurator to exit
        }
    }

	$imagenumber = get_image_info(\%imagehash);

	#see if there is anything to do
	if ( (scalar(@packagesThatShouldBeInstalled) <= 0) && 
       (scalar(@packagesThatShouldBeUninstalled) <= 0) )
	{
		print "Notice: Nothing to do.\n";
		return (0);
	}

	#we only support one image in this version
	if ($imagenumber != 1)
	{
		print "Warning: This program only supports one image.\n";
		return (0);
	}
	@imagename = keys(%imagehash);
	croak "Error: no imagename\n" if( !defined($imagename[0]) );

	#sanity check
	if ((sanity_check()) != 0)
	{
		print "Warning: sanity check failed.\n";
		return (0);
	}

	#Loop through the list of packages to be UNINSTALLED and do the right
	#thing
	foreach $package (@packagesThatShouldBeUninstalled)
	{
		$success = package_uninstall($package, "1", "1", "1", $imagename[0], "blah", "0");
                                                                                
		# If the removal was successful, clear the 'installed' flag for
		# that package in the database.  Also, clear the
		# 'should_be_uninstalled'
		# flag for that package.
		if (!$success)
		{
			# make sure the package we un-installed is un-selected in selector so scripts won't run
            OSCAR::Database::delete_group_packages(undef,$package,\%options,\@error_list);
		}
		else
		{
            # If PackageInUn fails to uninstall the package,
            # roll the Node_Package_Status back to the previous status.
            my $node = $OSCAR_SERVER_NODE;
            my @results = ();
            OSCAR::Database::get_node_package_status_with_node_package($node,$package,\@results,\%options,\@error_list);
            if (@results) {
                my $pstatus_ref = pop @results;
                my $ex_status = $$pstatus_ref{ex_status};
                OSCAR::Database::update_node_package_status(
                    \%options, $node, $package, $ex_status, \@error_list, undef);
            }
			my $e_string = "Error: package ($package) failed to uninstall.\n";
			print $e_string;
			add_error($e_string);
		}
	}

	# Loop through the list of packages to be INSTALLED and do the right thing
	foreach $package (@packagesThatShouldBeInstalled)
	{
		$success = package_install($package, "1", "1", "1", $imagename[0], "blah", "0");
		# If the installation was successful, set the 'installed' flag for
		# that package in the database.  Also, clear the 'should_be_installed'
		# flag for that package.
		if (!$success)
		{

            # New database schema can trace what group has been selected.
            # So if $group parameter is not set, Database.pm will find the selected group.
            # At the below subroutine, undef is for $group parameter.
            OSCAR::Database::delete_group_packages(undef,$package,\%options,\@error_list);

		}
		else
		{
            # If PackageInUn fails to install the package,
            # roll the Node_Package_Status back to the previous status.
            my $node = $OSCAR_SERVER_NODE;
            my @results = ();
            OSCAR::Database::get_node_package_status_with_node_package($node,$package,\@results,\%options,\@error_list);
            if (@results) {
                my $pstatus_ref = pop @results;
                my $ex_status = $$pstatus_ref{ex_status};
                OSCAR::Database::update_node_package_status(
                    \%options,$node,$package,$ex_status,\@error_list,undef);
            }
			my $e_string = "Error: package ($package) failed to install.\n";
			print $e_string;
			add_error($e_string);
		}
	}

	#added this to reprint all errors found
	print_errors();

	#now run every packages post_install phase if it is installed
	@all_packages = OSCAR::Package::list_selected_packages(); 
	foreach my $package_ref (@all_packages)
	{
        my $package = $$package_ref{package};
		if(is_installed($package))
		{
			if (OSCAR::Package::run_pkg_script($package, 'post_install', 1, '0'))
			{
				print "executed post_install phase on server for package: ($package)\n";
			}
			else
			{
				my $e_string = "Warning: nothing ran for ($package) post_install phase on server\n";
				print $e_string;
				add_error($e_string);
			}
		}
	}

	#added this to reprint all errors found...again
	#included the stuff from the post_installs
	print_errors();
                                                                                
    OSCAR::Database::initialize_selected_flag(\%options,\@error_list);
	oscar_log_section("Finished running Install/Uninstall OSCAR Packages");
	
	return 0;
}

#performs a (cexec hostname) as a basic cluster sanity check
#returns 0 on success, 1 otherwise...
#prints output if the sanity check fails 
sub sanity_check
{
	my $cmd_string = "$C3_HOME/cexec --pipe c3cmd-filter hostname";
	my $retval;
	my @rslts;

	$retval = cexec_open($cmd_string, \@rslts); 
	if( $retval != 0 ) 
	{
		print @rslts; 
		return(1);
	}
	return 0;
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
#   7 package is dependent on another package
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

	oscar_log_section("Running OSCAR package install");

	#add check to see if package exists
	if ((is_package_a_package($package_name)) =~ 1)
	{
		my $e_string = "Error: package ($package_name) does not exist...\n";
		print $e_string;
		add_error($e_string);
		return 6;
	} 


	if (is_installed($package_name,1))
	{
		my $e_string = "Error: package ($package_name) is installed already, aborting...\n";
		print $e_string;
		add_error($e_string);
		return (5);
	}

	#check to see if package is dependent on anything
	if( check_package_dependency($package_name))
	{
		my $e_string = "Error: package has dependencies\n";
		print $e_string;
		add_error($e_string);
		return (7);
	} 

	if (!$headnode && !$allnodes && !$image)
	{
		my $e_string = "Error: no install target selected.\n";
		print $e_string;
		add_error($e_string);
		return (1);
	}

	if($allnodes)
	{
		if(!run_install_client($package_name, $testmode, $imagename, $range))
		{
			my $e_string = "Error: cannot install to the nodes.\n";
			print $e_string;
			add_error($e_string);
			return (3);
		}
	}

	if($headnode)
	{
		if(!run_install_server($package_name, $testmode))
		{
			my $e_string = "Error: cannot install on the server.\n";
			print $e_string;
			add_error($e_string);
			return (2);
		}
	}

	if($image)
	{
		if(!run_install_image($package_name, $testmode, $imagename))
		{
			my $e_string = "Error: cannot install to the image:$image\n";
			print $e_string;
			add_error($e_string);
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
		my $e_string = "Error: image name is invalid\n";
		print $e_string;
		add_error($e_string);
		return (0);
	}

	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if( !defined($package_dir) )
	{
		my $e_string = "Error: can't find the package\n";
		print $e_string;
		add_error($e_string);
		return (0);
	}

	$retval = get_rpm_list($package_name, $type, \@rpmlist);
	if($retval == 0)
	{
		if((check_rpm_list("image", \@rpmlist, \@newrpmlist, "/var/lib/systemimager/images/$imagename")) != 0)
		{
			my $e_string = "Error: check_rpm_list() failed\n";
			print $e_string;
			add_error($e_string);
			return (0);
		}

		if (scalar(@newrpmlist) > 0)
		{
			$cmd_string1 = "$C3_HOME/cexec --pipe c3cmd-filter mkdir -p /tmp/tmpinstallrpm/";
			$all_rpms = "";
			foreach $rpm (@newrpmlist)
			{
				@temp_list = split(/\//,$rpm);
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
				if( $retval != 0 ) 
				{
					print @rslts; 
					return(0);
				}

				foreach $rpm (@newrpmlist)
				{
					$cmd_string2 = "$C3_HOME/cpush $rpm /tmp/tmpinstallrpm/";
					if ( run_command_general($cmd_string2) )
					{
						return 0;
					}

				}
				$retval = cexec_open($cmd_string3, \@rslts); 
				if( $retval != 0 ) 
				{
					print @rslts; 
					return(0);
				}
				
				$retval = cexec_open($cmd_string4, \@rslts); 
				if( $retval != 0 ) 
				{
					print @rslts; 
					return(0);
				}
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
			if( $retval != 0 ) 
			{
				print @rslts; 
				return(0);
			}

			$retval = cexec_open($cmd_string3, \@rslts); 
			if( $retval != 0 ) 
			{
				print @rslts; 
				return(0);
			}
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
			if( $retval != 0 ) 
			{
				print @rslts; 
				return(0);
			}
			$retval = cexec_open($cmd_string3, \@rslts); 
			if( $retval != 0 ) 
			{
				print @rslts; 
				return(0);
			}
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

		my $e_string = "Error: image name ($imagename) is invalid\n";
		print $e_string;
		add_error($e_string);
		return (0);
	}

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	if( !defined($package_dir) )
	{
		my $e_string = "Error: can't find the package\n";
		print $e_string;
		add_error($e_string);
		return (0);
	}
	
	$retval = get_rpm_list($package_name, $type, \@rpmlist);
	if($retval == 0)
	{
		if((check_rpm_list("image", \@rpmlist, \@newrpmlist, "/var/lib/systemimager/images/$imagename")) != 0)
		{
			my $e_string = "Error: check_rpm_list failed\n";
			print $e_string;
			add_error($e_string);
			return (0);
		}

		if (scalar(@newrpmlist) > 0)
		{

			$all_rpms_full_path = "";
			$all_rpms = "";
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
		my $e_string = "Error: finding rpms to install failed\n";
		print $e_string;
		add_error($e_string);
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
			print "Warning: nothing ran for ($package_name) post_rpm_install phase on the image.\n";
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
		my $e_string = "Error: can't find the package\n";
		print $e_string;
		add_error($e_string);
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
			my $e_string = "Error: check_rpm_list failed\n";
			print $e_string;
			add_error($e_string);
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
			print "executed post_server_install phase on server\n";
			#ran something
			$flag = 1;
		}
		else
		{
			print "Warning: nothing ran for ($package_name) post_server_install \n";
		}
		
		if (OSCAR::Package::run_pkg_script($package_name, 'post_clients', 1, '0'))
		{
			print "executed post_clients phase on server\n";
			$flag = 1;
		}
		else
		{
			print "Warning: nothing ran for ($package_name) post_clients phase on server\n";
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
	my @trimmed_list;

	my $rpm;
	my $rawrpm;
	my %rpmhash;
	my %tftpbootrpmhash;
	my $rpmstring = "/bin/rpm -q --nosignature --queryformat=\"%{NAME}\" -p ";
	my $rpmname;
	my $count;
	my $openstring;
	my $key;

	my @tftprpmlist;

	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);
    my %sel = ( "group" => $type );
	@rpm_list_database =
        OSCAR::Database::pkgs_of_opkg($package_name,"",\@error_list, %sel);

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

	#make sure there is supposed to be at least 1 rpm
	if (scalar(@rpm_list_database) == 0)
	{
		#add logic here to deal with the null case
		print "Warning: No rpms listed for $type in database.\n";
        my %sel = ( "group" => "all" );
        @rpm_list_database =
            OSCAR::Database::pkgs_of_opkg($package_name,"",\@error_list, %sel);
		if (scalar(@rpm_list_database) == 0)
		{
			print "Warning: No rpms listed for both in database.\n";
			print "Warning: trying to get rpms from $package_dir/RPMS\n";
			$count = 0;

			foreach $key (keys(%rpmhash))
			{
				${$rpmlistref}[$count] = $rpmhash{$key};
				$count++;
			}

			if($count == 0)
			{
				return (1);
			}

			print "RPMS that need to be installed:\n";
			foreach $rpm ( @{$rpmlistref} ) 
			{
				print " - $rpm\n";
			}
			return (0);
		}
	}
	else
	{

		#Stick the rpms from /tftpboot/rpm into a list
		opendir(DNAME, "/tftpboot/rpm") or Carp::croak "cannot read directory: $!\n";
		@temp = readdir(DNAME) or Carp::croak "cannot read directory: $!\n";
		@tftprpmlist = grep( !/^\.{1,2}$/ && /\.rpm$/ && !/ia64\.rpm$/, @temp);
		closedir(DNAME);

		#trim down the list to possibles
		foreach $rpm (@rpm_list_database)
		{
			@temp = grep(/^$rpm/,@tftprpmlist);
			push @trimmed_list, @temp;
		}
		
		#Stick the trimmed down list of rpms from /tftpboot/rpm into an aa 
		#in case we need them later
		$cmd_string = "/tftpboot/rpm/";
		foreach $rpm (@trimmed_list)
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
					$tftpbootrpmhash{$rpmname} = "$cmd_string$rpm";
				}
			}
		}


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
				if( exists ($tftpbootrpmhash{$rpm}) ) #else error
				{
					${$rpmlistref}[$count] = $tftpbootrpmhash{$rpm};
					$count++; 
				}
				else
				{
					#no match even in /tftpboot/rpm...punt
					my $e_string = "Error: No rpm found for:$rpm\n";
					print $e_string;
					add_error($e_string);
				}
			}
		}

		#if the number we found doesn't match the number we need
		if ($count != scalar(@rpm_list_database))
		{
			#in a sane world this should fail...
			#and now it does
			my $e_string = "Error: number of rpms in database do not match number found on filesystem.\n";
			print $e_string;
			add_error($e_string);
			return 2;
		}

		print "RPMS that need to be installed:\n";
		foreach $rpm ( @{$rpmlistref} ) 
		{
			print " - $rpm\n";
		}
		return (0);

	}#end else
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

	oscar_log_section("Running OSCAR package un-install");

	if ((is_package_a_package($package_name)) =~ 1)
	{
		my $e_string = "Error: package ($package_name) does not exist...\n";
		print $e_string;
		add_error($e_string);
		return 6;
	} 

	if (! is_installed($package_name,1))
	{
		my $e_string = "Error: package ($package_name) is not installed, aborting...\n";
		print $e_string;
		add_error($e_string);
		return (6);
	}

	if (!$headnode && !$allnodes && !$image)
	{
		my $e_string = "Error: no uninstall target selected\n";
		print $e_string;
		add_error($e_string);
		return (1);
	} 
	#check to see if other packages need it
	if( check_dependent_package($package_name))
	{
		my $e_string = "Error: other packages depend on this package\n";
		print $e_string;
		add_error($e_string);
		return (7);
	} 

	if ($allnodes)
	{
		if (run_uninstall_client($package_name, $testmode, $imagename, $range))
		{
			my $e_string = "Error: cannot uninstall on clients.\n";
			print $e_string;
			add_error($e_string);
			return (3);
		}
	}

	if ($headnode)
	{ 
		if (run_uninstall_server($package_name, $testmode))
		{
			my $e_string = "Error: cannot uninstall on server.\n";
			print $e_string;
			add_error($e_string);
			return (2);
		}
	}

	if($image)
	{
		if(run_uninstall_image($package_name, $testmode, $imagename))
		{
			my $e_string = "Error: cannot uninstall on the image.\n";
			print $e_string;
			add_error($e_string);
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
	my @result_ref;

	my $result_ref=OSCAR::Database::get_package_info_with_name($package_name,\%options,\@error_list);

	if ($result_ref)
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
    OSCAR::Database::set_group_packages(undef,$package_name,8,\%options,\@error_list);
}

#this sets the installed field in table packages to 0
#takes as input a scalar string that is a package name
#does set oda's error code to verbose
#returns nothing, as nothing gets returned to me from oda
sub set_uninstalled
{
	my ($package_name) = @_;	
    OSCAR::Database::delete_group_packages(undef,$package_name,\%options,\@error_list);
}

#queries oda to see if a package is installed
#takes as input a scalar string that is a package name
#returns 1 if the package is installed, 0 otherwise
#does set oda's error code to verbose
#
#note: actually returns the value of the installed field
sub is_installed{
    my ($package_name, $selector) = @_;	

    return OSCAR::Database::is_installed_on_node($package_name,
            $OSCAR_SERVER_NODE,\%options,\@error_list,$selector,undef);
}

sub uninstall_rpms_patch
#patch fuction added 2/20/05
#uninstall's rpms, takes the database at its word
#works on the headnode or the compute nodes/image
#args:
#$package_name = name of a valid OSCAR package
#$type is either oscar_server or oscar_client
#return:
#0 on success
#1 on failure
{
	my ($package_name, $type) = @_;
	my @rpm_list;
	my $cmd_string;
	my $rpm;
	my $rpms = "";
	my $pm;
	my $retval = 0;
	my @rslts;
	
    my %sel = ( "group" => $type );
	@rpm_list =
        OSCAR::Database::pkgs_of_opkg($package_name,"",\@error_list, %sel);

	if ($type =~ "oscar_client")
	{
		#handle clients
		$cmd_string = "$C3_HOME/cexec yume -y remove ";
		print "client\n";

	} 
	elsif($type =~ "oscar_server")
	{
		print "server\n";
		$cmd_string = "";
	}

	foreach $rpm (@rpm_list)
	{
		$rpms = $rpms." ".$rpm;
	}
	$cmd_string = $cmd_string.$rpms;
	#print $cmd_string;
	#exit (0);

	if ($type =~ "oscar_client")
	{
		print("Uninstalling package $package_name on client nodes\n");
		$retval = cexec_open($cmd_string, \@rslts); 
		if( $retval != 0 )
		{ 
			oscar_log_subsection("Error on client rpm un-install for $package_name \n");
			my $e_string = "Error on client rpm un-install for $package_name \n";
			add_error($e_string);
			return(1);
		}

		#handle image
		#$pm = PackMan::RPM->new;
		#$pm->chroot("/var/lib/systemimager/images/oscarimage");
		#if($pm->remove( @rpm_list ))
		#{
		#	return 0;
		#}
		my @images = list_image();
		my $imagepath = "/var/lib/systemimager/images";
		my $image;

		foreach (@images) {
		  $image = $_->name;
		  print("Uninstalling package $package_name from image $image\n");
		  if (!system("yume --installroot $imagepath/$image -y remove $rpms")) {
			return 0;
		  } else {
			oscar_log_subsection("Error on image [$image] RPM un-install for $package_name \n");
			my $e_string = "Error on image [$image] RPM un-install for $package_name \n";
			add_error($e_string);
			return 1;
		  }
		}
		
	}
	elsif($type =~ "oscar_server")
	{
		#$pm = PackMan::RPM->new;
		#$pm->chroot(undef);
		#if($pm->remove( @rpm_list ))
		#{
		#	return 0;
		#}
		print ("Uninstalling package $package_name from headnode\n");
		if (!system("yume -y remove $rpms")) {
			return 0;
		}
		else
		{
			oscar_log_subsection("Error on server rpm un-install for $package_name \n");
			my $e_string = "Error on server rpm un-install for $package_name \n";
			add_error($e_string);
			return 1;
		}
	}
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
	
	if (uninstall_rpms_patch($package_name, "oscar_server") != 0)
	{
		my $e_string = "Error on server un-install for $package_name \n";
		add_error($e_string);
		return 1;
	}

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
	return (0);
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

	if (uninstall_rpms_patch($package_name, "oscar_client") != 0)
	{
		my $e_string = "Error on server un-install for $package_name \n";
		add_error($e_string);
		return 1;
	}

	#get the package dir sanely
	my $package_dir = OSCAR::Package::getOdaPackageDir($package_name);

	$script_path = "$package_dir/scripts/post_client_rpm_uninstall";
	if (-x $script_path)
	{
		@temp_list = split(/\//,$script_path);
		my $imgdir = "/var/lib/systemimager/images/$imagename";

		if (!(-d $imgdir))
		{
			my $e_string = "Error: not a valid image ($imagename)\n";
			print $e_string;
			add_error($e_string);
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
			if( $retval != 0 ) 
			{
				print @rslts; 
				return(0);
			}
			$retval = cexec_open($cmd_string3, \@rslts); 
			if( $retval != 0 ) 
			{
				print @rslts; 
				return(0);
			}
		}
		oscar_log_subsection("Completed un-install on client");
		return (0);
	}
	return 0;
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
			my $e_string = "Error: not a valid imagename ($imagename)\n";
			print $e_string;
			add_error($e_string);
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

	return (0);
}

#invokes an mksimachine command to find out image info
#about the cluster.
#	$image_aa_ref --> a reference to an aa that contains 
#					image names as keys and node names as values
#	
#
#returns: number of images (note: this is the number of keys in $image_aa_ref
#note: this function is not completely implemented, but is ok for now
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
		my $e_string = "Error executing:$cmd_string\n";
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
		my $e_string = "Error executing:$cmd_string:\n";
		print $e_string;
		add_error($e_string);
		foreach $aline (@cmd_out)
		{	
			print $aline."\n";
		}
		return 1;
	}
}

#checks to see if a package is dependent on another
#	$package_name --> a valid package name
#returns 1 if
#if it is and that package is already installed
#if it is not dependent on anything
#returns 0 otherwise
sub check_package_dependency 
{
	my ($package_name) = @_;
	my @results;
    my @tables = ("packages_requires");
	my $record;

    OSCAR::Database::get_packages_related_with_package(
                "requires",$package_name,\@results,\%options,\@error_list);
                
    foreach my $result_ref (@results){
        my $record = $$result_ref{p2_name};
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
sub check_dependent_package
{
	my ($package_name) = @_;
	my @results;
    my @tables = ("packages_requires");
	my $record;

    OSCAR::Database::get_packages_related_with_name(
                "requires",$package_name,\@results,\%options,\@error_list);

    foreach my $result_ref (@results){
        my $record = $$result_ref{package};
		if( is_installed($record) )
		{
			print "Package $package_name is needed by package $record.\n";
			return (1);
		}
	}
	return (0);
}

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

	print "executing:$cmd\n";

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

#this function adds an error to the global list
#returns nothing
sub add_error
{
	my $error_string = shift;
	push(@error_list, $error_string);
}

#this method prints out the global list
#returns nothing
sub print_errors
{
	my $error;
	foreach $error (@error_list)
	{
		print $error;
	}
}


1;
