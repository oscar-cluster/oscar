package OSCAR::pxegrub;

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

#   Copyright 2008 Oak Ridge National Laboratory
#                  Geoffroy Vallee <valleegr@ornl.gov>
#

use strict;
use vars qw($VERSION @EXPORT);
use File::Basename;
use OSCAR::Utils;
use OSCAR::Logger;
use OSCAR::PxegrubConfigManager;
use Carp;

@EXPORT = qw(
            install_pxegrub
            setup_pxegrub
            );

my $verbose = 1;

################################################################################
# Check whether a given NIC is supported or not.                               #
#                                                                              #
# Input: config_file, path of the configuration file.                          #
#        nic_id, identifier of the NIC to check.                               #
# Return: 1 if the NIC is support, 0 if not, -1 if error.                      #
################################################################################
sub is_a_valid_nic ($) {
    my ($nic_id) = @_;

    # We get the configuration from the OSCAR configuration file.
    my $pxegrub_configurator = OSCAR::PxegrubConfigManager->new();
    if ( ! defined ($pxegrub_configurator) ) {
        carp "ERROR: Impossible to get the pxegrub configuration\n";
        return undef;
    }
    my $config = $pxegrub_configurator->get_config();

    my $nics_file = $config->{nics_deffile};
    print "Path of the file giving the list of supported NICs: $nics_file\n"
        if $verbose;

    # We read the file with the list of supported NICs. The result is in an 
    # array.
    my @supported_nics = load_supported_nics ($nics_file);
    if (scalar(@supported_nics) <= 0) {
        carp "ERROR: Impossible to load the supported NICs";
        return -1;
    }

    # Know we check whether the NIC is in the array or not.
    if (is_element_in_array ($nic_id, @supported_nics) == 1) {
        return 1;
    } else {
        return 0;
    }
}

sub load_supported_nics ($) {
    my ($file) = @_;

    my @supported_nics;
    my $line;

    print "Opening file: $file\n" if $verbose;
    open(DAT, $file);
    while ($line = <DAT>) {
        my ($id, $desc) = split (" | ", $line);
        push (@supported_nics, $id);
    }
    close (DAT);

    OSCAR::Utils::print_array(@supported_nics) if $verbose;

    return @supported_nics;
}

sub setup_pxegrub ($) {
    my $nic_id = shift;
    my $cmd;
    my $dest = "/home/gvh/temp";

    if (!is_a_valid_nic ($nic_id)) {
        carp "ERROR: Unsupported NIC";
        return undef;
    }

    # We get the configuration from the OSCAR configuration file.
    my $pxegrub_configurator = OSCAR::PxegrubConfigManager->new();
    if ( ! defined ($pxegrub_configurator) ) {
        carp "ERROR: Impossible to get the pxegrub configuration\n";
        return undef;
    }
    my $config = $pxegrub_configurator->get_config();
    my $url = $config->{download_url};

    # Download the Grub source code.
    my $file = OSCAR::Utils::download_file ($url, $dest);

    # Untar it
    $cmd = "cd $dest; tar xzf $file";
    oscar_log_subsection "Executing: $cmd" if $verbose;
    if (system ($cmd)) {
        carp "ERROR: Impossible to untar the file ($file)";
        return undef;
    }

    # We patch grub (yes it sucks, w/ newer gcc, grub does not compile when the
    # diskless option is activated.
    my $dir = basename ("$file", ".tar.gz");
    patch_grub ("$dest/$dir");

    # Set it up
    $cmd = "cd $dest/$dir; ./configure --enable-$nic_id --enable-diskless";
    oscar_log_subsection "Executing: $cmd" if $verbose;
    if (system ($cmd)) {
        carp "ERROR: Impossible to setup grub ($cmd)";
        return undef;
    }

    # Compile it
    $cmd = "cd $dest/$dir; make";
    oscar_log_subsection "Executing: $cmd" if $verbose;
    if (system ($cmd)) {
        carp "ERROR: Impossible to compile grub ($cmd)";
        return undef;
    }

    # We are done
    return "$dest/$dir";
}

sub patch_grub ($) {
    my $path = shift;
    my $cmd = "cd $path; patch -Np1 << EOF
--- grub-0.97.orig/netboot/main.c       2004-05-21 00:19:33.000000000 +0200
+++ grub-0.97/netboot/main.c    2007-07-20 02:31:28.000000000 +0200
@@ -54,9 +54,9 @@

 static int vendorext_isvalid;
 static unsigned long netmask;
-static struct bootpd_t bootp_data;
+struct bootpd_t bootp_data;
 static unsigned long xid;
-static unsigned char *end_of_rfc1533 = NULL;
+unsigned char *end_of_rfc1533 = NULL;

 #ifndef        NO_DHCP_SUPPORT
 #endif /* NO_DHCP_SUPPORT */
EOF";

    if (system ($cmd)) {
        carp "ERROR: Impossible to patch grub ($cmd)";
        return -1;
    }
    return 0;
}

sub install_pxegrub ($) {
    my $nic_id = shift;

    my $path = setup_pxegrub ($nic_id);
    if (!defined ($path)) {
        carp "ERROR: Impossible to setup Grub for your configuration";
        return -1;
    }

    my $cmd = "cd $path; cp stage2/nbgrub /tftpboot";
    oscar_log_subsection "Executing: $cmd" if $verbose;
    if (system($cmd)) {
        carp "ERROR: Impossible to install Grub ($cmd)";
        return -1;
    }

    return 0;
}

1;
