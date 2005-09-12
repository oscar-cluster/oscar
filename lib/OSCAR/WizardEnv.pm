package WizardEnv;

# $Id$ 
# 
# Descr: Import any new system ENV additions/changes to the Wizard's ENV.
#
# Copyright (c) 2005 Oak Ridge National Laboratory.
#                    All rights reserved.
#
#
#  Notes:
#   N1) Ignore a few specific ENV Vars
#   N2) Only add/replace ENV, don't remove anything from existing ENV.
#   N3) Blindly update values for any existing ENV vars
#   N4) Use '--login' to guarantee all system files are processed
#
#--------------------------------------------------------------------

use IPC::Open2;
use Carp;
use warnings;
use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
@EXPORT = qw(update_env);


my $bash_cmd = "/bin/bash";
my $echo_cmd = "/bin/echo";
my $env_cmd  = "/bin/env";
my %ENV_IGNORE = (PWD=>1, OLDPWD=>1, SHLVL=>1, _=>1, USER=>1, USERNAME=>1,
                  LS_COLORS=>1);

#   Input: n/a
#  Output: %ENV
#  Return: list of modified env items [possibly empty]
sub update_env
{
	my @modified_env = ();
	my $magicstr = "___MaGiCsTrInG-OSCAR::WizardEnv___";

	 # Sanity checks
	croak "Error: '$bash_cmd' not executable.\n" if( ! -x $bash_cmd );
	croak "Error: '$echo_cmd' not executable.\n" if( ! -x $echo_cmd );
	croak "Error: '$env_cmd' not executable.\n"  if( ! -x $env_cmd );

	my ($rh, $wh);  # Handle autovivification 

    # Use '--login' to guarantee all system files are processed
	my $pid = open2($rh, $wh, "$bash_cmd", "--login") or croak "Error: $!\n";


	 # TODO: May need to trap SIGPIPE for child, see IPC::Open2(3pm)
	 # Print our delimiter all output above this was from system,
	 #  e.g., /etc/profile.d/ssh-oscar.sh gens *lots* of output :-|
	print $wh "/bin/echo $magicstr\n";


	 # TODO: May need to trap SIGPIPE for child, see IPC::Open2(3pm)
	print $wh "$env_cmd";
	close($wh);

	my @rslt = <$rh>;
	close($rh);
	chomp(@rslt);

	waitpid($pid, 0); # reap child (if needed?)


	# Remove any leading stuffo (prior to our sentinal)
	while ( ($_ = shift(@rslt)) !~ /$magicstr/ ) {
		print "WizardEnv: removed($_)\n" if( $ENV{DEBUG_OSCAR_WIZARD} );
		next;
	}
	print "WizardEnv: removed($_)\n" if( $ENV{DEBUG_OSCAR_WIZARD} );


	foreach my $r (@rslt) {
		my ($key, $val) = split/=/, $r;
    
		if( ! $ENV_IGNORE{$key} ) {

			next if( defined($ENV{$key}) && $ENV{$key} eq $val ); 
    
			print "Update environment: ENV{$key}\n" unless( $ENV{QUIET_OSCAR_WIZARD} );
			print "  $key=$val\n\n" if( $ENV{DEBUG_OSCAR_WIZARD} 
			                          && ! $ENV{QUIET_OSCAR_WIZARD} );
			$ENV{$key} = $val;
			push @modified_env, $key;
		}
	}
	return @modified_env;
}

1;

# vim:tabstop=4:shiftwidth=4

