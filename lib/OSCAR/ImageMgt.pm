package OSCAR::ImageMgt;

#
# Copyright (c) 2007-2008 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#
#   $Id: ImageMgt.pm 4833 2006-05-24 08:22:59Z bli $
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use lib "/usr/lib/systeminstaller","/usr/lib/systemimager/perl";
use OSCAR::Logger;
use OSCAR::PackagePath;
use OSCAR::Database;
use OSCAR::Utils;
use OSCAR::ConfigManager;
# use SystemImager::Server;
# use OSCAR::Opkg qw ( create_list_selected_opkgs );
use SystemInstaller::Utils;
use OSCAR::PackMan;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use warnings "all";

@EXPORT = qw(
            create_image
            delete_image
            do_setimage
            do_post_binary_package_install
            do_oda_post_install
            export_image
            get_image_default_settings
            get_list_corrupted_images
            image_exists
            install_opkgs_into_image
            update_systemconfigurator_configfile
            );

our $images_path = "/var/lib/systemimager/images";
my $verbose = 1;

################################################################################
# Set the image in the Database.                                               #
#                                                                              #
# Parameter: img, image name.                                                  #
#            options, hash with option values.                                 #
# Return   : 0 if sucess, -1 else.                                             #
################################################################################
sub do_setimage {
    my ($img, %options) = @_;
    my @errors = ();

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "file") {
        my $master_os = OSCAR::PackagePath::distro_detect_or_die("/");
        my $arch = $master_os->{arch};

        # Get the image path (typically
        # /var/lib/systemimager/images/<imagename>)
        my $config = SystemInstaller::Utils::init_si_config();
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
    } elsif ($config->{db_type} eq "file") {
        return 0;
    } else {
        carp "ERROR: Unknow ODA type ($config->{db_type}\n";
        return -1;
    }
    return 0;
}

################################################################################
# Simple wrapper around post_rpm_install; make sure we call correctly the      #
# script.                                                                      #
# Input: img, image name.                                                      #
#        interface, network interface id used by OSCAR.                        #
# Return: 1 if success, 0 else.                                                #
################################################################################
sub do_post_binary_package_install ($$) {
    my $img = shift;
    my $interface = shift;
    my $cwd = `pwd`;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return undef;
    }
    my $config = $oscar_configurator->get_config();

    chdir "$config->{binaries_path}";
    my $cmd = "$config->{binaries_path}/post_rpm_install $img $interface";

    if (system($cmd)) {
        delete_image($img);
        return 0;
    }
    oscar_log_subsection("Successfully ran: $cmd");

    chdir "$cwd";
    return 1;
}

################################################################################
# Simple wrapper around post_rpm_install; make sure we call correctly the      #
# script.                                                                      #
# Input: vars, hash with variable values.                                      #
#        options, hash with option values.                                     #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub do_oda_post_install {
    my (%vars, %options) = @_;
    my @errors = ();
    my $img = $vars{imgname};

    # Have installed Client binary packages and did not croak, so mark
    # packages. <pkg>installed # true. (best effort for now)

    oscar_log_subsection("Marking installed bit in ODA for client binary ".
                         "packages");

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "db") {
        my @opkgs = list_selected_packages("all");
        foreach my $opkg_ref (@opkgs)
        {
            my $opkg = $$opkg_ref{package};
            oscar_log_subsection("Set package: $opkg");
            OSCAR::Database::set_image_packages($img,$opkg,\%options,\@errors);
        }
    } elsif ($config->{db_type} eq "db") {
        # Get the list of opkgs for the specific image.
    } else {
        carp "ERROR: Unknow ODA type ($config->{db_type})\n";
        return -1
    }
    oscar_log_subsection("Done marking installed bits in ODA");

    #/var/log/lastlog could be huge in some horked setup packages...
    croak "Image name not defined\n" unless $img;
    my $lastlog = "/var/log/lastlog";
    oscar_log_subsection("Truncating ".$img.":".$lastlog);

    my $sis_config = SystemInstaller::Utils::init_si_config();
    my $imaged = $sis_config->default_image_dir;
    my $imagepath = $imaged."/".$img;
    my $imagelog = $imagepath.$lastlog;
    truncate $imagelog, 0 if -s $imagelog;
    oscar_log_subsection("Truncated ".$img.":".$lastlog);

    oscar_log_subsection("Image build successfully");

    return 0;
}

###############################################################################
# Get the fstab stuff based on the architecture and the type of disk          #
# Input: arch, target architecture.                                           #
#        disk_type, target disk type (e.g. IDE, SCSI).                        #
# Return: file path the fstab stuff.                                          #
###############################################################################
sub get_disk_file {
    my ($arch, $disk_type) = @_;

    my $diskfile;
    if ($ENV{OSCAR_HOME}) {
        $diskfile = "$ENV{OSCAR_HOME}/oscarsamples/$disk_type";
    } else {
        $diskfile = "/usr/share/oscar/oscarsamples/$disk_type";
    }
    #ia64 needs special disk file because of /boot/efi
    $diskfile .= ".$arch" if $arch eq "ia64";
    $diskfile .= ".disk";

    return $diskfile;
}

################################################################################
# Get the default settings for the creation of new images.                     #
# !!WARNNING!! We do not set postinstall and title. The distro is also by      #
# default the local distro.                                                    #
# Input: none.                                                                 #
# Output: default settings (via a hash).                                       #
#         The format of the hash is the following is available within the code.#
# TODO: fix the problem with the distro parameter.                             #
################################################################################
sub get_image_default_settings () {
    my $oscarsamples_dir;
    if (defined $ENV{OSCAR_HOME}) {
        $oscarsamples_dir = "$ENV{OSCAR_HOME}/oscarsamples";
    } else {
        $oscarsamples_dir = "/usr/share/oscar/oscarsamples";
    }
    my @df_lines = `df /`;
    my $disk_type = "ide";
    $disk_type = "scsi" if (grep(/\/dev\/sd/,(@df_lines)));

    #Get the distro list
    my $master_os = OSCAR::PackagePath::distro_detect_or_die("/");
    my $arch = $master_os->{arch};

    my $distro = $master_os->{compat_distro};
    my $distro_ver = $master_os->{compat_distrover};

    my $distro_pool = OSCAR::PackagePath::distro_repo_url();
    $distro_pool =~ s/\ /,/g;
    my $oscar_pool = OSCAR::PackagePath::oscar_repo_url();

    oscar_log_subsection("Identified distro of clients: $distro $distro_ver");
    oscar_log_subsection("Distro repo: $distro_pool");
    oscar_log_subsection("OSCAR repo: $oscar_pool");

    my $pkglist = "$oscarsamples_dir/$distro-$distro_ver-$arch.rpmlist";
    oscar_log_subsection("Using binary list: $pkglist");

    # Get a list of client RPMs that we want to install.
    # Make a new file containing the names of all the RPMs to install

#     my $outfile = "/tmp/oscar-install-rpmlist.$$";
#     create_list_selected_opkgs ($outfile);
#     my @errors;
#     my $save_text = $outfile;
#     my $extraflags = "--filename=$outfile";
    # WARNING!! We deactivate the OPKG management via SystemInstaller
    my $extraflags = "";
    if (exists $ENV{OSCAR_VERBOSE}) {$extraflags .= " --verbose ";}

    my $diskfile = get_disk_file($arch, $disk_type);

    my $config = SystemInstaller::Utils::init_si_config();

    # Default settings
    my %vars = (
           # imgpath: location where the image is created
           imgpath => $config->default_image_dir,
           # imgname: image name
           imgname => "oscarimage",
           # arch: target hardware architecture
           arch => $arch,
           # pkgfile: location of the file giving the list of binary package
           # for the creation of the image
           pkgfile => $pkglist,
           # pkgpath: path of the different binary packages pools used for the
           # creation of the image.
           pkgpath => "$oscar_pool,$distro_pool",
           # diskfile: path to the file that gives the disk partition layout.
           diskfile => $diskfile,
           # ipmeth: method to assign the IP (possible options are: "static")
           # TODO: check what are the other possible options
           ipmeth => "static",
           # piaction: action to perform when the image is deployed (possible
           # options are: "reboot").
           # TODO: check what are the other possible options
           piaction => "reboot",
           # extraflags: string for extra SIS flags. Should be used only for the
           # tricky stuff.
           extraflags => $extraflags
           );

    return %vars;
}

################################################################################
# Delete an existing image.                                                    #
# Input: imgname, image name.                                                  #
# Output: none.                                                                #
# TODO: We need to update the OSCAR database when deleting an image.           #
################################################################################
sub delete_image ($) {
    my $imgname = shift;

    my $config = SystemInstaller::Utils::init_si_config();
    my $rsyncd_conf = $config->rsyncd_conf();
    my $rsync_stub_dir = $config->rsync_stub_dir();

    system("mksiimage -D --name $imgname");
    require SystemImager::Server;
    SystemImager::Server::remove_image_stub($rsync_stub_dir, $imgname);
    SystemImager::Server::gen_rsyncd_conf($rsync_stub_dir, $rsyncd_conf);
}

################################################################################
# Get the list of corrupted images. An image is concidered corrupted when info #
# from the OSCAR database, the SIS database and the file system are not        #
# synchronized.                                                                #
#                                                                              #
# Input: None.                                                                 #
# Output: an array of hash; each element of the array (hash) has the following #
#         format ( 'name' => <image_name>,                                     #
#                  'oda' => "ok"|"missing",                                    #
#                  'sis' => "ok"|"missing",                                    #
#                  'fs' => "ok"|"missing" ).                                   #
################################################################################
sub get_list_corrupted_images {
    my $sis_cmd = "/usr/bin/si_lsimage";
    my @sis_images = `$sis_cmd`;
    my @result;

    #We do some cleaning...
    # We remove the three useless lines of the result
    for (my $i=0; $i<3; $i++) {
        shift (@sis_images);
    }
    # We also remove the last line which is an empty line
    pop (@sis_images);
    # Then we remove the return code at the end of each array element
    # We also remove the 2 spaces before each element
    foreach my $i (@sis_images) {
        chomp $i;
        $i = substr ($i, 2, length ($i));
    }

    # The array is now clean, we can print it
    print "List of images in the SIS database: ";
    print_array (@sis_images);

    my @tables = ("Images");
    my @oda_images = ();
    my @res = ();
    my $cmd = "SELECT Images.name FROM Images";
    if ( OSCAR::Database::single_dec_locked( $cmd,
                                             "READ",
                                             \@tables,
                                             \@res,
                                             undef) ) {
    # The ODA query returns a hash which is very unconvenient
    # We transform the hash into a simple array
    foreach my $elt (@res) {
        # It seems that we always have an empty entry, is it normal?
        if ($elt->{name} ne "") {
            push (@oda_images, $elt->{name});
        }
    }
    print "List of images in ODA: ";
    print_array (@oda_images);
    } else {
        die ("ERROR: Cannot query ODA\n");
    }

    # We get the list of images from the file system
    my $sis_image_dir = "/var/lib/systemimager/images";
    my @fs_images = ();
    die ("ERROR: The image directory does not exist ".
         "($sis_image_dir)") if ( ! -d $sis_image_dir );
    opendir (DIRHANDLER, "$sis_image_dir")
        or die ("ERROR: Impossible to open $sis_image_dir");
    foreach my $dir (sort readdir(DIRHANDLER)) {
        if ($dir ne "."
            && $dir ne ".."
            && $dir ne "ACHTUNG"
            && $dir ne "DO_NOT_TOUCH_THESE_DIRECTORIES"
            && $dir ne "CUIDADO"
            && $dir ne "README") {
            push (@fs_images, $dir);
        }
    }
    print "List of images in file system: ";
    print_array (@fs_images);

    # We now compare the lists of images
    foreach my $image_name (@sis_images) {
        my %entry = ('name' => $image_name,
                     'sis' => "ok",
                     'oda' => "ok",
                     'fs' => "ok");
        if (!is_element_in_array($image_name, @oda_images)) {
            $entry{'oda'} = "missing";
        }
        if (!is_element_in_array($image_name, @fs_images)) {
            $entry{'fs'} = "missing";
        }
        push (@result, \%entry);
    }

    foreach my $image_name (@oda_images) {
        my %entry = ('name' => $image_name,
                     'sis' => "ok",
                     'oda' => "ok",
                     'fs' => "ok");
        if (!is_element_in_array($image_name, @sis_images)) {
            $entry{'sis'} = "missing";
        }
        if (!is_element_in_array($image_name, @fs_images)) {
            $entry{'fs'} = "missing";
        }
        push (@result, \%entry);
    }

    foreach my $image_name (@fs_images) {
        my %entry = ('name' => $image_name,
                     'sis' => "ok",
                     'oda' => "ok",
                     'fs' => "ok");
        if (!is_element_in_array($image_name, @sis_images)) {
            $entry{'sis'} = "missing";
        }
        if (!is_element_in_array($image_name, @oda_images)) {
            $entry{'oda'} = "missing";
        }
        push (@result, \%entry);
    }

    return (@result);
}

################################################################################
# Check if a given image exists.                                               #
#                                                                              #
# Input: image_name, name of the image to check.                               #
# Return: 1 if the image already exists (true), 0 else (false), -1 if error.   #
################################################################################
sub image_exists ($) {
    my $image_name = shift;

    if (!OSCAR::Utils::is_a_valid_string ($image_name)) {
        carp "ERROR: Invalid image name";
        return -1;
    }

    my $path = "$images_path/$image_name";

    if ( -d $path ) {
        return 1;
    } else {
        return 0;
    }
}

################################################################################
# Create a basic image.                                                        #
#                                                                              #
# Input: image. image name to create.                                          #
#        vars, image configuration (hash.
# Return: 0 if success, -1 else.                                               #
################################################################################
sub create_image ($%) {
    my ($image, %vars) = @_;

    # We create a basic image for clients. Note that by default we do not
    # create a basic image for servers since the server may already be deployed.
    # We currently use the script 'build_oscar_image_cli'. This is a limitation
    # because it only creates an image based on the local Linux distribution.
    oscar_log_section "Creating the basic golden image..." if $verbose;

    $vars{imgname} = "$image";
    $verbose = 1;

    my $cmd = "mksiimage -A --name $vars{imgname} " .
            "--filename $vars{pkgfile} " .
            "--arch $vars{arch} " .
            "--path $vars{imgpath}/$vars{imgname} ";
    $cmd .= "--distro $vars{distro} " if defined $vars{distro};
    if (!defined $vars{distro} && defined $vars{pkgpath}) {
        $cmd .= "--location $vars{pkgpath} ";
    }
    $cmd .= " $vars{extraflags} --verbose";

    oscar_log_subsection "Executing command: $cmd" if $verbose;
    if (system ($cmd)) {
        carp "ERROR: Impossible to create the image\n";
        return -1;
    }
    # GV: currently we create first a basic image and only then we install OPKGs
    # and run post_install scripts. Therefore the following command should not
    # be needed.
    postimagebuild (\%vars);

    # Add image data into ODA
    my %image_data = ("name" => $image,
                      "path" => "$vars{imgpath}/$vars{imgname}",
                      "architecture" => "$vars{arch}");
    if (OSCAR::Database::set_images (\%image_data, undef, undef) != 1) {
        carp "ERROR: Impossible to store image data into ODA";
        return -1;
    }

    my $systemconfig_file = "$image/etc/systemconfig/systemconfig.conf";
    if (update_systemconfigurator_configfile ($systemconfig_file) == -1) {
        carp "ERROR: Impossible to update the file $systemconfig_file";
        return -1;
    }

    return 0;
}

################################################################################
# SystemConfigurator has a bad limitation: the label for the default kernel    #
# has a limitation on its length. So we check this length and we update it if  #
# needed.                                                                      #
#                                                                              #
# Input: full path of the SystemConfigurator config file to analyze.           #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub update_systemconfigurator_configfile ($) {
    my $file = shift;
    use constant MAX_LABEL_LENGTH  =>  16;

    if (! -f $file) {
        return 1;
    }

    require OSCAR::ConfigFile;
    my $default_boot = OSCAR::ConfigFile::get_value ($file,
                                                     "BOOT",
                                                     "DEFAULTBOOT");
    my $default_label = OSCAR::ConfigFile::get_value ($file,
                                                     "KERNEL0",
                                                     "LABEL");

    if (!defined ($default_boot) || !defined ($default_label)) {
        carp "ERROR: The file $file exists but does not have a default boot ".
             "or a default label";
        return -1;
    }

    if ($default_boot ne $default_label) {
        print STDERR "WARNING: the default boot kernel is not the kernel0 we ".
                     "do not know how to deal with that situation";
        return 1;
    }

    if (length ($default_boot) > MAX_LABEL_LENGTH) {
        if (OSCAR::ConfigFile::set_value($file,
                                         "BOOT",
                                         "DEFAULTBOOT",
                                         "default_kernel")) {
            carp "ERROR: Impossible to update the default boot kernel";
            return -1;
        }
        if (OSCAR::ConfigFile::set_value($file,
                                         "KERNEL0",
                                         "LABEL",
                                         "default_kernel")) {
            carp "ERROR: Impossible to update the label of the default kernel";
            return -1;
        }
    }

    return 0;
}

# Return: 0 if success, -1 else.
sub postimagebuild {
    my ($vars) = @_;
    my $img = $$vars{imgname};
    my $interface = "eth0";
    my %options;

    print ("Setting up image in the database\n");
    if (do_setimage ($img, \%options)) {
        carp "ERROR: Impossible to set image";
        return -1;
    }

    my $cmd = "post_binary_package_install ($img, $interface)";
    print ("Running: $cmd");
    if (do_post_binary_package_install ($img, $interface) == 0) {
        carp "ERROR: Impossible to do post binary package install";
        return -1;
    }

    if (do_oda_post_install (%$vars, \%options)) {
        carp "ERROR: Impossible to update data in ODA";
        return -1;
    }

    return 0;
}

################################################################################
# Install a given list of OPKGs into a golden image. We assume for now that we #
# have to install the client side of those OPKGs.                              #
#                                                                              #
# Input: partition, the image name in which we need to install OPKGs.          #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: remove the hardcoded image path. SIS provides a tool for that.         #
################################################################################
sub install_opkgs_into_image ($@) {
    my ($image, @opkgs) = @_;

    # We check first if parameters are valid.
    if (!defined($image) || $image eq "" ||
        !@opkgs) {
        carp "ERROR: Invalid parameters\n";
        return -1;
    }

    my $image_path = "$images_path/$image";
    if ($verbose) {
        oscar_log_section "Installing OPKGs into image $image ($image_path)";
        oscar_log_subsection "List of OPKGs to install:";
        print_array (@opkgs);
    }

    # To install OPKGs, we use Packman, creating a specific packman object for
    # the image.
    my $pm = PackMan->new->chroot ($image_path);
    if (!defined ($pm)) {
        carp "ERROR: Impossible to create a Packman object for the ".
             "installation of OPKGs into the golden image\n";
        return -1;
    }

    # We assign the correct repos to the PacjMan object.
    my $os = OSCAR::OCA::OS_Detect::open(chroot=>$image_path);
    if (!defined ($os)) {
        carp "ERROR: Impossible to detect the OS of the image ($image_path)\n";
        return -1;
    }
    my $oscar_pkg_pool = OSCAR::PackagePath::oscar_repo_url(os=>$os);
    my $distro_pkg_pool = OSCAR::PackagePath::distro_repo_url(os=>$os);
    my @pools = split(",", $oscar_pkg_pool);
    my @distro_pools = split(",", $distro_pkg_pool);
    foreach my $repo (@distro_pools) {
        next if $repo eq "";
        push (@pools, $repo);
    }
    print "Available pools:\n";
    OSCAR::Utils::print_array (@pools);
    $pm->repo(@pools);

    my ($ret, $output) = $pm->smart_install (@opkgs);
    print "Installation result: $ret\n";
    if ( defined ($output) ) {
        print "\t[" . join (" ", @$output) . "]\n";
    }
    if ($ret == -1) {
        carp "ERROR: Impossible to install OPKGs\n";
        return -1;
    }

    # GV: do we need to install only the client side of the OPKG? or do we also
    # need to install the api part.
    foreach my $opkg (@opkgs) {
        oscar_log_subsection "\tInstalling $opkg using opkg-$opkg-client"
            if $verbose;
        # Once we have the packman object, it is fairly simple to install opkgs.
        my ($ret, $output) = $pm->smart_install("opkg-$opkg-client");
        print "Installation result: $ret\n";
        if ( defined ($output) ) {
            print "\t[" . join (" ", @$output) . "]\n";
        }
        if ($ret == -1) {
            carp "ERROR: Impossible to install OPKG $opkg\n";
            return -1;
        }
    }

    return 0;
}

################################################################################
# Export the image for a given partition. This image can then be used outside  #
# of OSCAR. The export typically creates a tarball having the file system of   #
# partition. The name of the partition is image-<partition_id>.tar.gz.         #
#                                                                              #
# Input: partition, partition identifier (typically its name).                 #
#        dest, directory where the tarball will be created. Note that the      #
#        directory is also used as temporary directory while creating the      #
#        image, that can require a lot of disk space.                          #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub export_image ($$) {
    my ($partition, $dest) = @_;

    if (!defined ($partition) || !defined ($dest)) {
        carp "ERROR: Invalid arguments";
        return -1;
    }

    my $tarball = "$dest/image-$partition.tar.gz";
    my $temp_dir = "$dest/temp-$partition";

    require File::Path;

    if (! -d $dest) {
        carp "ERROR: the destination directory does not exist";
        return -1;
    }
    if (-f $tarball) {
        carp "ERROR: the tarball already exists ($tarball)";
        return -1;
    }

    if (image_exists ($partition) == 1) {
        oscar_log_subsection "INFO: The image already exists" if $verbose;

        # the image already exists we just need to create the tarball
        my $cmd = "cd $images_path/$partition; tar czf $tarball *";
        oscar_log_subsection "Executing: $cmd" if $verbose;
        if (system ($cmd)) {
            carp "ERROR: impossible to create the tarball";
            return -1;
        }
    } else {
        oscar_log_subsection "INFO: the image does not exist" if $verbose;
        if (-d $temp_dir) {
            rmtree ($temp_dir);
        }

        # We get the default settings for images.
        my %image_config = OSCAR::ImageMgt::get_image_default_settings ();
        if (!%image_config) {
            carp "ERROR: Impossible to get default image settings\n";
            return -1;
        }
        $image_config{imgpath} = $temp_dir;
        # If the image does not already exists, we create it.
        if (OSCAR::ImageMgt::create_image ($partition, %image_config)) {
            carp "ERROR: Impossible to create the basic image\n";
            rmtree ($temp_dir);
            return -1;
        }

        # the image is ready to be tared!
        my $cmd = "cd $temp_dir; tar czf $tarball *";
        oscar_log_subsection "Executing: $cmd" if $verbose;
        if (system ($cmd)) {
            carp "ERROR: impossible to create the tarball";
            rmtree ($temp_dir);
            return -1;
        }

        rmtree ($temp_dir);
    }
    return 0;
}

1;

__END__

=head1 NAME

ImageMgt - a set of functions for the management of images in OSCAR.

=head1 SYNOPSIS

The available functions are:

    create_image
    delete_image
    do_setimage
    do_post_binary_package_install
    do_oda_post_install
    export_image
    get_image_default_settings
    get_list_corrupted_images
    image_exists
    install_opkgs_into_image
