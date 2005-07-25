#!/usr/bin/perl
#
# Dummy driver program for OSCAR Component Architecture (OCA).
#
# Related EnvVars:
#   OSCAR_HOME
#   DEBUG_OCA_OS_DETECT


use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::OCA::OS_Detect;
use Data::Dumper;

die "Cannot continue\n" if( ! OSCAR::OCA::OS_Detect::open() );

my $ident = $OS_Detect->{query}();
print Dumper($ident);
