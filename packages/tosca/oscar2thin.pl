#!/usr/bin/perl
# oscar2thin:  Conversion of a plain oscar image to ramdisk image
# Michel Barrette 7 sept  2002
#
# Generalization, PERL usage and OSCAR integration by Benoit des Ligneris
# benoit@des.ligneris.net, 25-11-2002

use strict;
use Getopt::Long;

my $size =  '80';           # size in Mb (FIXME can be specified from the actual file size !)
my $clean_module = '';      # Clean the module or not
my $clean_rpm_base = '1';   # Clean the RPM base or not
my $inet = '192.168.0.1';   # network address of the server
my $netmask = '255.255.255.255';   # network address of the server
my $image = '';             # image name (from /var/lib/systemimager/images/*)
my $file =  'thinimage.img';# Name (default=thinimage.img)
my $help =  '';             # help
my $verbose = '';           # verbose

GetOptions ('size=f'=>\$size,
            'image=s'=>\$image, 
            'file=s'=>\$file,
            'help|h'=>\$help,
            'verbose|v' => \$verbose,
            'rmmodule'=>\$clean_module,
            'rmrpm'=>\$clean_rpm_base,
            'inet=s'=>\$inet,
            'netmask=s'=>\$netmask);

if ($help || !$image) {
    display_help();
    die();
}

my $image_path="/var/lib/systemimager/images/".$image;
my $server_name="nfs_oscar";

create_blank_image();
copy_sis_to_image();
generate_fstab();
generate_network_functionality();
create_host_pbs_config_file();
clean_stuff();
unmount_thin_image_compress_move();
create_exports_pxe_default();
display_todo();

# Create a blank image and mount it
sub create_blank_image{
    my $cmd="dd if=/dev/zero of=$file bs=1024k count=$size";
    exec_command($cmd);
    $cmd="mkfs.ext2 -F $file";
    exec_command($cmd);
    $cmd="mkdir -p $file.mnt";
    exec_command($cmd);
    $cmd="mount -t ext2 -o loop $file $file.mnt";
    exec_command($cmd);
}
# Copy all dir except /usr and /opt from SIS image to mounted diskless image
sub copy_sis_to_image{
    my $cmd="cp -a $image_path/{bin,boot,dev,etc,home,initrd,lib,mnt,proc,root,sbin,tmp,var} $file.mnt";
    exec_command($cmd);
    $cmd="mkdir $file.mnt/usr $file.mnt/opt";
    exec_command($cmd);
}
# Generation of /etc/fstab (/,/opt, /usr, /home, /dev/pts,/proc) in the diskless image
sub generate_fstab{
    open(FSTAB,">$file.mnt/etc/fstab") || die("Impossible to open $file.mnt/etc/fstab for writing");
    print FSTAB "/dev/ram0  /  ext2 defaults 1 2";
    print FSTAB "$server_name:$image_path/opt /opt nfs defaults 0 0";
    print FSTAB "$server_name:$image_path/usr /usr nfs defaults 0 0";
    print FSTAB "$server_name:/home /home nfs defaults 0 0";
    print FSTAB "none /dev/pts devpts mode=0622 0 0";
    print FSTAB "none /proc proc defaults   0 0";
    close(FSTAB);
}
# Generation of /etc/sysconfig/network and /etc/sysconfig/network-scripts/ifcfg-eth0
sub generate_network_functionality{
    open(NET,">$file.mnt/etc/sysconfig/network") || die("Impossible to open $file.mnt/etc/sysconfig/network for writing");
    print NET "NETWORKING=yes";
    close(NET);
    open(NET,">$file.mnt/etc/sysconfig/network-scripts/ifcfg-eth0") || die("Impossible to open $file.mnt/etc/sysconfig/network-scripts/ifcfg-eth0 for writing");
    print NET "DEVICE=\"eth0\"\n";
    print NET "BOOTPROTO=\"dhcp\"\n";
    print NET "ONBOOT=\"yes\"\n";
    close(NET);
}
# Set /etc/hosts, /var/spool/pbs/server_name and config pbs_mom
sub create_host_pbs_config_file{
    # Copy the /etc/hosts
    my $cmd="cp -p /etc/hosts $file.mnt/etc/hosts";
    exec_command($cmd);
    # Set the pbs server name
    $cmd="echo \"pbs_oscar\" >$file.mnt/var/spool/pbs/server_name";
    exec_command($cmd);
    # Set the config for pbs_mom
    open(PBS_MOM,">$file.mnt/var/spool/pbs/mom_priv/config") || die("Error writing to $!");
    print PBS_MOM "\$clienthost $server_name\n";
    print PBS_MOM "\$usecp $server_name:/home /home\n";
    print PBS_MOM "\$restricted $server_name\n";
    close(PBS_MOM);
}
# Cleaning some stuff : rpm database, /lib/module, ... (any ideas ?)
sub clean_stuff{
    # Remove the /lib/module directories
    # Useful for monolithic kernels to gain some disk space !
    if ($clean_module) {
        my $cmd = "rm -rf $file.mnt/lib/modules";
        exec_command($cmd);
    }

    # Remove the RPM database.
    # Usefule to suppress useless info ;-0)
    if ($clean_rpm_base) {
        my $cmd="rm -rf $file.mnt/var/lib/rpm";
        exec_command($cmd);
    }
}
# Umount thin image and suppress dir
sub unmount_thin_image_compress_move{
    my $cmd="umount $file";
    exec_command($cmd);
    $cmd="sync;sleep 2";
    exec_command($cmd);
    $cmd="rmdir $file.mnt";
    exec_command($cmd);
    $cmd="gzip $file";
    exec_command($cmd);
    $cmd="mv $file.gz /tftpboot/";
    exec_command($cmd);
}
# Create /etc/exports and /etc/tftpboot/pxelinux.cfg/default
sub create_exports_pxe_default{
    open(EXPORTS,">/etc/exports") || die("Impossible to open $! for writing!");
    print EXPORTS "/home $inet/$netmask(rw,no_root_squash)\n";
    print EXPORTS "$image_path $inet/$netmask(ro,no_root_squash)\n";
    close EXPORTS;
   
    open(TFTPBOOT,">/tftpboot/pxelinux.cfg/default") || die ("Impossible to open $! for writing!");
    print TFTPBOOT "DEFAULT bzImage\n";
    print TFTPBOOT "APPEND initrd=$file.gz devfs=nomount root=/dev/ram0\n";
    close TFTPBOOT;
}
# Execute a command and display the command if in verbose mode
sub exec_command{
    my $cmd=shift;
    if ($verbose) {
        print "$cmd\n";
    }
    return system($cmd);
}
# Display the help
sub display_help{
    print <<fin666
    
usage: ./oscar2thin.pl -image=oscarimage

! You must supply an image name !

Arguments :
-image=  : name of a valid systemimager image found in /var/lib/systemimager/images

Optional Arguments :
-size=    : maximum size (in Mb) of the complete image. 80 Mb by default
-name=    : name of the thin-client image (thinimage.img by default)
-inet=    : IP address of the server (192.168.0.1)
-netmask= : netmask of the cluster (255.255.255.0)

Options :
-rmmodule: remove the modules (usefull for monolythic kernels)
-rmrpm   : remove the rpm database (set by default)
-help    : this help
-verbose : verbose level (on|off)

fin666
}
# Display the things todo
sub display_todo{
    print <<fin666

    If you have a working kernel for you diskless clients named bzImage in
    /tftpboot/ then, if you reboot your clients, they should now
    boot diskless depending on the BIOS boot order.

    You have to configure the image to use DHCP (static not supported for the moment)

    Your /etc/exports files and /tftpboot/pxe.cfg/default have been overwritten by this script.

    Support for per node configuration and static IP should come soon as well as initial 
    ramdisk (ie modular kernel !) and root-raid-ram disk so that we will be able to use
    stock kernel from distributions !

    Hints, ideas, suggestions : benoit at des.ligneris.net

fin666
}
# Convert an IP address into an hexadecimal
sub ip_to_hexa{
# Note : with this, we can have a personalized (by IP) config file
# for each node according to it's IP /tftpboot/pxe.cfg/HEXANUMBER
# where HEXANUMBER is the number return by this function
my $ip = shift;
my @data = split (/[.]/,$ip);
my $res = "";
my $nombre;
foreach $nombre (@data)
        {
        $res .= dec_hex($nombre);
        }
return $res;
}
# Convert a decimal number to hexadecimal
sub dec_hex{

        # Conversion en hexa 8 chiffres
        my $out = unpack("H8",pack("N", $_[0]));
        # Extrait les deux derniers bits (1-256)
        $out =~ s/^......(..)$/$1/;
        # Met tout en majuscules
        $out = uc($out);
        return $out;
}
