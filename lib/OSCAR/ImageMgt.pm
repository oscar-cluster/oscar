package OSCAR::ImageMgt;

#
# Copyright (c) 2007-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#
#   $Id$
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
use File::Basename;
use File::Temp qw/ :mktemp  /;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::PackagePath;
use OSCAR::Database;
use OSCAR::Utils;
use OSCAR::Env;
use OSCAR::ConfigManager;
# use SystemImager::Server;
use OSCAR::Opkg;
use OSCAR::PackMan;
use SystemInstaller::Utils;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use warnings "all";

@EXPORT = qw(
            create_image
            delete_image
            delete_image_from_oda
            do_setimage
            do_post_image_creation
            do_oda_post_install
            export_image
            get_image_default_settings
            get_list_corrupted_images
            get_list_images
            image_exists
            install_opkgs_into_image
            update_grub_config
            update_image_initrd
            update_kernel_append
            update_modprobe_config
            update_systemconfigurator_configfile
            );

our $si_config = SystemInstaller::Utils::init_si_config();

our $images_path = "/var/lib/systemimager/images";
$images_path = $si_config->default_image_dir if defined($si_config->default_image_dir);

our $imagename;

################################################################################
# Set the image in the Database.                                               #
#                                                                              #
# Parameter: img, image name.                                                  #
#            options, hash with option values.                                 #
# Return   : 0 if sucess, -1 else.                                             #
################################################################################
sub do_setimage ($%) {
    my ($img, %options) = @_;
    my @errors = ();

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{oda_type} eq "db") {
        my $master_os = OSCAR::PackagePath::distro_detect_or_die("/");
        my $arch = $master_os->{arch};

        # Get the image path (typically
        # /var/lib/systemimager/images/<imagename>)
        #my $config = SystemInstaller::Utils::init_si_config();
        # FIXME: is $config always defined?
        my $imaged = $si_config->default_image_dir;
        (oscar_log(5, ERROR, "default_image_dir not defined."), return -1)
            unless $imaged;
        (oscar_log(5, ERROR, "$imaged: not a directory."), return -1)
            unless -d $imaged;
        (oscar_log(5, ERROR, "$imaged: not accessible."), return -1)
            unless -x $imaged;
        my $imagepath = $imaged."/".$img;
        (oscar_log(5, ERROR, "$imagepath: not an image directory."), return -1)
            unless -d $imagepath;
        (oscar_log(5, ERROR, "$imagepath: not accessible."), return -1)
            unless -x $imagepath;

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
    } elsif ($config->{oda_type} eq "file") {
        return 0;
    } else {
        oscar_log(5, ERROR, "Unknow ODA type ($config->{oda_type})");
        return -1;
    }
    return 0;
}

################################################################################
# Runs the post installation scripts.
#                                                                              #
# Input: $vars
# Return: 1 if success, 0 else.                                                #
################################################################################
sub do_post_image_creation ($) {
    my $vars = shift;
    my $cmd = "";
    $imagename = $$vars{imgname};

    if (! -d "${images_path}/${imagename}") {
        oscar_log(1, ERROR, "${images_path}/${imagename} does not exists.");
        return 0;
    }

    oscar_log(3, INFO, "Running post image creation scripts.");

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        delete_image($imagename);
        return 0;
    }

    my $config = $oscar_configurator->get_config();

    #
    # 1st: Install the ssh config.
    #
    $cmd = "$config->{binaries_path}/ssh_install ${images_path}/${imagename}"; # FIXME: OL: we should have a core opkg for that. (maybe a opium non chroot script?)
    if(oscar_system($cmd)) {
        oscar_log(1, ERROR, "Couldn't generate ssh keys ($cmd)");
        return 1;
    }

    #
    # 2nd: We run the post install scripts.
    # 
    my @pkgs = OSCAR::Database::list_selected_packages(); # We assume that all cores are selected.

    my $err_count = 0;

    oscar_log(3, INFO, "Running OSCAR package post_rpm_install scripts for " . join(", ", @pkgs));
    # Fist we mount specific filesystems into the image for chrooted runs.

    my @bind = ('/dev', '/proc', '/sys', '/run', '/tmp');
    $SIG{INT}  = \&UmountSigHandler; # Catch signals so we can unmount garbage.
    $SIG{QUIT} = \&UmountSigHandler;
    $SIG{TERM} = \&UmountSigHandler;
    $SIG{KILL} = \&UmountSigHandler;
    $SIG{HUP}  = \&UmountSigHandler;
    for my $mpt (@bind) {
        if ( -d $mpt ) {
            oscar_log(5, INFO, "Mounting $mpt into image ${images_path}/${imagename}$mpt");
            $cmd = "mount -o bind $mpt ${images_path}/${imagename}$mpt";
            if(oscar_system($cmd)) {
                oscar_log(5, WARNING, "Failed to mount -o bind $mpt into the image ${images_path}/${imagename}$mpt");
            }
        }
    }

    foreach my $pkg (@pkgs) {       # %$pkg_ref has the two keys ( package, version);
        if(OSCAR::Package::run_pkg_script_chroot($pkg, "${images_path}/${imagename}") != 1) {
            oscar_log(2, ERROR, "Couldn't run post_rpm_install for $pkg");
            $err_count++;
        }

        # Config script running outside chroot, for access to
        # master databases, xml files and parsing perl modules.
        # Argument passed: image directory path.

        if(!OSCAR::Package::run_pkg_script($pkg,"post_rpm_nochroot",1,"${images_path}/${imagename}")) {
            oscar_log(2, ERROR, "Couldn't run post_rpm_nochroot for $pkg");
            $err_count++;
        }
    }

    UmountSpecialFS();
    $SIG{INT}  = 'DEFAULT'; # Reset signal handler
    $SIG{QUIT} = 'DEFAULT';
    $SIG{TERM} = 'DEFAULT';
    $SIG{KILL} = 'DEFAULT';
    $SIG{HUP}  = 'DEFAULT';

    if($err_count) {
        oscar_log (1, ERROR, "There were errors running post install scripts. Please check your logs.");
        delete_image($imagename);
        return 0;
    }

    #
    # 3rd: We create the SystemImager auto_install scripts for the image.
    #
    my $config_dir = "/etc/systemimager";
    my $auto_install_script_conf = "${images_path}/${imagename}${config_dir}/autoinstallscript.conf";
    SystemImager::Server->validate_auto_install_script_conf( $auto_install_script_conf );

    my $ip_assignment_method = "static";
    $ip_assignment_method = $$vars{ipmeth} if defined($$vars{ipmeth});
    my $post_install = "reboot";
    $post_install = $$vars{piaction} if defined($$vars{piaction});
    my $no_listing = 0;
    my $autodetect_disks = 1;
    my $overrides = "$imagename,";
    my $script_name = $imagename;
    my $autoinstall_script_dir = $si_config->autoinstall_script_dir();
    oscar_log(5, INFO, "Generating autoinstall script for image $imagename.");
    oscar_log(5, INFO, "Using postinstall action: $post_install");
    oscar_log(5, INFO, "Using ip assigment method: $ip_assignment_method");

    SystemImager::Server->create_autoinstall_script(
        $script_name,
        $autoinstall_script_dir,
        $config_dir,
        $imagename,
        $overrides,
        $autoinstall_script_dir,
        $ip_assignment_method,
        $post_install,
        $no_listing,
        $auto_install_script_conf,
        $autodetect_disks);

    oscar_log(5, INFO, "New autoinstall script has been created for this image: $autoinstall_script_dir/$script_name.master");

    $imagename = "";
    return 1;
}

sub UmountSigHandler {
    my $signal=@_;
    oscar_log(1, ERROR, "do_post_image_creation: Caught signal $signal");
    UmountSpecialFS();
    delete_image($imagename);
    $imagename = "";
    exit 1;
}

sub UmountSpecialFS {
    if(defined($imagename) && ($imagename ne "") && (-d "${images_path}/${imagename}")) {
        for my $mount ('/dev', '/proc', '/sys', '/run', '/tmp') {
            if (-d $mount) {
                my $cmd = "umount ${images_path}/${imagename}$mount";
                oscar_log(5, INFO, "Unmounting [$mount]");
                oscar_system($cmd);
            }
        }
    } else {
        oscar_log(1, INFO, "post_rpm_install: no image dir: nothing to unmount");
    }
}

################################################################################
# Input: vars, hash with variable values.                                      #
#        options, hash with option values.                                     #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub do_oda_post_install ($$) {
    my ($vars, $options) = @_;
    my @errors = ();
    my $img = $$vars{imgname};

    # Have installed Client binary packages and did not croak, so mark
    # packages. <pkg>installed # true. (best effort for now)

    oscar_log(6, INFO, "Marking installed bit in ODA for client binary packages");

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{oda_type} eq "db") {
        my @opkgs = list_selected_packages();
        foreach my $opkg (@opkgs)
        {
            oscar_log(6, INFO, "Set package $opkg as selected in ODA.");
            OSCAR::Database::set_image_packages($img,
                                                $opkg,
                                                $options,
                                                \@errors);
        }
    } else {
        oscar_log(8, DB, "Unknow ODA type ($config->{oda_type})");
        return -1
    }
    oscar_log(6, INFO, "Done marking installed bits in ODA");

    #/var/log/lastlog could be huge in some horked setup packages...
    (oscar_log(1, ERROR, "Image name not defined"), return -1)
        unless $img;
    my $lastlog = "/var/log/lastlog";
    oscar_log(6, ACTION, "Truncating ".$img.":".$lastlog);

    my $sis_config = SystemInstaller::Utils::init_si_config();
    my $imaged = $sis_config->default_image_dir;
    my $imagepath = $imaged."/".$img;
    my $imagelog = $imagepath.$lastlog;
    truncate $imagelog, 0 if -s $imagelog;
    oscar_log(6, INFO, "Truncated ".$img.":".$lastlog."\n");

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
        $diskfile = "$ENV{OSCAR_HOME}/oscarsamples/diskfiles/$disk_type";
    } else {
        $diskfile = "/usr/share/oscar/oscarsamples/diskfiles/$disk_type";
    }
    #ia64 needs special disk file because of /boot/efi
    $diskfile .= ".$arch" if $arch eq "ia64";
    $diskfile .= ".disk";

    return $diskfile;
}

sub get_binary_list_file ($) {
    my $os = shift;

    if (!defined $os) {
        oscar_log(9, ERROR, "Undefined os variable");
        return undef;
    }

    my $oscarsamples_dir;
    if (defined $ENV{OSCAR_HOME}) {
        $oscarsamples_dir = "$ENV{OSCAR_HOME}/oscarsamples/pkglists";
    } else {
        $oscarsamples_dir = "/usr/share/oscar/oscarsamples/pkglists";
    }

    if (! -d $oscarsamples_dir) {
        oscar_log(1, ERROR, "$oscarsamples_dir does not exists");
        return undef;
    }

    # We look if a package file exists for the exact distro we use. If not, we
    # use the package file for the compat distro.
    my $distro = $os->{distro};
    my $distro_ver = $os->{distro_version};
    my $distro_update = $os->{distro_update}; #this is optinal
    my $compat_distro = $os->{compat_distro};
    my $compat_distro_ver = $os->{compat_distrover};
    my $arch = $os->{arch};
    if (!OSCAR::Utils::is_a_valid_string ($distro) ||
        !OSCAR::Utils::is_a_valid_string ($distro_ver) ||
        !OSCAR::Utils::is_a_valid_string ($compat_distro) ||
        !OSCAR::Utils::is_a_valid_string ($compat_distro_ver) ||
        !OSCAR::Utils::is_a_valid_string ($arch)) {
            oscar_log(6, ERROR, "Impossible to extract distro information");
            return undef;
    }

    my $full_version;
    if (defined ($distro_update)) {
        $full_version = "$distro_ver.$distro_update";
    } else {
        $full_version = $distro_ver;
    }
    my $pkglist = "$oscarsamples_dir/$distro-$distro_ver-$arch.pkglist";
    if (! -f $pkglist) {
        oscar_log(5, WARNING, "pkglist: $pkglist not found. trying with specific".
             " version $compat_distro-$full_version-$arch.\n");
        $pkglist = "$oscarsamples_dir/$distro-$full_version-$arch.pkglist";
        if (! -f $pkglist) {
            oscar_log(5, WARNING, "pkglist: $pkglist not found. trying with".
                 " generic $compat_distro-$compat_distro_ver-$arch.\n");
            $pkglist = "$oscarsamples_dir/".
                       "$compat_distro-$compat_distro_ver-$arch.pkglist";
            if (! -f $pkglist) {
                oscar_log(1, ERROR, "No".
                    " $distro-$distro_ver-$arch suitable binary list file found".
                    " in $oscarsamples_dir/ to create the basic image\n".
                    "DISTRO NOT SUPPORTED");
                return undef;
            }
        }
    }

    oscar_log(6, INFO, "Identified distro of clients: $distro $distro_ver");
    oscar_log(5, INFO, "Using $pkglist as package list");

    return $pkglist;
}

################################################################################
# Get the default settings for the creation of new images.                     #
# !!WARNNING!! We do not set postinstall and title. The distro is also by      #
# default the local distro.                                                    #
# Input: none.                                                                 #
# Output: default settings (via a hash).                                       #
#         The format of the hash is the following is available within the code.#
################################################################################
sub get_image_default_settings () {
    # /tmp/error is provided if any error; further fdisk may produce
    # certain output such as raid partitions, but the following check should
    # work for grepping /dev/sd, further the check should also work when LVM
    # partitions. Replacing the previous "df" check.
    
    my @df_lines = `LC_ALL=C fdisk -l 2> /tmp/error |grep Disk`;
    my $disk_type = "ide";
    $disk_type = "scsi" if (grep(/\/dev\/sd/,(@df_lines)));

    #Get the distro list
    my $master_os = OSCAR::OCA::OS_Detect::open ("/");
    if (!defined $master_os) {
        oscar_log(1, ERROR, "Impossible to detect the distro on the headnode.");
        return undef;
    }

    oscar_log(9, INFO, "Detected OS:");
    OSCAR::Utils::print_hash ("", "", $master_os) if ($OSCAR::Env::oscar_verbose >= 9);

    my $arch = $master_os->{arch};
    my $pkglist = get_binary_list_file($master_os);
    if (!defined $pkglist) {
        oscar_log(5, ERROR, "Unable to get the package list for this distro.");
        return undef;
    }

    my $distro_pool = OSCAR::PackagePath::distro_repo_url();
    $distro_pool =~ s/\ /,/g;
    my $oscar_pool = OSCAR::PackagePath::oscar_repo_url();

    oscar_log(9, INFO, "Distro repo: $distro_pool");
    oscar_log(9, INFO, "OSCAR repo: $oscar_pool");
    oscar_log(6, INFO, "Using binary list: $pkglist");

    # Get a list of client RPMs that we want to install.
    # Make a new file containing the names of all the RPMs to install

#     my $outfile = "/tmp/oscar-install-rpmlist.$$";
#     create_list_selected_opkgs ($outfile);
#     my @errors;
#     my $save_text = $outfile;
#     my $extraflags = "--filename=$outfile";
    # WARNING!! We deactivate the OPKG management via SystemInstaller
    my $extraflags = "";
    if ($OSCAR::Env::oscar_verbose >= 5) {$extraflags .= " --verbose ";}

    my $diskfile = get_disk_file($arch, $disk_type);

    # Default settings
    my %vars = (
           # imgpath: location where the image is created
           imgpath => $si_config->default_image_dir,
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

###############################################################################
# Get the list of images from the SIS database (which is used to drive and    #
# settup SystemImager.                                                        #
#                                                                             #
# Input: None.                                                                #
# Return: List of images in the SIS database (via an array of image names),   #
#         undef if error.                                                     #
###############################################################################
sub get_systemimager_images () {
    my $sis_cmd = "/usr/bin/si_lsimage";

    oscar_log(7, ACTION, "About to run: $sis_cmd");
    my @sis_images = `$sis_cmd`;
    my $i;

    #We do some cleaning...
    # We remove the three useless lines of the result
    for ($i=0; $i<3; $i++) {
        shift (@sis_images);
    }
    # We also remove the last line which is an empty line
    pop (@sis_images);
    # Then we remove the return code at the end of each array element
    # We also remove the 2 spaces before each element
    oscar_log(9, INFO, "Got the following images:");
    foreach $i (@sis_images) {
        chomp $i;
        $i = substr ($i, 2, length ($i));
        oscar_log(9, NONE, "        - $i");
    }

    return @sis_images;
}

sub delete_image_from_oda ($) {
    my $imgname = shift;

    # We remove the image from ODA.
    my $sql = "DELETE FROM Images WHERE Images.name='$imgname'";

    oscar_log(6, ACTION, "Removing image $imgname from ODA.\n");
    if (OSCAR::Database::do_update($sql,"Images", undef, undef) == 0) {
        oscar_log(5, DB, "Failed to execute the SQL command $sql");
        return -1;
    }

    return 0;
}

################################################################################
# Delete an existing image.                                                    #
# Input: imgname, image name.                                                  #
# Output: 0 if success, -1 else.                                               #
# TODO: We need to update the OSCAR database when deleting an image.           #
################################################################################
sub delete_image ($) {
    my $imgname = shift;

    oscar_log(5, ACTION, "Deleting image: $imgname.");
    # If the image exists at the SystemImager level, we delete it
    my @si_images = get_systemimager_images ();
    if (OSCAR::Utils::is_element_in_array ($imgname, @si_images) == 1) {
#        my $config = SystemInstaller::Utils::init_si_config();
        my $rsyncd_conf = $si_config->rsyncd_conf();
        my $rsync_stub_dir = $si_config->rsync_stub_dir();

        oscar_log(6, ACTION, "Removing image $imgname from disk.");
        my $cmd = "/usr/bin/mksiimage -D --name $imgname --force";
        if (oscar_system($cmd)) {
            return -1;
        }
        require SystemImager::Server;
        oscar_log(6, ACTION, "Removing image stub.");
        SystemImager::Server::remove_image_stub($rsync_stub_dir, $imgname);
        oscar_log(6, ACTION, "Updating rsyncd config: $rsyncd_conf.");
        SystemImager::Server::gen_rsyncd_conf($rsync_stub_dir, $rsyncd_conf);
    }

    if (delete_image_from_oda ($imgname)) {
        oscar_log(5, ERROR, "Impossible to remove $imgname from the database.");
        return -1;
    }

    oscar_log(5, INFO, "Successfully deleted image: $imgname.");
    return 0;
}

sub add_corrupted_image ($$) {
    my ($res_ref, $entry_ref) = @_;

    # The deal here is the following: we want to avoid entry duplication, i.e.,
    # maintain info for a given image is a single hash. So before to add a new
    # entry to the hash, we check first if an entry is not already there that
    # we could update.
    
    my $image_name = $entry_ref->{'name'};
    oscar_log(6, INFO, "Adding/updating corruption data for $image_name");

    # We check whether an entry is already available or not.
    foreach my $e (@$res_ref) {
        if ($e->{'name'} eq $image_name) {
            # We update each key marked as "missing"
            foreach my $k (keys %$entry_ref) {
                if ($entry_ref->{$k} eq "missing") {
                    $e->{$k} = "missing";
                }
            }
            return 0;
        }
    }

    # If we reach this point, no entry for the image is already in the hash
    push (@$res_ref, $entry_ref);
    oscar_log (6, INFO, "Corrupted data for $image_name saved.");

    return 0;
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
#         undef if error.                                                      #
################################################################################
sub get_list_corrupted_images () {
    my @result = ();
    my @sis_images = get_systemimager_images ();
    my $image_name;

    # The array is now clean, we can print it
    oscar_log(6, INFO, "List of images in the SIS database:");
    print_array (@sis_images) if($OSCAR::Env::oscar_verbose >= 6);

    my @tables = ("Images");
    my @oda_images = ();
    my @res = ();
    my $cmd = "SELECT Images.name FROM Images";
    oscar_log(8, DB, "ODA query: $cmd;");
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
        oscar_log(6, INFO, "List of images in ODA:");
        print_array (@oda_images) if($OSCAR::Env::oscar_verbose >= 6);
    } else {
        oscar_log(5, DB, "ERROR: Cannot query ODA    =>  $cmd;");
        return undef;
    }

    # We get the list of images from the file system
    my $sis_image_dir = "/var/lib/systemimager/images";
    my @fs_images = ();
    if ( ! -d $sis_image_dir ) {
        oscar_log (5, ERROR, "The image directory does not exist ".
              "($sis_image_dir)");
        return undef;
    }
    opendir (DIRHANDLER, "$sis_image_dir")
        or (oscar_log (5, ERROR, "Impossible to open $sis_image_dir"), return undef);
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
    oscar_log(6, INFO, "List of images in file system:");
    print_array (@fs_images) if($OSCAR::Env::oscar_verbose >= 6);

    # We now compare the lists of images
    foreach $image_name (@sis_images) {
        my %entry = ('name' => $image_name,
                  'sis' => "ok",
                  'oda' => "ok",
                  'fs' => "ok");
        if (!is_element_in_array($image_name, @oda_images)) {
            $entry{'oda'} = "missing";
            add_corrupted_image (\@result, \%entry);
        }
        if (!is_element_in_array($image_name, @fs_images)) {
            $entry{'fs'} = "missing";
            add_corrupted_image (\@result, \%entry);
        }
    }

    foreach $image_name (@oda_images) {
        my %entry = ('name' => $image_name,
                  'sis' => "ok",
                  'oda' => "ok",
                  'fs' => "ok");
        if (!is_element_in_array($image_name, @sis_images)) {
            $entry{'sis'} = "missing";
            add_corrupted_image (\@result, \%entry);
        }
        if (!is_element_in_array($image_name, @fs_images)) {
            $entry{'fs'} = "missing";
            add_corrupted_image (\@result, \%entry);
        }
    }

    foreach $image_name (@fs_images) {
        my %entry = ('name' => $image_name,
                  'sis' => "ok",
                  'oda' => "ok",
                  'fs' => "ok");
        if (!is_element_in_array($image_name, @sis_images)) {
            $entry{'sis'} = "missing";
            add_corrupted_image (\@result, \%entry);
        }
        if (!is_element_in_array($image_name, @oda_images)) {
            $entry{'oda'} = "missing";
            add_corrupted_image (\@result, \%entry);
        }
    }

    return (@result);
}

sub get_list_images () {
    my @tables = ("Images");
    my @res = ();
    my $sql = "SELECT * FROM Images";
    oscar_log(8, DB, "ODA query: $sql;");
    if (!OSCAR::Database::single_dec_locked( $sql,
                                             "READ",
                                             \@tables,
                                             \@res,
                                             undef) ) {
        oscar_log(5, ERROR, "Failed to execute the SQL command:\n    => $sql");
        return undef;
    }

    # We reformat the result just to get the list of image names.
    my @images;
    foreach my $i (@res) {
        push (@images, $i->{'name'});
    }

    return @images;
}

################################################################################
# Check if a given image exists.                                               #
#                                                                              #
# Input: image_name, name of the image to check.                               #
# Return: 1 if the image already exists (true), 0 else (false), -1 if error.   #
# TODO: We should check in ODA and not the filesystem.                         #
################################################################################
sub image_exists ($) {
    my $image_name = shift;

    if (!OSCAR::Utils::is_a_valid_string ($image_name)) {
        oscar_log(6, ERROR, "Invalid image name.");
        return -1;
    }

    my @tables = ("Images");
    my @res = ();
    my $sql = "SELECT Images.name FROM Images WHERE Images.name='$image_name'";
    oscar_log(8, DB, "ODA query: $sql;");
    if ( OSCAR::Database::single_dec_locked( $sql,
                                             "READ",
                                             \@tables,
                                             \@res,
                                             undef) ) {
        if (scalar (@res) == 1) {
            return 1;
        } elsif (scalar (@res) == 0) {
            return 0;
        } else {
            oscar_log(5, ERROR, "Found ".scalar(@res)." images named $image_name");
            return -1;
        }
    }
    oscar_log(5, ERROR, "Failed to query ODA (image_exists)");
    return -1;
}

################################################################################
# Function that makes sure /proc is not mounted within an image.               #
#                                                                              #
# Input: image_path, path to the image.                                        #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub umount_image_proc ($) {
    my $image_path = shift;
    my $proc_status = 0; # tells if /proc is mounted or not (0 = not mounted,
                         # 1 = mounted)
    my $cmd = "/usr/sbin/chroot $image_path mount";
    oscar_log(7, ACTION, "About to run: $cmd");
    my @lines = split ('\n', `$cmd`);

    foreach my $line (@lines) {
        if ($line =~ /^proc/) {
            $proc_status = 1;
            last;
        }
    }

    if ($proc_status == 1) {
        $cmd = "/usr/sbin/chroot $image_path umount /proc";
        oscar_system ($cmd); # we do not check the return code because when creating
                             # the image, the status of /proc may not be coherent, so
                             # the command returns an error but this is just fine.
    }

    return 0;
}


# Clean up the SystemImager configuration files. For instance, this is used when
# the creation of an image fails: config files are updated by SystemImager so if
# the failure happens during the OSCAR part of the image creation, we must clean
# clean up the configuration files.
#
# Input: image, image name.
# Return: 0 if success, -1 else.
sub cleanup_sis_configfile ($) {
    my $image = shift;

    if (!OSCAR::Utils::is_a_valid_string ($image)) {
        oscar_log(6, ERROR, "Invalid image name.");
        return -1;
    }

    oscar_log(4, ACTION, "Cleaning up $image from flamethrower config.");
    my $flamethrower_conf = "/etc/systemimager/flamethrower.conf";
    require SystemImager::Common;
    SystemImager::Common->add_or_delete_conf_file_entry($flamethrower_conf, 
                                                        $image) or
        (oscar_log(5, ERROR, "Impossible to update the flamethrower config file."));

    SystemImager::Common->add_or_delete_conf_file_entry($flamethrower_conf, 
                                                        "override_$image") or
        (oscar_log(5, ERROR, "Impossible to update the flamethrower config file"));

    return 0;
}

################################################################################
# Create a basic image.                                                        #
#                                                                              #
# Input: image. image name to create.                                          #
#        vars, image configuration hash.                                       #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub create_image ($%) {
    my ($image, %vars) = @_;

    # We create a basic image for clients. Note that by default we do not
    # create a basic image for servers since the server may already be deployed.
    # We currently use the script 'build_oscar_image_cli'. This is a limitation
    # because it only creates an image based on the local Linux distribution.
    oscar_log(3, ACTION, "Creating the basic golden image...");

    $vars{imgname} = "$image";

    my $image_path = "$vars{imgpath}/$vars{imgname}";
    my $cmd = "mksiimage -A --name $vars{imgname} " .
            "--filename $vars{pkgfile} " .
            "--arch $vars{arch} " .
            "--path $image_path " .
            "--selectedopkgs ";
    $cmd .= "--distro $vars{distro} " if defined $vars{distro};
    if (!defined $vars{distro} && defined $vars{pkgpath}) {
        $cmd .= "--location $vars{pkgpath} ";
    }
    $cmd .= " $vars{extraflags} --verbose";

    if (oscar_system ($cmd)) {
        oscar_log(5, ERROR, "Failed to build the image.");
        cleanup_sis_configfile ($image);
        return -1;
    }

    # Add image data into ODA
    my %image_data = ("name" => $image,
                      "path" => "$vars{imgpath}/$vars{imgname}",
                      "architecture" => "$vars{arch}");
    if (OSCAR::Database::set_images (\%image_data, undef, undef) != 1) {
        oscar_log(5, ERROR, "Impossible to store image data into ODA.");
        cleanup_sis_configfile ($image);
        return -1;
    }

    # Deal with the harddrive configuration of the image

    # 1st, create the final diskfile
    my($filename, $dirs, $suffix) = fileparse($vars{diskfile},"disk");

    my($tmp_fh, $temp_diskfile) = mkstemps( $filename."_XXXXXX", $suffix);

    oscar_log(5, INFO, "");
    open my $template_fh,"<", $vars{diskfile}
        or (oscar_log(1, ERROR, "Failed to open $vars{diskfile}"), close $tmp_fh, return -1);

    oscar_log(5, INFO, "Generating $temp_diskfile from $vars{diskfile} using:");
    oscar_log(5, INFO, "Boot_filesystem:$vars{boot_filesystem} Root_filesystem:$vars{root_filesystem}");
    oscar_log(5, NONE, "----- $temp_diskfile -----");
    while (my $line = <$template_fh>) {
        $line =~ s/_BOOTFS_/$vars{boot_filesystem}/;
        $line =~ s/_ROOTFS_/$vars{root_filesystem}/;
        print $tmp_fh $line;
        oscar_log(5, NONE, "> $line");
    }

    close $tmp_fh;
    oscar_log(5, NONE, "----- end -----");

    # 2nd: Run mksidisk.
    $cmd = "mksidisk -A --name $vars{imgname} --file $temp_diskfile";
    if( oscar_system($cmd) ) {
        cleanup_sis_configfile ($image);
        return -1;
    }

    # 3rd: Now we execute the post image creation actions.
    if (postimagebuild (\%vars)) {
        oscar_log(5, ERROR, "Failed to run postimagebuild.");
        cleanup_sis_configfile ($image);
        return -1;
    }

    oscar_log(3, INFO, "OSCAR image successfully created.");

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
    use constant MAX_LABEL_LENGTH  =>  12;

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
        oscar_log(5, ERROR, "The file $file exists but does not have a default boot ".
             "or a default label.");
        return -1;
    }

    if ($default_boot ne $default_label) {
        oscar_log(1, WARNING, "[SystemConfigurator] the default boot kernel is not the kernel0 we ".
                     "do not know how to deal with that situation.");
#        print STDERR "WARNING: the default boot kernel is not the kernel0 we ".
#                     "do not know how to deal with that situation";
        return 1;
    }

    if (length ($default_boot) > MAX_LABEL_LENGTH) {
        if (OSCAR::ConfigFile::set_value($file,
                                         "BOOT",
                                         "DEFAULTBOOT",
                                         "default_kernel")) {
            oscar_log(5, ERROR, "Impossible to update the default boot kernel.");
            return -1;
        }
        if (OSCAR::ConfigFile::set_value($file,
                                         "KERNEL0",
                                         "LABEL",
                                         "default_kernel")) {
            oscar_log(5, ERROR, "Impossible to update the label of the default kernel.");
            return -1;
        }
    }

    return 0;
}

################################################################################
# Update the etc/systemconfig/systemconfig.conf file of a given image to       #
# include some kernel parameters (the APPEND option).                          #
#                                                                              #
# Return: 0 if success, -1 else.                                               #
# TODO: we currently assume only one kernel is setup. Yes this is lazy and     #
# this needs to be updated                                                     #
################################################################################
sub update_kernel_append ($$) {
    my ($imgdir, $append_str) = @_;

    oscar_log(3, SUBSECTION, "Adding boot parameter ($append_str) for image ".
                          "$imgdir");
    my $file = "$imgdir/etc/systemconfig/systemconfig.conf";
    require OSCAR::ConfigFile;
    if (OSCAR::ConfigFile::set_value ($file, "KERNEL0", "\tAPPEND",
                                      "\"$append_str\"")) {
        oscar_log(5, ERROR, "Impossible to add $append_str as boot parameter in $file");
        return -1;
    }

    return 0;
}

################################################################################
# Make sure the basic GRUB files exists into a given image (some distro are    #
# more picky than others.                                                      #
#                                                                              #
# Input: Path, path to the image.                                              #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub update_grub_config ($) {
    my $path = shift;

    $path .= "/boot";
    if (!-d $path) {
        oscar_log(5, ERROR, "[update_grub_config] $path does not exist.");
        return -1;
    }

    $path .= "/grub";
    if (!-d $path) {
        mkdir $path;
    }

    $path .= "/menu.lst";
    if (!-f $path) {
        my $cmd = "touch $path";
        if (oscar_system $cmd) {
            return -1;
        }
    }

    return 0;
}

# This update the modprobe.conf file for a given image. The content that needs
# to be added is static since it currently only aims to enable the creation of
# a valid initrd for RHEL-5 based systems.
#
# Input: image_path, path of the image for which the update has to be done.
# Return: 0 if success, -1 else.
sub update_modprobe_config ($) {
    my $image_path = shift;
    my $cmd;

    if (! -d $image_path) {
        oscar_log(5, ERROR, "$image_path does not exist.");
        return -1;
    }

    my $modprobe_conf = "$image_path/etc/modprobe.conf";
    my $content = "alias scsi_hostadapter1 amd74xx ata_piix";
    if (OSCAR::FileUtils::add_line_to_file_without_duplication (
            $content,
            $modprobe_conf)) {
        oscar_log(5, ERROR, "Impossible to add $content into $modprobe_conf");
        return -1;
    }

    return 0;
}

# Return: 0 if success, -1 else.
sub update_image_initrd ($) {
    my $imgpath = shift;
    my $cmd;

    oscar_log(4, INFO, "Updating initrd for image($imgpath).");
    # First we create a "fake" fstab. The problem is the following: nowadays,
    # binary packages for kernels try to create the initrd on the fly, based
    # on configuration data. This is not compliant with the old systemimager
    # idea where the initrd is created at the end of the image deployment. So
    # we trick the configuration to allow the kernel package to generate the
    # initrd.

    # Currently the problem has been reported only for RPM based distros
    my $os = OSCAR::OCA::OS_Detect::open ($imgpath);
    if (!defined $os) {
        oscar_log(6, ERROR, "Impossible to detect image distro ($imgpath).");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    return 0 if ($os->{pkg} ne "rpm");

    if (! -d $imgpath) {
        oscar_log(6, ERROR, "Impossible to find the image ($imgpath).");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }

    # The /etc/systemconfig/systemconfig.conf should exist in the image.    
    my $systemconfig_file = "$imgpath/etc/systemconfig/systemconfig.conf";
    if (! -f $systemconfig_file) {
        oscar_log(6, ERROR, "$systemconfig_file does not exist.");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    use OSCAR::ConfigFile;
    my $root_device = OSCAR::ConfigFile::get_value ($systemconfig_file,
        "BOOT", "ROOTDEV");
    if (!OSCAR::Utils::is_a_valid_string ($root_device)) {
        oscar_log(6, ERROR, "Impossible to get the default root device");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    my $fake_fstab = "$imgpath/etc/fstab.fake";
    $cmd = "echo \"$root_device  /  ext3  defaults  1 1\" >> $fake_fstab";
    if (oscar_system ($cmd)) {
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    if (! -f $fake_fstab) {
        oscar_log(6, ERROR, "$fake_fstab does not exist");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }

    # TODO: We currently assume the kernel0 is the one we boot up, this is
    # not necessarily the case right now.
    my $initrd = OSCAR::ConfigFile::get_value ($systemconfig_file,
        "KERNEL0", "INITRD");
    my $version = OSCAR::ConfigFile::get_value ($systemconfig_file,
        "KERNEL0", "PATH");
    if (!OSCAR::Utils::is_a_valid_string ($version)) {
        oscar_log(6, ERROR, "Impossible to detect the image kernel version ($imgpath).");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    if ($version =~ /\/boot\/vmlinuz-(.*)/) {
        $version = $1;
    } else {
        oscar_log(6, ERROR, "Impossible to get the version ($version)");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    my $chroot_bin = "/usr/sbin/chroot";
    if (! -f $chroot_bin) {
        oscar_log(6, ERROR, "The chroot binary ($chroot_bin) is not available");
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }
    # OL: Temporary fix to support dracut using mkinitrd alias. the alias is in /usr/bin, no /sbin, thus the fix.
    my $mkinitrd_cmd="/sbin/mkinitrd";
    $mkinitrd_cmd="/usr/bin/mkinitrd" if ( -f "/usr/bin/mkinitrd" );
    # OL: End of tmp fix. (should be replaced with OS_Settings::getitem).
    $cmd = "$chroot_bin $imgpath $mkinitrd_cmd -v -f --fstab=/etc/fstab.fake ".
           "--allow-missing $initrd $version";
    if (oscar_system ($cmd)) {
        oscar_log(4, ERROR, "Failed to update initrd for image($imgpath).");
        return -1;
    }

    oscar_log(4, INFO, "Successuflly updated initrd for image($imgpath).");
    return 0;
}

# Return: 0 if success, -1 else.
sub postimagebuild {
    my ($vars) = @_;
    my $img = $$vars{imgname};
    my $interface;
    my %options;

    require OSCAR::ConfigFile;
    oscar_log (3, INFO, "Doing postimagebuild actions.");
    $interface = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf",
                                               undef,
                                               "OSCAR_NETWORK_INTERFACE");

    oscar_log (4, INFO, "Setting up image in the database.");
    if (do_setimage ($img, %options)) {
        oscar_log(4, ERROR, "Failed to set image.");
        return -1;
    }

    oscar_log (4, INFO, "Doing post binary package install.");
    if (do_post_image_creation ($vars) == 0) {
        oscar_log(4, ERROR, "Impossible to do post binary package install, ".
             "deleting the image...");
        if (delete_image ($img)) {
            oscar_log(5, ERROR, "Impossible to delete image $img");
        }
        return -1;
    }

    oscar_log (4, INFO, "Doing ODA update.");
    if (do_oda_post_install ($vars, \%options)) {
        oscar_log(4, ERROR, "Impossible to update data in ODA, deleting image...");
        if (delete_image ($img)) {
            oscar_log(5, ERROR, "Impossible to delete image $img");
        }
        return -1;
    }

    oscar_log (3, INFO, "Successfully processed postimagebuild actions.");
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
        oscar_log(5, ERROR, "Install Opkg into image: invalid parameters.");
        return -1;
    }

    my $image_path = "$images_path/$image";
    oscar_log(4, INFO, "Installing OPKGs into image $image ($image_path).");
    oscar_log(5, INFO, "List of OPKGs to install: ". join(" ", @opkgs));

    # To install OPKGs, we use Packman, creating a specific packman object for
    # the image.
    my $pm = PackMan->new->chroot ($image_path);
    if (!defined ($pm)) {
        oscar_log(5, ERROR, "Failed to create a Packman object for the ".
                            "installation of OPKGs into the golden image.");
        return -1;
    }

    # We assign the correct repos to the PackMan object.
    my $os = OSCAR::OCA::OS_Detect::open(chroot=>$image_path);
    if (!defined ($os)) {
        oscar_log(5, ERROR, "Impossible to detect the OS of the image ($image_path)");
        return -1;
    }
    my $image_distro = "$os->{distro}-$os->{distro_version}-$os->{arch}";
    oscar_log(5, INFO, "Detected Image distro: $image_distro");
    require OSCAR::RepositoryManager;
    my $rm = OSCAR::RepositoryManager->new (distro=>$image_distro);

    # GV: do we need to install only the client side of the OPKG? or do we also
    # need to install the api part.
    my @opkgs2install = map { "opkg-".$_."-client" } @opkgs;
    oscar_log(4, ACTION, "Installing: ".join(', ',@opkgs));
    # Once we have the packman object, it is fairly simple to install opkgs.
    my ($ret, @out) = $rm->install_pkg($image_path, @opkgs2install);
    if ($ret) {
        oscar_log(5, ERROR, "Failed to install client opkgs:\n".join("\n", @out));
        return -1;
    }

    oscar_log(4, INFO, "Successfully Installed OPKGs into image $image.");
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

    oscar_log(6, INFO, "Exporting an image.");
    if (!defined ($partition) || !defined ($dest)) {
        oscar_log(5, ERROR, "Export image: invalid arguments.");
        return -1;
    }

    my $tarball = "$dest/image-$partition.tar.gz";
    my $temp_dir = "$dest/temp-$partition";

    require File::Path;

    if (! -d $dest) {
        oscar_log(5, ERROR, "The destination directory does not exist.");
        return -1;
    }
    if (-f $tarball) {
        oscar_log(5, ERROR, "The tarball already exists ($tarball)");
        return -1;
    }

    if (image_exists ($partition) == 1) {
        oscar_log(6, INFO, "The image already exists (no need to build it).");

        # the image already exists we just need to create the tarball
        my $cmd = "cd $images_path/$partition; tar czf $tarball *";
        if (oscar_system ($cmd)) {
            oscar_log(5, ERROR, "Impossible to create the tarball.");
            return -1;
        }
    } else {
        oscar_log(6, INFO, "The image does not exist (need to build it).");
        if (-d $temp_dir) {
            rmtree ($temp_dir);
        }

        # We get the default settings for images.
        my %image_config = OSCAR::ImageMgt::get_image_default_settings ();
        if (!%image_config) {
            oscar_log(5, ERROR, "Impossible to get default image settings.");
            return -1;
        }
        $image_config{imgpath} = $temp_dir;
        # If the image does not already exists, we create it.
        oscar_log(6, ACTION, "Building image into $temp_dir");
        if (OSCAR::ImageMgt::create_image ($partition, %image_config)) {
            oscar_log(5, ERROR, "Failed to create the basic image.");
            rmtree ($temp_dir);
            return -1;
        }

        # the image is ready to be tared!
        my $cmd = "cd $temp_dir; tar czf $tarball *";
        if (oscar_system ($cmd)) {
            oscar_log(5, ERROR, "Failed to create the tarball.");
            rmtree ($temp_dir);
            return -1;
        }

        oscar_log(6, ACTION, "Cleaning up $temp_dir");
        rmtree ($temp_dir);
    }
    oscar_log(6, INFO, "Image successfully exported.");
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
    delete_image_from_oda
    do_setimage
    do_post_image_creation
    do_oda_post_install
    export_image
    get_image_default_settings
    get_list_corrupted_images
    image_exists
    install_opkgs_into_image
    upgrade_grub_config
    update_systemconfigurator_configfile

