package OSCAR::Env;

# Copyright (c) 2007 Oak Ridge National Laboratory.
#                         All rights reserved.
#
#   $Id: Env.pm 5585 2006-12-27 00:16:54Z valleegr $

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use Cwd qw(chdir cwd);

use OSCAR::Logger;
use File::Basename;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            oscar_home_env
            );

#
# Check for OSCAR_HOME environment variable and its correctness
# in the /etc/profile.d directory
#
sub oscar_home_env {
    my $ohome = &cwd();
    if (dirname($0) ne ".") {
    carp("You MUST execute the program from within the OSCAR top level directory!\n");
    }

    # Two situations now: we are using an RPM based distro therefore we need to update /etc/profile.d/, or we are using a Debian-like distro and therefore, we do not have a /etc/profile.d/ folder (see Debian policies for more information), and we update /root/.bashrc
    # First case: Debian-like distro
    my $dir = "/etc/profile.d/";
    if (!-d $dir) {
        my $ret = `grep OSCAR /root/.bashrc`;
        # We update /etc/.bashrc only if we did not do it before
        my $cmd4deb;
        if ($ret eq "") {
             $cmd4deb = "echo \"OSCAR_HOME=$ohome\nexport OSCAR_HOME\n\" >> /root/.bashrc";
             system ($cmd4deb);
        }
    $ENV{OSCAR_HOME} = $ohome;
    }
    # Second case RPM based distros
    else {
        # do profile.d files already exist?
        my ($dir_csh, $dir_sh) = &profiled_files_read();
        if ($dir_csh ne $dir_sh) {
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
            print "The /etc/profile.d/oscar_home.{csh,sh} files point to\n";
            print "different \$OSCAR_HOME environment variables!\n";
            print "Fix or delete them and rerun this program!\n";
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
            exit 1;
        }
        # is there another OSCAR installation around?
        if ($dir_sh && ($dir_sh ne $ohome)) {
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
            print "The /etc/profile.d/oscar_home.{csh,sh} files already \n";
            print "exist and point to a different OSCAR installation!\n";
            print "If you want to DELETE the other OSCAR installation (!!!)\n";
            print "you should do:\n";
            print "   cd $dir_sh\n";
            print "   scripts/start_over\n";
            print "Then rerun this script.\n";
            print "ATTENTION: The steps described above will remove all OSCAR\n";
            print "packages and delete all defined cluster nodes!\n";
            print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
            exit 1;
        }
        # set environment variable OSCAR_HOME
        if ($ENV{OSCAR_HOME} ne $ohome) {
            oscar_log_subsection("Setting env variable OSCAR_HOME to $ohome");
            $ENV{OSCAR_HOME} = $ohome;
        }
        # write profile.d files
        if (!$dir_sh || !$dir_csh) {
            oscar_log_subsection("Generating ".
                                 "/etc/profile.d/oscar_home.{sh,csh} files.");
            &profiled_files_write("OSCAR_HOME", $ohome);
            &profiled_files_write("OSCAR_PACKAGE", "/usr/lib/oscar/packages");
            &profiled_files_write("OSCAR_TEST", "/usr/lib/oscar/testing");
        }
    }
}

sub profiled_files_read {
    my ($dir_csh, $dir_sh);
    local *IN;
    my $file = "/etc/profile.d/oscar_home.csh";
    if (-f $file) {
    open IN, "$file" or
        carp("Could not open $file: $!");
    while (<IN>) {
        if (/^setenv OSCAR_HOME (\S+)$/) {
        $dir_csh = $1;
        }
    }
    close IN;
    }
    $file = "/etc/profile.d/oscar_home.sh";
    if (-f $file) {
    open IN, "$file" or
        carp("Could not open $file: $!");
    while (<IN>) {
        if (/^OSCAR_HOME=(\S+)$/) {
        $dir_sh = $1;
        }
    }
    close IN;
    }
    return ($dir_csh, $dir_sh);
}

sub profiled_files_write ($$) {
    my ($env_var, $dir) = @_;
    my $file = "/etc/profile.d/oscar_home.csh";
    if ( -e $file ){
        my @check = `grep $env_var $file`;
        return if @check;
    }
    open OUT, "> $file" or
        carp("Could not write file $file: $!");
    print OUT "setenv $env_var $dir\n";
    close OUT;
    chmod 0755, $file;
    $file = "/etc/profile.d/oscar_home.sh";
    if ( -e $file ){
        my @check = `grep $env_var $file`;
        return if @check;
    }
    open OUT, "> $file" or
        carp("Could not write file $file: $!");
    print OUT "$env_var=$dir\n";
    print OUT "export $env_var\n";
    close OUT;
    chmod 0755, $file;
}

1;
