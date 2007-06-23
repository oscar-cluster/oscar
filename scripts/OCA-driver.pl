#!/usr/bin/perl
#
# Dummy driver program
#
# Relevant EnvVars:
#   OSCAR_HOME
#   DEBUG_OCA_OS_DETECT
#

use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Logger;
use Data::Dumper;
use Carp;


 ############################################################
 #
 # (Check#1)
 # Framework: OS_Detect 
 #
 ############################################################
oscar_log_section("OS_Detect");

use OSCAR::OCA::OS_Detect;
my $os = OSCAR::OCA::OS_Detect::open();

if( not defined($os) ) {
	carp "Error: OS_Detect open failed."; 
} else {
	oscar_log_subsection( " Dump...\n" . Dumper($os) );
	oscar_log_subsection( "distro_flavor=(" . $os->{distro_flavor} . ")" );
	oscar_log_subsection( "distro_version=(" . $os->{distro_version} . ")" );
	oscar_log_subsection( "arch=(" . $os->{arch} . ")" );
}


 ############################################################
 #
 # (Check#2)
 # Framework: RM_Detect 
 #
 ############################################################
oscar_log_section("RM_Detect");

use OSCAR::OCA::RM_Detect;
my $rmgr = OSCAR::OCA::RM_Detect::open();

if( not defined($rmgr) ) {
	carp "Error: RM_Detect open failed."; 
} else {
	oscar_log_subsection( " Dump...\n" . Dumper($rmgr) );
}


  ############################################################
  #
  # (Check#3)
  # Framework: Sanity_Check
  #
  ############################################################
oscar_log_section("Sanity_Check");

use OSCAR::OCA::Sanity_Check;
my $sanity = OSCAR::OCA::Sanity_Check::open();

if( not defined($sanity) ) {
	carp "Error: Sanity_Check open failed.";
} else {
	oscar_log_subsection( " Dump...\n" . Dumper($sanity) );
}
 

# 
# TJN: (4/19/06) Until I commit the Cluster_Ops framework, I'm
#    going to comment this section out too.
#
#  ############################################################
#  #
#  # (Check#4)
#  # Framework: Cluster_Ops
#  #
#  ############################################################
# oscar_log_section("Cluster_Ops");
# 
# use OSCAR::OCA::Cluster_Ops;
# my $cops = OSCAR::OCA::Cluster_Ops::open();
# 
# if( not defined($cops) ) {
# 	carp "Error: Cluster_Ops open failed."; 
# } else {
# 	oscar_log_subsection( " Dump...\n" . Dumper($cops) );
# }
# 
# 
