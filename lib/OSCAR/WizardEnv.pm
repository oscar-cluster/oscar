package WizardEnv;

# $Id$ 
# 
# Descr: Import any new system ENV additions/changes to the Wizard's ENV.
#
# Copyright (c) 2005 Oak Ridge National Laboratory.
#                    All rights reserved.
#
#
#--------------------------------------------------------------------
#  Notes:
#   N1) Ignore a few specific ENV Vars
#   N2) Only add/replace ENV, don't remove anything from existing ENV.
#   N3) Blindly update values for any existing ENV vars
#   N4) Future/idea: add this to OPKG meta-data and auto gen via LibOPKG.
#
#  Comments:
#   * In future an idea to better support such changes is to
#     improve the "meta data" about an OPKG, listing: 
#     (a) env vars and values, (b) services (start/stop runlevel), etc.
#     This is not to say duplicate ENV setup, rather we could/would 
#     automatically generate things for the OPKG author, in keeping
#     with having them do less and the system do more with the advantage 
#     that this information can help the system make better 
#     decisions/additions/etc., e.g., LibOPKG.
#     Discussed some of this with Jeff S., seemed reasonable.
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
my $env_cmd  = "/bin/env";
my %ENV_IGNORE = (PWD=>1, OLDPWD=>1, SHLVL=>1, _=>1, USER=>1, USERNAME=>1,
                  LS_COLORS=>1);

#   Input: n/a
#  Output: %ENV
#  Return: list of modified env items [possibly empty]
sub update_env
{
	my @modified_env = ();

	 # Sanity checks
	croak "Error: '$bash_cmd' not executable.\n" if( ! -x $bash_cmd );
	croak "Error: '$env_cmd' not executable.\n" if( ! -x $env_cmd );

	my ($rh, $wh);  # Handle autovivification 
	my $pid = open2($rh, $wh, "$bash_cmd") or croak "Error: $!\n";

	 # TODO: May need to trap SIGPIPE for child, see IPC::Open2(3pm)
	print $wh "$env_cmd";
	close($wh);

	my @rslt = <$rh>;
	close($rh);
	chomp(@rslt);

	waitpid($pid, 0); # reap child (if needed?)

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

