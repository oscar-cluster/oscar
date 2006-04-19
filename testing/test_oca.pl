#!/usr/bin/env perl
# Wed Apr 19 2006  15:27:20PM    Thomas Naughton  <naughtont@ornl.gov>
#
# Descr: A collection of tests for the OSCAR Component Architecture (OCA).
#        These are basic tests to include Perl syntax, etc.
#
#  Note: We try to assume as little as possible about the environment.
# 

use POSIX;

my $perl_bin = `which perl`;  # Use default perl from current PATH
chomp($perl_bin);
if( not -x $perl_bin ) {
	die "Error: $perl_bin is not executable ... very bad!\n";
}

 #
 # Check OSCAR_HOME
 #
if( not defined($ENV{OSCAR_HOME}) ) {
	die "Error: OSCAR_HOME not defined\n"; 
}
print "Good - OSCAR_HOME defined.\n";

 #
 # Check OSCAR_HOME dir exists 
 #
if( not -d $ENV{OSCAR_HOME} ) {
	die "Error: OSCAR_HOME not a dir - OSCAR_HOME=$ENV{OSCAR_HOME}\n";
}
print "Good - $ENV{OSCAR_HOME} is a directory.\n";
print "Now can start using OSCAR libs, to include pretty-print module\n\n"; 



 ###############################################################
 #
 # OSCAR_HOME looks good, include a few libs
 #
 ###############################################################
 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
use lib "$ENV{OSCAR_HOME}/lib/";
use OSCAR::Logger;


 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

 # Backup or original dir location & change to $OSCAR_HOME/lib/ 
my $origdir = getcwd();
chdir("$ENV{OSCAR_HOME}/lib");
 
 #
 # OSCAR_HOME is good, start checking OCA
 #
my $oca_dir = "$ENV{OSCAR_HOME}/lib/OSCAR/OCA";

 #
 # Check OCA dir exists
 #
if( not -d "$oca_dir" ) {
	die "Error: OCA not a dir - OCA=$oca_dir\n";
}


 #
 # OCA looks good, so lets start digging through the frameworks...
 # 
opendir(OCA_DIR, $oca_dir) or "Error: Unable to open OCA - $!\n";
my @tmp = readdir(OCA_DIR);
my @frameworks = grep( !/^\.{1,2}$/ && !/^\.svn$/ && -d "$oca_dir/$_", @tmp);

oscar_log_section("The OCA frameworks that will be checked:");

foreach my $frmwrk (@frameworks) {
	oscar_log_subsection("$frmwrk");
}


#
# FIXME: TODO I should just build a large list of all files to syntax check
#  and then look through the list.
# 


 #
 # Special case: just check OCA.pm
 #
oscar_log_section("Perl syntax check of top-level OCA");
my $msg = check_perl_syntax("$ENV{OSCAR_HOME}/lib/OSCAR/OCA.pm"); 
oscar_log_subsection("OCA.pm: $msg");

 # WALK Framework/Components to see if they pass syntax, '-c'
 # add a pass with strict and warning and without them, e.g.,
 #   1) no strict, no warnings
 #   2) strict, warnings
 #   3) strict, no warnings
 #   4) no strict, warnings



oscar_log_section("Perl syntax check of OCA frameworks/components");


foreach my $frmwrk (@frameworks) {
	my $curpath = $ENV{PWD};

	my $msg = check_perl_syntax("$oca_dir/$frmwrk.pm"); 
	oscar_log_subsection("$frmwrk.pm: $msg");

	# FIXME: This should be in a sub-rtn
	opendir(DIR, "$oca_dir/$frmwrk/") or "Error: Unable to open '$frmwrk' - $!\n";
	my @tmp = readdir(DIR);
	my @comps = grep( !/^\.{1,2}$/ && !/^\.svn$/ && /\.pm$/ && -e "$oca_dir/$frmwrk/$_", @tmp);

	 # NOTE: We dont' have to append the '.pm' b/c we can grep out just
	 #       these files, as opposed to the -d approach.
	foreach my $comp (@comps) {
		#print "DBG: $oca_dir/$frmwrk/$comp\n";
		my $msg = check_perl_syntax("$oca_dir/$frmwrk/$comp"); 
		oscar_log_subsection("   |->  $comp.pm: $msg");
	}
	print "\n";
}

 
 # FIXME: Need some way to have frameworks specify this so that we
 #        can query the Framework and then check all its components
 #        to make sure the method is in EXPORT() or at worst defined.
 #        I don't think we can instantiate methods b/c that may not
 #        make since for all components on the given testing platform.
oscar_log_section("TODO: Check component required methods for frameworks"); 
oscar_log_subsection("TODO: walk over all components to check required methods");
# WALK over all the published (required) methods that the Component must 
# support, e.g., OS_Detect::$compname::detect_dir(), etc....
print "\n";


 # Return to our original dir upon entry
chdir($origdir);


#
#  Input: perl file to syntax check ($file) with fully qualified path
# Return: result string from syntax check
#
sub check_perl_syntax
{
	my $file = shift;

	 # Return early and loudly if the file doesn't exist!
	return("Error: file not found - $file") unless( -e $file);

	my $cmd = "$perl_bin -c $file 2>&1";
	my @rslt = eval { my $r = `$cmd`; return( ("$?", "$r") ) };
	my $rc = shift @rslt;
	my $msg = shift @rslt;

	# FIXME: I don't like this but it is now working...if you run it from
	# $OSCAR_HOME/lib/;  otherwise the search paths get off?
	if( $rc ) {
		#print "Error: $msg \n";
		return("syntax ERROR  \n  $msg");
	} else {
		#print "syntax OK\n";
		return("syntax OK");
	}
}

