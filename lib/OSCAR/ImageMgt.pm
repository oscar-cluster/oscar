package OSCAR::ImageMgt;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
#
#   $Id: PackageSet.pm 4833 2006-05-24 08:22:59Z bli $
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This package provides a set of function for OSCAR image management. This has
# initialy be done to avoid code duplication between the CLI and the GUI.
#

use strict;
use lib "$ENV{OSCAR_HOME}/lib","/usr/lib/systeminstaller";
use OSCAR::Logger;
use OSCAR::PackagePath;
use OSCAR::Database;
use SystemInstaller::Tk::Common;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            do_setimage
            do_post_binary_package_install
            do_oda_post_install
            );

################################################################################
# Set the image in the Database.                                               #
# Parameter: img, image name.                                                  #
#            options, hash with option values.                                 #
# Return   : None.                                                             #
################################################################################
sub do_setimage {
    my ($img, %options) = @_;
    my @errors = ();

    my $master_os = OSCAR::PackagePath::distro_detect_or_die("/");
    my $arch = $master_os->{arch};

    # Get the image path (typically /var/lib/systemimager/images/<imagename>)
    my $config = SystemInstaller::Tk::Common::init_si_config();
    my $imaged = $config->default_image_dir;
    croak "default_image_dir not defined\n" unless $imaged;
    croak "$imaged: not a directory\n" unless -d $imaged;
    croak "$imaged: not accessible\n" unless -x $imaged;
    my $imagepath = $imaged."/".$img;
    croak "$imagepath: not a directory\n" unless -d $imagepath;
    croak "$imagepath: not accessible\n" unless -x $imagepath;

    #
    # Image info lines should be deleted once systeminstaller
    # talks directly to ODA
    #
    my %image_info = ( "name"        => $img,
               #
               # EF: OS_Detect detects images now, use that!
               #
               # "distro"=>"$distroname-$distroversion",
              "architecture" => $arch,
              "path"         => $imagepath);

    OSCAR::Database::set_images(\%image_info, \%options, \@errors);
}

################################################################################
# Simple wrapper around post_rpm_install; make sure we call correctly the      #
# script.                                                                      #
# Input: img, image name.                                                      #
#        interface, network interface id used by OSCAR.                        #
# Return: none.                                                                #
################################################################################
sub do_post_binary_package_install{
    my $img = shift;
    my $interface = shift;
    my $cwd = `pwd`;
    chdir "$ENV{OSCAR_HOME}/scripts/";
    my $cmd = "$ENV{OSCAR_HOME}/scripts/post_rpm_install $img $interface";

    !system($cmd) or (carp($!), return undef);
    oscar_log_subsection("Successfully ran: $cmd");

    chdir "$cwd";
}

################################################################################
# Simple wrapper around post_rpm_install; make sure we call correctly the      #
# script.                                                                      #
# Input: vars, hash with variable values.                                      #
#        options, hash with option values.                                     #
# Return: none.                                                                #
################################################################################
sub do_oda_post_install {
    my (%vars, %options) = @_;
    my @errors = ();
    my $img = $vars{imgname};

    # Have installed Client binary packages and did not croak, so mark
    # packages. <pkg>installed # true. (best effort for now)

    oscar_log_subsection("Marking installed bit in ODA for client binary ".
                         "packages");

    my @opkgs = list_selected_packages("all");
    foreach my $opkg_ref (@opkgs)
    {
        my $opkg = $$opkg_ref{package};
        oscar_log_subsection("Set package: $opkg");
        OSCAR::Database::set_image_packages($img,$opkg,\%options,\@errors);
    }
    oscar_log_subsection("Done marking installed bits in ODA");

    #/var/log/lastlog could be huge in some horked setup packages...
    croak "Image name not defined\n" unless $img;
    my $lastlog = "/var/log/lastlog";
    oscar_log_subsection("Truncating ".$img.":".$lastlog);

    my $config = init_si_config();
    my $imaged = $config->default_image_dir;
    my $imagepath = $imaged."/".$img;
    my $imagelog = $imagepath.$lastlog;
    truncate $imagelog, 0 if -s $imagelog;
    oscar_log_subsection("Truncated ".$img.":".$lastlog);

    oscar_log_subsection("Image build successfully");
}