package SystemInstaller::Image;

#   $Header: /home/user5/oscar-cvsroot/oscar/packages/sis/scripts/fedora_patch/Image.pm,v 1.2 2004/03/03 21:23:56 bligneri Exp $

#   Copyright (c) 2001 International Business Machines
 
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
 
#   Michael Chase-Salerno <salernom@us.ibm.com>             
use strict;

use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
use File::Path;
use SystemInstaller::Log qw (verbose);
use Carp;
 
@EXPORT = qw(find_distro init_image del_image write_scconf cp_image split_version); 
@EXPORT_OK = qw(find_distro init_image del_image write_scconf cp_image split_version); 
 
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

my @MODS=qw(Kernel_ia64 Kernel_iseries Kernel_x86);
use SystemInstaller::Image::Kernel_x86;
use SystemInstaller::Image::Kernel_ia64;
use SystemInstaller::Image::Kernel_iseries;

use SystemInstaller::Log qw(verbose get_verbose);

sub init_image {
# Creates the image directories 
#
# Input: 	Image root directory
# Returns:	1 if failure, 0 if ok

	my $root = shift;
	mkpath(["$root/usr/lib","$root/var","$root/home","$root/tmp","$root/boot","$root/proc","$root/root"]);
	mkpath(["$root/etc/systemimager/partitionschemes"]);
	mkpath(["$root/etc/systemconfig"]);
	# Check that something worked.
	unless (-d "$root/usr/lib" ){
		return 1;
	}
	return 0;
} #init_image

sub del_image {
# Removes an image
#
# Input: 	Image root directory
# Returns:	1 if failure, 0 if ok

	my $image = shift;
	my $CMD=$main::config->delimage ." ". $image;
	&verbose("$CMD");
	if (system($CMD)){
		return 1;
	}
	return 0;
} #del_image

sub cp_image {
# Makes a copy of an image.
#
        my %vars = (
                source => undef,
                destination => undef,
                @_,
        );
        &verbose("Checking cp_image input.");
        foreach my $required (qw(source destination)) {
                if (!$vars{$required}) {
                        carp("Required variable $required not provided");
                        return undef;
                }
        }
	my $cmd=$main::config->cpimage;
        if (&get_verbose) {
                $cmd.=" -verbose";
        }
        $cmd.=" $vars{source} $vars{destination}";
        &verbose($cmd);
	if (system($cmd)){
		return 1;
	}
	return 0;



} # cp_image



sub split_version {
# Splits the version from find_distro into its major and 
# minor parts for reference into the distinfo tree
# Input:        Version from find_distro
# Output:       A list with the major and minor parts.
        my $version=shift;
        my ($maj,$min)=split(/\./,$version);
        return ($maj,$min);
}

sub find_distro {
# Try to determine which distro is contained in a directory
#
# Input:	Package file directory
# Returns:	A 2 element list, 
#			distro name, release
#				or
#			null if unable to determine
        my $pkgdir=$_[0];
        my $distro;
        my $version;
        my @relfiles;
 
        # Is this Mandrake?
        @relfiles=glob("$pkgdir/mandrake-release*.rpm");
        if (scalar(@relfiles) == 1) {
                $distro="Mandrake";
                # Now find the version
                $relfiles[0]=~s/.*\///;
                my ($j1,$j2,$version,$j3)=split(/-/,$relfiles[0]);
                return($distro,$version);
        }
        undef @relfiles;
        # Is this Redhat AS?
        @relfiles=glob("$pkgdir/redhat-release-as*.rpm");
        if (scalar(@relfiles) == 1) {
                $distro="RedhatAS";
                # Now find the version
                $relfiles[0]=~s/.*\///;
                my ($j1,$j2,$j3,$version,$j3)=split(/-/,$relfiles[0]);
                $version=~s/AS//;
                return($distro,$version);
        }

	# Is it Fedora ?
        @relfiles=glob("$pkgdir/fedora-release*.rpm");
        if (scalar(@relfiles) == 1) {
                $distro="Fedora";
                # Now find the version
                $relfiles[0]=~s/.*\///;
                my ($j1,$j2,$version,$j3)=split(/-/,$relfiles[0]);
                return($distro,$version);
        }
        undef @relfiles;

        # Is this Redhat?
        @relfiles=glob("$pkgdir/redhat-release*.rpm");
        if (scalar(@relfiles) == 1) {
                $distro="Redhat";
                # Now find the version
                $relfiles[0]=~s/.*\///;
                my ($j1,$j2,$version,$j3)=split(/-/,$relfiles[0]);
                return($distro,$version);
        }
        undef @relfiles;
        # How about TurboLinux?
        @relfiles=glob("$pkgdir/distribution-release-TL*.rpm");
        if (scalar(@relfiles) >= 1) {
                $distro="Turbo";
                # Now find the version
                $relfiles[0]=~s/.*\///;
                my ($j1,$j2,$version,$j3)=split(/-/,$relfiles[0]);
                $version=~s/TLS//;
                return($distro,$version);
        }
        undef @relfiles;
        # Maybe Suse?
        my $versionrpm;
        @relfiles=glob("$pkgdir/aaa_version*.rpm");
        if (scalar(@relfiles) >= 1) {
                $versionrpm=$relfiles[0];
        } elsif (scalar(@relfiles=glob("$pkgdir/sles-release*.rpm")) >= 1) {
                 $versionrpm=$relfiles[0];
        } else  {
                @relfiles=glob("$pkgdir/aaa_base*.rpm");
                if (scalar(@relfiles) >= 1) {
                        $versionrpm=$relfiles[0];
                }
        }
        if ($versionrpm) {
                $distro="Suse"; # Unless it is SLES down below.
                # Now find the version
                mkdir("/tmp/find_distro");
                system("cd /tmp/find_distro; rpm2cpio $versionrpm | cpio -iumd --quiet  etc/SuSE-release");
                unless (open(BASE,"< /tmp/find_distro/etc/SuSE-release")) {
                        carp("Unable to determine distro for Suse");
                } else {
                        while (<BASE>) {
                                chomp;
                                if (/SLES/) {
                                        $distro="SLES";
                                }
                                if (/^VERSION/) {
                                        $version=$_;
                                        $version=~s/^VERSION = //;
                                }
                        }
                }
                rmtree("/tmp/find_distro");
                return($distro,$version);
        }
        undef @relfiles;
        #If we got here, we couldn't figure it out.
        return ;
}                       


sub write_scconf {
        # Write the boot and kernel info to the systemconfig.conf file.
        #
        # Input: imagedir, root device, boot device
        # Returns: Boolean
        my $imagedir=shift;
        my $root=shift;
        my $boot=shift;
        my $scfile="$imagedir/etc/systemconfig/systemconfig.conf";

        # Make sure we have all input
        unless ($imagedir && $root && $boot) {
                carp("Missing required input!");
                return 0;
        }
        unless (open(SCFILE,">$scfile")) {
                carp("Cannot open System Configurator conf file $scfile!");
                return 0;
        }
        # Print the first part of the file, the static data and the boot 
        # devices.
        print SCFILE "# systemconfig.conf written by systeminstaller.\n";
        print SCFILE "CONFIGBOOT = YES\nCONFIGRD = YES\n\n[BOOT]\n";
        print SCFILE "\tROOTDEV = $root\n\tBOOTDEV = $boot\n";

        # Now find the kernels.
        my @kernels=find_kernels($imagedir);
        my $i=0;
        my $default=0;
        foreach (@kernels){
                my ($path,$label)=split;
                # Make sure its not longer than 15 characters
                $label=substr($label,0,15);
                unless ($default){
                        print SCFILE "\tDEFAULTBOOT = $label\n\n";
                        $default++;
                }
                print SCFILE "[KERNEL$i]\n";
                print SCFILE "\tPATH = $path\n";
                print SCFILE "\tLABEL = $label\n\n";
                $i++;
        }        
        close SCFILE;
        return 1;
                
} #write_scconf

sub find_kernels {
# Builds the systemconfig.conf
# Input: pkg path, imagedir, force flag
# Output: boolean success/failure

        my $imgpath=shift;
        my @kernels;

        foreach (@MODS){
		my $class="SystemInstaller::Image::$_";
                if ($class->footprint($imgpath)) {
                        return $class->find_kernels($imgpath);
                }
        }
        return 1;

} #find_kernels

### POD from here down

=head1 NAME
 
SystemInstaller::Image - Interface to Images for SystemInstaller
 
=head1 SYNOPSIS   

 use SystemInstaller::Image;

 if (&SystemInstaller::Image::init_image("/var/images/image1") {
	printf "Image initialization failed\n";
 }

=head1 DESCRIPTION

SystemInstaller::Image provides an interface to creating images
for SystemInstaller.

=head1 AUTHOR
 
Michael Chase-Salerno <mchasal@users.sourceforge.net>
 
=head1 SEE ALSO

 
=cut

1;
