README for OSCAR vOSCARVERSION with Red Hat Enterprise Linux 3

Date:   Fri Feb 18 13:08:44 PST 2005

Author: David Lombard <david.n.lombard@intel.com>
        Yves Trudeau <yves.trudeau@revolutionlinux.com>
        Fernando Camargos <fernando@revolutionlinux.com>

Notes:

1) These instructions are for Red Hat Enterprise Linux 3 (Update 3); users
of the Gold or Update 2 versions will want to pay particular attention to
Step A2 (x86) or B2 (ia64).

2) If you are building an x86-based cluster, please see steps A1 through A3.

3) If you are building an ia64-based cluster, please see steps B1 through B7.


-----------------------
A1) mysql-server on x86
-----------------------

BEFORE YOU BEGIN: you will need to obtain a mysql-server RPM and put it into
/tftpboot/rpm.  The easiest way is to get the SRPM and rebuild it,

  # rpmbuild --rebuild mysql-3.23.58-1.src.rpm
  # cp /usr/src/redhat/RPMS/i386/mysql-server-3.23.58-1.i386.rpm /tftpboot/rpm

MySQL v3.23.58-1 is the version that came with Red Hat Enterprise Linux 3,
Update 3; if you cannot find that particular version, please make sure that
you copy all the rebuilt MySQL RPMs (including the server RPM).  For example,
if the version you could find is v3.23.58-2.3:

  # rpmbuild --rebuild mysql-3.23.58-2.3.src.rpm
  # cp /usr/src/redhat/RPMS/i386/mysql*-3.23.58-2.3.i386.rpm /tftpboot/rpm 

The key is to keep the MySQL versions consistent.

----------------------------------------------------------------
A2) Red Hat Enterprise Linux 3 (Gold or Update 2) rpmlist on x86
----------------------------------------------------------------
 
IN OSCAR WIZARD STEP 4: if you're running an earlier version than Update 3,
you will need to manually select the correct rpmlist before generating the
client image.

  /opt/oscar/oscarsample/redhat-3asU2-i386.rpmlist

----------------------
A3) tftp-server on x86
----------------------

AFTER OSCAR WIZARD STEP 6, BEFORE YOU BOOT THE CLIENT NODES: you will need to
replace the TFTP server.  If your distribution does not come with a tftp-server
package you should download and install the appropriate file from a repository.

Once you have downloaded and copied it to a known directory you must install
the package and turn it on:

  # rpm -i tftp-server-0.32-4.i386.rpm  
  # chkconfig tftp on 


------------------------
B1) mysql-server on ia64
------------------------

BEFORE YOU BEGIN: you will need to obtain a mysql-server RPM and put it into
/tftpboot/rpm.  The easiest way is to get the SRPM and rebuild it,

  # rpmbuild --rebuild mysql-3.23.58-1.src.rpm
  # cp /usr/src/redhat/RPMS/ia64/mysql-server-3.23.58-1.ia64.rpm /tftpboot/rpm

MySQL v3.23.58-1 is the version that came with Red Hat Enterprise Linux 3,
Update 3; if you cannot find that particular version, please make sure that
you copy all the rebuilt MySQL RPMs (including the server RPM).  For example,
if the version you could find is v3.23.58-2.3:

  # rpmbuild --rebuild mysql-3.23.58-2.3.src.rpm
  # cp /usr/src/redhat/RPMS/ia64/mysql*-3.23.58-2.3.ia64.rpm /tftpboot/rpm 

The key is to keep the MySQL versions consistent.

-----------------------------------------------------------------
B2) Red Hat Enterprise Linux 3 (Gold or Update 2) rpmlist in ia64
-----------------------------------------------------------------
 
IN OSCAR WIZARD STEP 4: if you're running an earlier version than Update 3,
you will need to manually select the correct rpmlist before generating the
client image.

  /opt/oscar/oscarsample/redhat-3asU2-ia64.rpmlist

---------------------------------
B3) Initrd and elilo.conf on ia64
---------------------------------

AFTER OSCAR WIZARD STEP 4: there is a problem generating a valid initrd on the
nodes, so we must provide one in the image.  Copy a valid initrd to image
directory

  /var/lib/systemimager/images/oscarimage/boot/efi/EFI/redhat

with the commands

  # cp /boot/efi/efi/redhat/initrd-*.img \
    /var/lib/systemimager/images/oscarimage/boot/efi/EFI/redhat/
    
  # cp /boot/efi/efi/redhat/elilo.conf \
    /var/lib/systemimager/images/oscarimage/boot/efi/EFI/redhat/

-----------------------------
B4) systemconfig.conf on ia64
-----------------------------
 
AFTER OSCAR WIZARD STEP 4: you will need to add an INITRD entry to the image
file

  /var/lib/systemimager/images/oscarimage/etc/systemconfig/systemconfig.conf

After the modification, the kernel section should look like this:

  [KERNEL0]
    PATH = /boot/efi//EFI/redhat/vmlinuz-2.4.21-20.EL
    INITRD = /boot/efi//EFI/redhat/initrd-2.4.21-20.EL.img
    LABEL = 2.4.21-20.EL

where 2.4.21-20.EL is the kernel for Red Hat Enterprise Linux 3 (Update 3)
you should substitute your kernel version if you're not running Update 3.

NOTE CAREFULLY THE DOUBLE SLASH IN THE PATH AND INITRD LINES!

----------------------------
B5) SCSI and network on ia64
----------------------------

AFTER OSCAR WIZARD STEP 4: you may also need to add a Hardware section with
SCSI and network drivers.  In the image file

  /var/lib/systemimager/images/oscarimage/etc/systemconfig/systemconfig.conf

the hardware section of this file would look like for an Intel SR870BH2:

  [HARDWARE]
    ORDER = e1000 e1000 mptscsih mptbase scsi_mod

---------------
B6) USB on ia64
---------------

AFTER OSCAR WIZARD STEP 4: if you need to use the keyboard on a USB-only
system, like the Intel SR870BH2, you need to add the USB controller to the
image file:

  /var/lib/systemimager/images/oscarimage/etc/modules.conf

For example,

  # echo alias usb-controller usb-uhci >> \
    /var/lib/systemimager/images/oscarimage/etc/modules.conf

-----------------------
B7) tftp-server on ia64
-----------------------

AFTER OSCAR WIZARD STEP 6, BEFORE YOU BOOT THE CLIENT NODES: you will need to
replace the TFTP server.  If your distrubition doesn't come with a tftp-server
package you should download and install the appropriate file from a repository.

Once you have downloaded and copied it to a known directory you must install
the package and turn it on:

  # rpm -i tftp-server-0.32-4.ia64.rpm  

  # /sbin/chkconfig --level 345 tftp on 
