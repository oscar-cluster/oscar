#!/usr/bin/perl -w

# $Id$
#
# Copyright (c) 2007 Oak Ridge National Laboratory
#                    All Rights Reserved
#
# This is a simple program to interface with the package set mananger

use strict;
use lib ".", "$ENV{OSCAR_HOME}/lib", "$ENV{OSCAR_HOME}/lib/Qt";
use pkgparser;
use Data::Dumper;
use OSCAR::Logger;
use Qt::SelectorUtils;
use Qt::SelectorTable;
use Term::Complete;

OSCAR::Logger::oscar_log_section("Beginning the OPKG Set Selector");

OSCAR::Logger::oscar_log_subsection("Populating list of package sets");

our @sets = get_package_sets();

my $help =
"###############################################################################\n" .
"# select-set <packageSet> - Select a packge set to be installed\n" .
"# unselect-set <packageSet> - Select a package set to be installed\n" .
"# list-sets - Lists the package sets\n" .
"# describe <packageSet> - Shows the packages in a package set\n" .
"# help - Prints this message\n" .
"# quit/exit - Quits the package set selector and continues with the next step\n" .
"###############################################################################\n";

my $continue = 1;
my @completion_list = qw( select-set unselect-set list-sets describe help quit exit );
my $prompt = "\nselector> ";

while($continue) {
	my $response = Complete($prompt, @completion_list);
	$continue = processInput($response);
}

#print Dumper(@sets);

#foreach my $set (@sets) {
#	my @packages = get_packages($set);
#
#	print "------$set-------\n" . Dumper(@packages);
#}


sub processInput {
	#Change the response from a scalar to an array
    my @response = split(' ', shift);

    my $command = shift(@response);
    my $requested;

    #By default, ask for help
    if(!defined $command)
    {
        $command = "help";
    }

    if($command eq "select-set") {
		OSCAR::Logger::oscar_log_subsection("Select set: $response[1]");
    } elsif ($command eq "unselect-set") {
		OSCAR::Logger::oscar_log_subsection("Unselect set: $response[1]");
    } elsif ($command eq "list-sets") {
    	printSets();
    } elsif ($command eq "describe") {
    	my $packageSet = shift(@response);
    	printPackages($packageSet);
    } elsif ($command eq "help") {
		print "Usage:\n" .
			"select-set <setname>\tSelects a set of packages\n" .
			"unselect-set <setname>\tUnselect a set of packages\n" .
			"list-sets\t\tLists the pakcage sets\n" . 
			"describe <setname>\tShows the packages in a packge set\n" .
			"help\t\t\tShows this message\n" .
			"quit | exit\t\tExits the package set manager\n";
    } elsif ($command eq "quit" || $command eq "exit") {
    	return 0;
    }
    
    return 1;
}

sub printSets {
	our @sets;
	print "------Package Sets--------\n";
	foreach my $set (@sets) {
		print $set . "\n";
	}
}

sub printPackages {
	my $packageSet = shift;
	my @packages = get_packages($packageSet);
	print "------Packages in $packageSet------\n";
	foreach my $package (@packages) {
		print $package . "\n";
	}
}
