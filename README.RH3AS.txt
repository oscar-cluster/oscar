README for OSCAR 4.0 with Red Hat Enterprise Linux 3 AS

Date: 2004/12/13

Author: David Lombard
        Yves Trudeau <yves.trudeau@revolutionlinux.com>
        Fernando Camargos <fernando@revolutionlinux.com>

Note: These instructions are for Red Hat Enterprise Linux 3 (Update 3); see
Step 2 if you are using the Gold or Update 2 versions.


1) mysql-server
   ------------

BEFORE YOU BEGIN: you will need to obtain a mysql-server RPM and put it into
/tftpboot/rpm.  The easiest way is to get the SRPM and rebuild it,

  rpmbuild --rebuild mysql-3.23.58-1.src.rpm
  cp /usr/src/redhat/RPMS/ia64/mysql-server-3.23.58-1.ia64.rpm /tftpboot/rpm

MySQL v3.23.58-1 is the version that came with Red Hat Enterprise Linux 3,
Update 3; if you cannot find that particular version, please make sure that
you copy all the rebuilt MySQL RPMs (including the server RPM).  For example,
if the version you could find is v3.23.58-2.3:

  rpmbuild --rebuild mysql-3.23.58-2.3.src.rpm
  cp /usr/src/redhat/RPMS/ia64/mysql*-3.23.58-2.3.ia64.rpm /tftpboot/rpm 

The key here is to keep the MySQL versions consistent.


2) Red Hat Enterprise Linux 3 (Gold or Update 2) rpmlist
   -----------------------------------------------
 
IN OSCAR WIZARD STEP 4: if you're running an earlier version than Update 3,
you will need to manually select the correct rpmlist before generating the
client image.  Select the appropriate file for your architecture

  /opt/oscar/oscarsample/redhat-3asU2-i386.rpmlist
or
  /opt/oscar/oscarsample/redhat-3asU2-ia64.rpmlist


3) Initrd and elilo.conf
   ---------------------

AFTER OSCAR WIZARD STEP 4: there is a problem generating a valid initrd on the
nodes, so we must provide one in the image.  Copy a valid initrd to image
directory

  /var/lib/systemimager/images/oscarimage/boot/efi/EFI/redhat

with the commands

  cp /boot/efi/efi/redhat/initrd-*.img \
    /var/lib/systemimager/images/oscarimage/boot/efi/EFI/redhat/
    
  cp /boot/efi/efi/redhat/elilo.conf \
    /var/lib/systemimager/images/oscarimage/boot/efi/EFI/redhat/


4) systemconfig.conf
   ----------------- 
 
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

NOTE: Note carefully the DOUBLE SLASH in the PATH and INITRD lines!


5) SCSI and network
   ----------------

AFTER OSCAR WIZARD STEP 4: you may also need to add a Hardware section with
SCSI and network drivers.  In the image file

  /var/lib/systemimager/images/oscarimage/etc/systemconfig/systemconfig.conf

For an Intel SR870BH2, the hardware section of this file would look like:

  [HARDWARE]
    ORDER = e1000 e1000 mptscsih mptbase scsi_mod


6) USB
   ---

AFTER OSCAR WIZARD STEP 4: if you need to use the keyboard on a USB-only
system, like the Intel SR870BH2, you need to add the USB controller to the
image file

  /var/lib/systemimager/images/oscarimage/etc/modules.conf

For example,

  echo alias usb-controller usb-uhci >> \
    /var/lib/systemimager/images/oscarimage/etc/modules.conf


7) tftp-server
   -----------

AFTER OSCAR WIZARD STEP 6, BEFORE YOU BOOT THE CLIENT NODES: you will need to
replace the TFTP server.  If your distrubition doesn't come with a tftp-server
package you should download and install the appropriate file from a repository.

Once you have downloaded and copied it to a known directory you must install
the package and turn it on:

  rpm -i tftp-server-0.32-4.ia64.rpm  

(it could be "ia64" or "i386", depending of your machine's architecture).

  /sbin/chkconfig --level 345 tftp on 


8) DISKORDER
   ---------

AFTER OSCAR WIZARD STEP 6, BEFORE YOU BOOT THE CLIENT NODES: you may have to
modify the DISKORDER sequence used by SystemImager to prevent the system from
using your CD-ROM as a disk, resulting in a "Kernel panic" during the
client's installation phase.  Add the following to the SystemImager
kernel command line:

  DISKORDER=sd,hd,cciss,ida,rd

For i386 clients, add this value to the "APPEND" keyword in the "KERNEL"
section of

  /tftpboot/pxelinux.cfg/default

For example,

  DEFAULT systemimager
  LABEL systemimager
  DISPLAY message.txt
  PROMPT 1
  TIMEOUT 50
  KERNEL kernel
    APPEND vga=extended initrd=initrd.img root=/dev/ram \
      DISKORDER=sd,hd,cciss,ida,rd

For ia64 clients, add this value to the "append" keyword in the "image"
section of

  /tftpboot/elilo.conf

For example,

  prompt
  timeout=50
  default=sisboot

  image=kernel
    label=sisboot
    initrd=initrd.img
    read-only
    root=/dev/ram
    append="DISKORDER=sd,hd,cciss,ida,rd"

NOTE: elilo requires keywords in lower case.
