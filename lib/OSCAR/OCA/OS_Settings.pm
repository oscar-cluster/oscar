# Copyright (c) 2008 Paul Greidanus <paul@majestik.org>
#                    All rights reserved
#		- New framework to set specific settings rationally
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OSCAR::OCA::OS_Settings;

use strict;
use vars qw(@EXPORT $LOCAL_NODE_OS);
use base qw(Exporter);
use Data::Dumper;

my $verbose = $ENV{OSCAR_VERBOSE};

# readfile() does the "heavy lifting" of reading the configuration files
# 

#Should this be converted to lib/OSCAR/ConfigFile.pm

sub readfile ($$) {
	my $file = shift();
	my $config = shift();
	open(CONFIG,"$ENV{OSCAR_HOME}/lib/OSCAR/OCA/OS_Settings/" . $file) or return $config;
	while (<CONFIG>) {
		chomp;
		next if /^\s*\#/;
		next unless /=/;
		my ($key, $variable) = split(/=/,$_,2);
		$variable =~ s/(\$(\w+))/$config->{$2}/g;
		$config->{$key} = $variable;
	}
	return $config;
}

# getconf reads the configuration files for default, distro, distro with version
# and then the complete ident string.  For example it will read:
# distro -> centos -> centos5 -> linux-x86_64-centos-5-0
# if any are missing, they will be ignored.

sub getconf () {
	my $config = {};
	my $os = OSCAR::OCA::OS_Detect::open();
	my $distro = $os->{distro};
	my $version = $os->{distro_version};
	my $ident = $os->{ident};
	readfile("default", $config);
	readfile("$distro", $config);
	readfile("$distro$version", $config);
	# This line specifies very specific OS versions, and should
	# never be used if possible.
	readfile("$ident", $config);
	return $config;
}

# getitem returns a config item.  It is called with a string containing 
# a configuration item.  It returns the string specified in the configuration
# files.
sub getitem ($) {
	my $request = shift @_;
	my $config = getconf();
	if ($verbose) { print "Called getitem with " . $request . " and returning " . $config->{$request} . "\n" };
	if ($verbose) { print Dumper($config) };
	if ( $config->{$request} ) {
		return $config->{$request};
		} else {
		# Unclear if we should die, or return undef here..
		if ($verbose) { print "We did not find a config option for " . $request . " please check the configuration files in lib/OSCAR/OCA/OS_Settings\n" };
		return undef;
		}
	}

1;
