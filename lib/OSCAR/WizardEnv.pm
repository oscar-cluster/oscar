package OSCAR::WizardEnv;

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
#   N3) Blindly update values for any existing ENV vars, sometime overwriting.
#   N4) Use '--login' to guarantee all profile related files are processed
#       and explicitly source the bashrc related files.  Otherwise,
#       only interactive shells get the bashrc related contents and in some
#       cases we'd remove things from the run-time ENV, e.g., PATH with
#       changed via bashrc files.
#   N5) I convert multi-line EnvVars to single-lines, e.g., TERMCAP,
#       even if we ignore that EnvVar in order to properly remove/ignore.
#
#
#   TODO: The update_env() rtn has grown quite a bit and should 
#         probably be broken into smaller pieces.
#--------------------------------------------------------------------

use IPC::Open3;
use Carp;
use warnings;
use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
@EXPORT = qw(update_env);


my @PATHS= qw(/bin /usr/bin /sbin /usr/sbin);

 # bashrc files processed in order of occurance in array
my @BASHRC = ("/etc/bash.bashrc", "/etc/bashrc", "$ENV{HOME}/.bashrc");

my %ENV_IGNORE = (PWD=>1, OLDPWD=>1, SHLVL=>1, _=>1, USER=>1, USERNAME=>1,
                  LS_COLORS=>1, PS1=>1, TERMCAP=>1);

# Debug Levels
use constant DBG_OFF  => 0;
use constant DBG_LOW  => 1;
use constant DBG_MED  => 2;
use constant DBG_HIGH => 3;
my $DEBUG = DBG_OFF;


#   Input: n/a
#  Output: %ENV
#  Return: list of modified env items [possibly empty]
sub update_env
{
	my @modified_env = ();
	my $magicstr = "___MaGiCsTrInG-OSCAR::WizardEnv___";
	my ($bash_cmd, $echo_cmd, $env_cmd);

	croak "Error: 'bash' not found " 
	   if( not defined($bash_cmd = find_cmd("bash")) );

	croak "Error: 'echo' not found " 
	   if( not defined($echo_cmd = find_cmd("echo")) );

	croak "Error: 'env' not found " 
	   if( not defined($env_cmd = find_cmd("env")) );


	# Set the DEBUG flag based on the old & new (multi-level verbose)
	# Keeping the previous flags around in case anyone actually used them.
	# ORDER IS IMPORTANT HERE!!!
	
	if( defined($ENV{DEBUG_OSCAR_WIZARD}) ) {
		$DEBUG = $ENV{DEBUG_OSCAR_WIZARD};
	}		

	if( defined($ENV{DEBUG_OSCAR_WIZARD_PARANOID}) 
	    and     $ENV{DEBUG_OSCAR_WIZARD_PARANOID} ) {
		$DEBUG = DBG_HIGH;
	}

	if( defined($ENV{QUIET_OSCAR_WIZARD}) 
	    and     $ENV{QUIET_OSCAR_WIZARD} ) {
		$DEBUG = DBG_OFF;   # Overrides all other flags
	}

	# this hack is needed for SuSE, otherwise it won't source the
	# scripts in /etc/profile.d/ [EF, 20.07.2006]
	delete $ENV{PROFILEREAD} if exists($ENV{PROFILEREAD});

	my ($rh, $wh);  # Handle autovivification 


	 # 1) Use the '--login' option in order to have profile related file 
	 #    sourced
	
	my $pid = open3($wh, $rh, 0, "$bash_cmd", "--login") or croak "Error: $!\n";


	 # TODO: May need to trap SIGPIPE for child, see IPC::Open3(3)
	 #       when writing to the pipe (write handle).
	 #
	 #       NOTE: Using open3() now to trap STDERR, arg order differs
	 #       from open2()!
	 #
	 # 2) We set PS1 to fake out some scripts that check for interactive
	 #    shells via this value being set, e.g., Debian's /etc/bash.bashrc
	 #    We have PS1 in %ENV_IGNORE so change won't propogate to cur ENV.
	 #
	 # 3) Then we manually source the bashrc related files (@BASHRC).
	 #    Note, we must check for existence, then source b/c naming differs.
	
	print $wh "export PS1=foobar\n";
	foreach my $rcfile (@BASHRC) {
		print $wh "if [ -e $rcfile ] ; then source $rcfile; fi\n";
	}

         # 3bis) remove exported functions. Those are printed on multiple lines
         #    and will be badly handeled.
        print $wh "export -nf \$(declare -F|grep fx|cut -d' ' -f3)\n";

	 # 4) Print our delimiter, all output above this is from system,
	 #   e.g., /etc/profile.d/ssh-oscar.sh gens *lots* of output :-|
	 #
	 # TODO: May need to trap SIGPIPE for child, see IPC::Open3(3)
	 #
	 #       NOTE: Using open3() now to trap STDERR, arg order differs
	 #       from open2()!
	 
	print $wh "/bin/echo $magicstr\n";

	 # 5) Get a listing of the new shell's ENV.
	 
	print $wh "$env_cmd";
	close($wh);

	 # 6) Drain the read pipe from shell and then do post-processing
	 #    to determine differences/additions to ENV and update cur ENV.
	 
	my @rslt = <$rh>;
	close($rh);
	chomp(@rslt);

	waitpid($pid, 0); # reap child (if needed?)


	 # Remove any leading stuffo (prior to our sentinal)
	while ( ($_ = shift(@rslt)) !~ /$magicstr/ ) 
	{
	
		print "WizardEnv: removed($_)\n" if($DEBUG >= DBG_HIGH );
		next;
	}
	print "WizardEnv: removed($_)\n" if( $DEBUG >= DBG_HIGH );


	 # Convert multi-line EnvVars to single-line, noticed b/c of
	 # TERMCAP when using screen.  We also ignore TERMCAP but need
	 # all on one line to actually get it out of the way. ;)

	@rslt = multi2singleline(@rslt);

	foreach my $r (@rslt) {
		my ($key, $val) = split(/=/, $r, 2);   # Limit to 2 tokens!

		if( ! $ENV_IGNORE{$key} ) {

			next if( defined($ENV{$key}) && $ENV{$key} eq $val ); 
 
			print "Update environment: ENV{$key}\n" if( $DEBUG >= DBG_LOW );
			print "  $key=$val\n\n" if( $DEBUG >= DBG_MED );

			# To see actual differential (for the paranoid among us)
			if( $DEBUG >= DBG_HIGH )
			{
				# To avoid unintialized warnings when not prev. exist
				my $orig = (defined($ENV{$key}))? $ENV{$key} : ""; 
				print "  ORIG: $key=$orig\n";
				print "   NEW: $key=$val\n\n";
			}

			$ENV{$key} = $val;
			push @modified_env, $key;
		}
	}
	return @modified_env;
}


# 
# TJN: (9/14/05) Fix/hack for multi-line EnvVars,
#  Converts multi-line EnvVars into single-lines, e.g., TERMCAP
#  Must use for() instead of more commond foreach() so we can pluck 
#  items from middle of array/stack.
#
sub multi2singleline
{
	my @env = @_;
	my (@keep, $tmp); 

	for(my $i=0; $i < scalar(@env); $i++) {
		push(@keep, $env[$i]);

		if( $env[$i] =~ /\\$/ ) {
			pop(@keep);

			while( $env[$i] =~ /\\$/ ) {
				chomp($env[$i]);
				$tmp .= $env[$i];
				$i++;
			}

			$tmp .= $env[$i];
			if( $DEBUG >= DBG_HIGH ) {
				print "WizardEnv: multi-line EnvVar converted to:\n  $tmp\n\n"; 
			}

			push(@keep, $tmp);
		}
	}

	return(@keep);
}

sub find_cmd 
{
	my $target = shift;
	my $cmd = undef;

	foreach my $path (@PATHS) {
		if( -x "$path/$target" ) {
			$cmd = $path . "/" . $target;
			last;
		}
	}

	return( ( defined($cmd) )?  $cmd : undef );
}

1;

# vim:tabstop=4:shiftwidth=4

