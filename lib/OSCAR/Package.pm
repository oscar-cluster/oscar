package OSCAR::Package;

#   $Id: Package.pm,v 1.5 2002/02/20 00:22:53 sdague Exp $

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

#   Copyright 2001-2002 International Business Machines
#                       Sean Dague <japh@us.ibm.com>

use strict;
use vars qw(@EXPORT $VERSION $RPM_TABLE $RPM_POOL @COREPKGS %PHASES);
use base qw(Exporter);
use File::Basename;
use File::Copy;
use Carp;

@EXPORT = qw(list_pkg run_pkg_script run_pkg_script_chroot rpmlist);

# Trying to figure out the best way to set this.
$RPM_POOL = $ENV{OSCAR_RPMPOOL} || '/tftpboot/rpm';

$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

# This defines which packages are core packages (i.e. MUST be installed before
# the wizard comes up)
@COREPKGS = qw(c3 sis);

# The list of phases that are valid for package install.  For more info, please
# see the developement doc

%PHASES = (
           post_server_install => 'post_server_install',
           post_rpm_install => 'post_rpm_install',
           post_clients => 'post_clients',
           post_install => 'post_install',
          );


#
# list_pkg - this returns a list of packages.
#          you may specify "core" or "noncore" as the first
#          argument to get a list of core or noncore packages instead of all packages
#
#          Basic theory, if you want core, return the core list.  If you want 
#          something else, read the package directory, if 'noncore' through away
#          core packages as you hit them.
#

sub list_pkg {
    my $type = shift;
    my @pkgs = ();
    if($type eq "core") {
        @pkgs = @COREPKGS;
    } else {
	opendir(PKGDIR,"$ENV{OSCAR_HOME}/packages") or (carp("Couldn't open $ENV{OSCAR_HOME}/packages for reading"), return undef);
        while($_ = readdir(PKGDIR)) {
            unless (/^(\.|CVS|Make)/) {
                my $pkg = $_;
                chomp($pkg);
                unless($type eq "noncore" and _is_core($pkg)) {
                    push @pkgs, $pkg;
                }
            }
        }
        close(PKGDIR);
    }
    return @pkgs;
}

sub _is_core {
    my $pkg = shift;
    for (@COREPKGS) {
        if($pkg eq $_) {
            return 1;
        }
    }
    return 0;
}

#
# run_pkg_script - runs the package script for a specific package
#


sub run_pkg_script {
    my ($pkg, $phase, $verbose) = @_;
    my $scriptname = $PHASES{$phase};
    if(!$scriptname) {
        carp("No such phase '$phase' in OSCAR package API");
        return undef;
    }
    my $script = $ENV{OSCAR_HOME} . "/packages/" . $pkg . "/scripts/" . $scriptname;
    if(-e $script) {
	print "About to run $script for $pkg\n" if($verbose); 
        my $rc = system($script);
        if($rc) {
            my $realrc = $rc >> 8;
            carp("Script $script exitted badly with exit code '$realrc'");
            return 0;
        }
        return 1;
    } 
    return 1;
}

sub run_pkg_script_chroot {
    my ($pkg, $dir) = @_;
    my $scriptname = $PHASES{post_rpm_install};
    if(!$scriptname) {
        carp("No such phase 'post_rpm_install' in OSCAR package API");
        return undef;
    }
    my $script = $ENV{OSCAR_HOME} . "/packages/" . $pkg . "/scripts/" . $scriptname;
    if(-e $script) {
        run_in_chroot($dir,$script) or (carp "Script $script failed", return undef);
    }
    return 1;
}

sub run_in_chroot {
    my ($dir, $script) = @_;
    my $base = basename($script);
    my $nscript = "$dir/tmp/$base";
    copy($script, $nscript) or (carp("Couldn't copy $script to $nscript"), return undef);
    chmod 0755, $nscript;
    !system("chroot $dir /tmp/$base") or (carp("Couldn't run /tmp/$script"), return undef);
    unlink $nscript or (carp("Couldn't remove $nscript"), return undef);
    return 1;
}

sub rpmlist {
    my ($pkg, $type) = @_;
    my $listfile = ($type eq "client") ? "client.rpmlist" : "server.rpmlist";
    my $file = "$ENV{OSCAR_HOME}/packages/$pkg/$listfile";
    my @rpms = ();
    open(IN,"<$file") or carp("Couldn't open package list file $file for reading!");
    while(<IN>) {
        # get rid of comments
        s/\#.*//;
        if(/(\S+)/) {
            push @rpms, $1;
        }
    }
    close(IN);
    return @rpms;
}

1;
