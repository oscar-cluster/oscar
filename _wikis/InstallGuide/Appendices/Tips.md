---
layout: wiki
title: InstallGuide/Appendices/Tips
meta: 
permalink: "wiki/InstallGuide/Appendices/Tips"
category: wiki
folder: wiki
---
<!-- Name: InstallGuide/Appendices/Tips -->
<!-- Version: 8 -->
<!-- Author: olahaye74 -->
[back to Table of Contents](wiki/InstallGuide)

# Appendix C: Tips and Troubleshooting

This is a rough colection of tips and tricks for when things don't work quite the way we might expect them to.  If you carefully follow the documentation provided here, these suggestions should not be neccesary.  However, the suggestions here might be helpful if something does not work and you need a place to start.

Also, please check out the OSCAR website ([wiki/Support]) for more support tips and tricks.

### Q1) When trying to PXE boot a node (for imaging), I get a TFTP timeout.
tftp server is started by xinetd.
=> check that /etc/xinetd.d/tftp file is correct.
- disable = no
- server                  = /usr/sbin/in.tftpd
- server_args             = --user nobody.nobody /tftpboot
=> check that /usr/sbin/in.tftpd points to a tftpd binary like atftpd.
if you modify this file, you need to restart xinetd service.

In order to test: install atftp command (yum install atftp on rhel distros) and then do:
cd /tmp; atftp localhost
get /pxelinux.0
^D
ls pxelinux.0

----

### Q2) when trying to PXE boot a node, PXE fails to find kernel and initrd.
Check that /tftpboot directory exists or is a link to your distro tftpboot.
tftps looks for files from parameters in /etc/xinetd.d/tftpd line server_args.
(see above).

----

### Q3) I get rsyncd is not running when trying to image a node.

1/ rsyncd is not running (service systemimager-server-rsyncd) is not started.
   - Note that this service doesn't automatically starts. You must start it from oscar_wizard step 6: "Enable Install Mode".
   - Upon reboot, you need to do that again.

=> Check that the following process exists on the server:
/usr/bin/rsync --daemon --config=/etc/systemimager/rsyncd.conf

2/ iptables blocks rsyncd port
=> Check that iptables is stopped.

----

### Q4). I have rsync errors about overrides not found.
=> This is normal if you didn't put files in /var/lib/systemimager/overrides

----

=== Q5) When trying to image a node I get the following error:
nc: can't connect to remote host (192.168.1.1): Connection refused. ===

si_monitor daemon is not running. You should have a process that looks like:

    /usr/bin/perl -w /usr/sbin/si_monitor --log /var/log/systemimager/si_monitor.log --log_level 2
   - Note that this service doesn't automatically starts. You must start it from oscar_wizard step 6: "Enable Install Mode".
   - Upon reboot, you need to do that again.

----

=== Q6) After imaging, the node doesn't boot: 
Booting from local disk... before "PXE-M0F : ... " ===
=> SystemConfigurator doesn't yet support grub/grub2/NetworkManager.
You need post install scripts to finish the work.
good examples are here: http://olivier.lahaye1.free.fr/OSCAR/SystemImager-scripts/
Copy required scripts to /var/lib/systemimager/scripts/post-install/ on the head and
edit them to suit your needs.

----

=== Q7) apitests refuse that I oscar-config --bootstrap
Check:
- That your hostname is set.
  If it's not set, or if it is localhost, you must update this.
  If you're using NetworkManager, you can do this with the following command:
  nmtui-hostname <hostname>
- That your hostname IP in /etc/hosts is NOT 127.0.0.1
- That your dnsdomainname is not localdomain.
- That /etc/selinux/config has SELINUX=permissive or SELINUX=disabled
- That IpV6 is disabled (torque doesn't support ipv6 yet and oscar scripts are not designed for that as well (yet))

----

=== Q8) How do I disable IPv6?
- On old distros:   vi /etc/sysconfig/network-scripts/ifcfg-private <iface> (private iface is the iface to access your nodes. This can be a public iface in that case)

  NETWORKING_IPV6=no

  IPV6INIT=no

- On recent distros:
  vim /etc/sysctl.conf
     net.ipv6.conf.all.disable_ipv6 = 1

     net.ipv6.conf.default.disable_ipv6 = 1

----
### More things to cross-check:

1. sshd_config
Edit _/etc/ssh/sshd.config_ and ensure the `PermitRootLogin` is set to `Yes`. See [Build Client Images](wiki/InstallGuideClusterInstall#BuildImage)

Then run */etc/init.d/sshd reload*

2. SELinux config (must be disabled)
Edit _/etc/selinux/config_ and ensure SELINUX is set to disabled.

3. hosts.{allow,deny}
Check the _/etc/hosts.allow_ and _/etc/hosts.deny_ files. They should allow all traffic from the entire private subnet.

4. Disk nodes partition template.
Edit _/usr/share/oscar/oscarsamples/ide.disk_ and set appropriate size for swap (suggested twice the client's memory size), and alternate filesystem if desired (eg reiserfs).

Note: the systemimager will determine the correct type of drive (hda/sda) so the ide.disk file can be used for scsi hardware as well. An enhancement request has been filed to clear up this issue.

----

### Some install tips and tricks:

1. Adding own packages when deploying nodes.
Copy your application (rpm) to the repository _/tftpboot/distro/your-os-version/_ and add the name to _/usr/share/oscar/oscarsamples/your-os-version.rpmlist_. Make sure to select the correct file for the creation of the image.

Other methods of installing your applications after OSCAR has been installed will be covered in the [Administration Guide](wiki/AdminGuide).


     cpush xyz.rpm /usr/src/ & cexec rpm -i /usr/src/xyz.rpm
     yume
     scrpm  --image all -w -- -Uhv xyz.rpm

