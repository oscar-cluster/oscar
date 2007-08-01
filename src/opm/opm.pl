#!/usr/bin/perl

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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
#   Copyright (c) 2007 Oak Ridge National Laboratory
#                      All rights reserved
#
#   $Id$

use strict;

use lib "/usr/lib/perl5/OSCAR", "$ENV{OSCAR_HOME}/lib";
use OSCAR::Database;
	
use Data::Dumper;
use PackMan;
use OSCAR::opd2;

my %options;
my @error_strings;

our $name;
our $type;
our $pm;

print "===Setting up package repositories===\n" if $ENV{OSCAR_DEBUG};

# Setup PackMan

$pm = PackMan->new;
$pm->repo(OSCAR::opd2::get_available_repositories());
$pm->gencache;

# Get the status code for an error

my $error_status_code = get_pkg_status_num(\%options, 'error', \@error_strings);

print "===Determining if running on server/client/image..." if $ENV{OSCAR_DEBUG};

# Determine if this is running on a server or a client

open(CONFIG, "/etc/opm.conf");
my @lines = <CONFIG>;
chomp @lines;
$type = $lines[0];
$name = $lines[1];
close(CONFIG);

print "$type===\n" if $ENV{OSCAR_DEBUG};

# Get current status of the OSCAR install

my %wizard_status = %{get_wizard_status(\%options, \@error_strings)};

print "===Getting a list of all OSCAR Packages===\n" if $ENV{OSCAR_DEBUG};

# Get a list of all the packages from the server/client/image

my @packages;

if($type eq 'server' || $type eq 'client' ) {
	get_node_package_status_with_node($name, \@packages, \%options, \@error_strings);
	
} elsif($type eq 'image') {
	get_image_package_status_with_image($name, \@packages, \%options, \@error_strings);
} else {
	die "Invalid type in /etc/opm.conf\n";
}

print "===Looking at each package to determine work===\n" if $ENV{OSCAR_DEBUG};

# Loop over each package
# If the package's 'requested' is different from 'curr' and 'status' is not
# an error, we need to do work

for my $package (@packages) {
	my $package_name = $$package{package};
	if($type eq 'server' || $type eq 'client' ) {
		my @results;
		get_node_package_status_with_node_package($name, $package_name, \@results, \%options, \@error_strings);
		my $pstatus_ref = pop @results;
		
#		print "$package_name\tREQUESTED: $$pstatus_ref{requested}\tCURR: $$pstatus_ref{curr}\tSTATUS: $$pstatus_ref{status}\n";
		
		if($$pstatus_ref{requested} ne $$pstatus_ref{curr} && $$pstatus_ref{status} ne $error_status_code) {
		
			print "===$package_name needs to do work on $name===\n" if $ENV{OSCAR_DEBUG};
			
			# Requested and curr are different and status does not equal error
			if($type eq 'server') {
				while(do_work_server($$pstatus_ref{requested}, $$pstatus_ref{curr}, \%wizard_status, $package_name)) {}
			} elsif($type eq 'client') {
				while(do_work_node($$pstatus_ref{requested}, $$pstatus_ref{curr}, \%wizard_status, $package_name)) {}
			}
		}
	} elsif($type eq 'image') {
		my @results;
		get_image_package_status_with_image_package($name, $package, \@results, \%options, \@error_strings);
		my $pstatus_ref = pop @results;
		if($$pstatus_ref{requested} ne $$pstatus_ref{curr} && $$pstatus_ref{status} ne $error_status_code) {
		
			print "===$package_name needs to do work on $name===\n" if $ENV{OSCAR_DEBUG};
		
			# Requested and curr are different and status does not equal error
			while(do_work_image($$pstatus_ref{requested}, $$pstatus_ref{curr}, \%wizard_status, $package_name)) {}
		}			
	}
}

# Takes the 'requested' and 'curr' values and the status of the cluster as a
# whole and decides what work needs to be done for the specified package on a
# server.  If a package is completed, the work for the compute nodes will be
# assigned and OPM will be started on those nodes.
# Parameters: $requested - The phase that has been requested in the database
#             $curr - The curr phase the package has reached
#             $cluster_status - The curr phase the cluster has reached
#             $package - The name of the package being installed
# Returns:    1 - If there is more work to do
#             0 - If the package does not have more work to do right now
sub do_work_server {
	my ($requested,
		$curr,
		$cluster_status_ref,
		$package) = @_;
		
	my $next_stage_num;
		
	# Figure out which phase is next
	if($requested > $curr) {
		$next_stage_num = $curr+1;
	} else {
		return 0;
	}
	
	# Get the number of the should_be_installed phase
	my $low_num = get_status_num(\%options, "should_be_installed", \@error_strings);
	# Make sure we don't pick an invalid stage (should_not_be_installed)
	if($next_stage_num < $low_num) {$next_stage_num = $low_num;}
	
	my %options;
	my @error_strings;
	
	my $next_stage_string = get_status_name(\%options, $next_stage_num, \@error_strings);
	
	print "===$package is running $next_stage_string===\n";
	
	# Start the appropriate phase (if/elsif/else statement)
	
	if($next_stage_string eq "should_be_installed") {
		# Install the binary package (opkg-<package>)
		my ($err, $outref) = $pm->smart_install("opkg-$package");
		
		# If there is an error, copy it to the database and note it
		if($err) {
			my %status_vars;
			$status_vars{curr} = "should_be_installed";
			$status_vars{status} = "error";
			$status_vars{errorMsg} = $err;
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
			return 0;
		} else { # Otherwise mark it as done and move on
			my %status_vars;
			$status_vars{status} = "should-be-installed_phase_done";
			$status_vars{errorMsg} = "";
			$status_vars{curr} = "should-be-installed";
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		}	
	} elsif($next_stage_string eq "run-configurator") {
		# Check to see if there is a pre-configure script
		if(-f "/var/lib/packages/$package/api-pre-configure") {
			my $rc = system("/bin/sh /var/lib/packages/$package/api-pre-configure");
			if($rc) {
				my %status_vars;
				$status_vars{curr} = "run-configurator";
				$status_vars{status} = "error";
				$status_vars{errorMsg} = 'Script failed';
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
				return 0;
			}
		}
		#####################################
		# INSERT CODE FOR CONFIGURATOR HERE #
		#####################################
		
		# Check to see if there is a post-configure script
		if(-f "/var/lib/packages/$package/api-post-configure") {
			my $rc = system("/bin/sh /var/lib/packages/$package/api-post-configure");
			if($rc) {
				my %status_vars;
				$status_vars{curr} = "run-configurator";
				$status_vars{status} = "error";
				$status_vars{errorMsg} = 'Script failed';
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
				return 0;
			}
		}
		
		my %status_vars;
		$status_vars{status} = "run-configurator_phase_done";
		$status_vars{errorMsg} = "";
		$status_vars{curr} = "run-configurator";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
					
	} elsif($next_stage_string eq "install-bin-pkgs") {
		# Install the binary package (opkg-server-<package>)
		my ($err, $outref) = $pm->smart_install("opkg-server-$package");
		
		# If there is an error, copy it to the database and note it
		if($err) {
			my %status_vars;
			$status_vars{curr} = "install-bin-pkgs";
			$status_vars{status} = "error";
			$status_vars{errorMsg} = $err;
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
			return 0;
		} else { # Otherwise mark it as done and move on
			my %status_vars;
			$status_vars{status} = "install-bin-pkgs_phase_done";
			$status_vars{errorMsg} = "";
			$status_vars{curr} = "install-bin-pkgs";
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		}	
	} elsif($next_stage_string eq "run-script-post-image") {
		# Check to see if there is an api-post-image script
		if(-f "/var/lib/packages/$package/api-post-image") {
			my $rc = system("/bin/sh /var/lib/packages/$package/api-post-image");
			if($rc) {
				my %status_vars;
				$status_vars{curr} = "run-script-post-image";
				$status_vars{status} = "error";
				$status_vars{errorMsg} = 'Script failed';
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
				return 0;
			} else {
				my %status_vars;
				$status_vars{curr} = "run-script-post-image";
				$status_vars{status} = "run-script-post-image_phase_done";
				$status_vars{errorMsg} = "";
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
			}
		}
	} elsif($next_stage_string eq "run-script-post-clients") {
		# Check to see if there is an api-post-clients script
		if(-f "/var/lib/packages/$package/api-post-clients") {
			my $rc = system("/bin/sh /var/lib/packages/$package/api-post-clients");
			if($rc) {
				my %status_vars;
				$status_vars{curr} = "run-script-post-clients";
				$status_vars{status} = "error";
				$status_vars{errorMsg} = 'Script failed';
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
				return 0;
			} else {
				my %status_vars;
				$status_vars{curr} = "run-script-post-clients";
				$status_vars{status} = "run-script-post-image_clients_done";
				$status_vars{errorMsg} = "";
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
			}
		}
		# Get the list of nodes that should be started now that the server is done
		my @results;
		get_node_package_status_with_node_package($name, $package, \@results, \%options, \@error_strings);
		my $pstatus_ref = pop @results;
		my @client_nodes = split($$pstatus_ref{client_nodes});
		
		# Update the requested value for that node so it will install the package
		for my $client (@client_nodes) {
			my %status_vars;
			$status_vars{requested} = "post-install";
			update_node_package_status_hash(\%options, $client, $package, \%status_vars, \@error_strings);
		}
	} elsif($next_stage_string eq "run-script-post-install") {
		# Check to see if there is an api-post-install script
		if(-f "/var/lib/packages/$package/api-post-install") {
			my $rc = system("/bin/sh /var/lib/packages/$package/api-post-install");
			if($rc) {
				my %status_vars;
				$status_vars{curr} = "run-script-post-install";
				$status_vars{status} = "error";
				$status_vars{errorMsg} = 'Script failed';
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
				return 0;
			} else {
				my %status_vars;
				$status_vars{curr} = "run-script-post-install";
				$status_vars{status} = "installed";
				$status_vars{errorMsg} = "";
				update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);		
			}
		}
	}
		
	# See if everything is done and return the appropriate number
	my @results;
	get_node_package_status_with_node_package($name, $package, \@results, \%options, \@error_strings);
	my $pstatus_ref = pop @results;
	if($$pstatus_ref{requested} ne $$pstatus_ref{curr}) {
		# More work to do
		return 1;
	} else {
		# No more work to do
		return 0;
	}
}

# Takes the 'requested' and 'curr' values and the status of the cluster as a
# whole and decides what work needs to be done for the specified package on a
# compute node.  This means that only the install-bpkg and post-deploy phases
# will be run.
# Parameters: $requested - The phase that has been requested in the database
#             $curr - The curr phase the package has reached
#             $cluster_status - The curr phase the cluster has reached
#             $package - The name of the package being installed
# Returns:    1 - If there is more work to do
#             0 - If the package does not have more work to do right now
sub do_work_node {
	my ($requested,
		$curr,
		%cluster_status,
		$package) = @_;
		
	my $next_stage_num;
		
	# Figure out which phase is next
	if($requested > $curr) {
		$next_stage_num = $curr+1;
	} else {
		return 0;
	}
	my %options;
	my @error_strings;
	
	my $next_stage_string = get_status_name(\%options, $next_stage_num, \@error_strings);
	
	# Start the appropriate phase (if/elsif/else statement)
	
	if($next_stage_string eq "should-be-installed") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{status} = "should-be-installed_phase_done";
		$status_vars{errorMsg} = "";
		$status_vars{curr} = "should-be-installed";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		
	} elsif($next_stage_string eq "run-configurator") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{status} = "run-configurator_phase_done";
		$status_vars{errorMsg} = "";
		$status_vars{curr} = "run-configurator";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
					
	} elsif($next_stage_string eq "install-bin-pkgs") {
		# Install the binary package (opkg-server-<package>)
		my ($err, $outref) = $pm->smart_install("opkg-client-$package");
		
		# If there is an error, copy it to the database and note it
		if($err) {
			my %status_vars;
			$status_vars{curr} = "install-bin-pkgs";
			$status_vars{status} = "error";
			$status_vars{errorMsg} = $err;
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
			return 0;
		} else { # Otherwise mark it as done and move on
			my %status_vars;
			$status_vars{status} = "install-bin-pkgs_phase_done";
			$status_vars{errorMsg} = "";
			$status_vars{curr} = "install-bin-pkgs";
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		}	
		
	} elsif($next_stage_string eq "run-script-post-image") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{curr} = "run-script-post-image";
		$status_vars{status} = "run-script-post-image_phase_done";
		$status_vars{errorMsg} = "";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		
	} elsif($next_stage_string eq "run-script-post-clients") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{curr} = "run-script-post-clients";
		$status_vars{status} = "run-script-post-image_clients_done";
		$status_vars{errorMsg} = "";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		
	} elsif($next_stage_string eq "run-script-post-install") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{curr} = "run-script-post-install";
		$status_vars{status} = "installed";
		$status_vars{errorMsg} = "";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
	}
		
	# See if everything is done and return the appropriate number
	my @results;
	get_node_package_status_with_node_package($name, $package, \@results, \%options, \@error_strings);
	my $pstatus_ref = pop @results;
	if($$pstatus_ref{requested} ne $$pstatus_ref{curr}) {
		# More work to do
		return 1;
	} else {
		# No more work to do
		return 0;
	}
}

# Takes the 'requested' and 'curr' values and the status of the cluster as a
# whole and decides what work needs to be done for the specified package on an
# image.
# Parameters: $requested - The phase that has been requested in the database
#             $curr - The curr phase the package has reached
#             $cluster_status - The curr phase the cluster has reached
#             $package - The name of the package being installed
# Returns:    1 - If there is more work to do
#             0 - If the package does not have more work to do right now
sub do_work_image {
	my ($requested,
		$curr,
		%cluster_status,
		$package) = @_;
		
	my $next_stage_num;
		
	# Figure out which phase is next
	if($requested > $curr) {
		$next_stage_num = $curr+1;
	} else {
		return 0;
	}
	my %options;
	my @error_strings;
	
	my $next_stage_string = get_status_name(\%options, $next_stage_num, \@error_strings);
	
	# Start the appropriate phase (if/elsif/else statement)
	
	if($next_stage_string eq "should-be-installed") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{status} = "should-be-installed_phase_done";
		$status_vars{errorMsg} = "";
		$status_vars{curr} = "should-be-installed";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		
	} elsif($next_stage_string eq "run-configurator") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{status} = "run-configurator_phase_done";
		$status_vars{errorMsg} = "";
		$status_vars{curr} = "run-configurator";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
					
	} elsif($next_stage_string eq "install-bin-pkgs") {
		# Install the binary package (opkg-server-<package>)
		my ($err, $outref) = $pm->smart_install("opkg-client-$package");
		
		# If there is an error, copy it to the database and note it
		if($err) {
			my %status_vars;
			$status_vars{curr} = "install-bin-pkgs";
			$status_vars{status} = "error";
			$status_vars{errorMsg} = $err;
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
			return 0;
		} else { # Otherwise mark it as done and move on
			my %status_vars;
			$status_vars{status} = "install-bin-pkgs_phase_done";
			$status_vars{errorMsg} = "";
			$status_vars{curr} = "install-bin-pkgs";
			update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		}	
		
	} elsif($next_stage_string eq "run-script-post-image") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{curr} = "run-script-post-image";
		$status_vars{status} = "run-script-post-image_phase_done";
		$status_vars{errorMsg} = "";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		
	} elsif($next_stage_string eq "run-script-post-clients") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{curr} = "run-script-post-clients";
		$status_vars{status} = "run-script-post-image_clients_done";
		$status_vars{errorMsg} = "";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
		
	} elsif($next_stage_string eq "run-script-post-install") {
		# Nothing to do for this stage
		
		my %status_vars;
		$status_vars{curr} = "run-script-post-install";
		$status_vars{status} = "installed";
		$status_vars{errorMsg} = "";
		update_node_package_status_hash(\%options, $name, $package, \%status_vars, \@error_strings);
	}
		
	# See if everything is done and return the appropriate number
	my @results;
	get_node_package_status_with_node_package($name, $package, \@results, \%options, \@error_strings);
	my $pstatus_ref = pop @results;
	if($$pstatus_ref{requested} ne $$pstatus_ref{curr}) {
		# More work to do
		return 1;
	} else {
		# No more work to do
		return 0;
	}
}
