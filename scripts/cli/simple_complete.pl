#!/usr/bin/perl -w

# $Id$
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                  All rights reserved.
#
# This script is the simple case to wait for the user to 
# type continue to quit.  The script is made to be used
# in conjunction with the main_cli script.  When the CLI
# needs to wait for the nodes to boot up and load their
# image, this script is one of the options to use to
# determine when that has completed.

$|++;

my $input = " ";
while ($input ne "continue") {
    print "*************************************************************\n" .
    "* Before continuing, network boot all of your nodes.        *\n" .
    "* Once they have completed installation, reboot them from   *\n" .
    "* the hard drive. Once all the machines and their ethernet  *\n" .
    "* adaptors are up, type \'continue\' and press Enter.         *\n" .
    "* If you are not ready to continue yet, hit Ctrl-C to exit. *\n" .
    "*************************************************************\n";
    $input = <STDIN>;
chomp $input;
}

exit 0;
