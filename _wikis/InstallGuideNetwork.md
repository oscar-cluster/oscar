---
layout: wiki
title: InstallGuideNetwork
meta: 
permalink: "wiki/InstallGuideNetwork"
category: wiki
---
<!-- Name: InstallGuideNetwork -->
<!-- Version: 2 -->
<!-- Author: valleegr -->

[[TOC]]

[back to Table of Content](wiki/InstallGuide)

# Chapter 4: Network Setup

== 4.1 Configure the ethernet adapter for the cluster == #NIC

Assuming you want your server to be connected to both a public network and the private cluster subnet, you will need to have two ethernet adapters installed in the server. This is the preferred OSCAR configuration because exposing your cluster may be a security risk and certain software used in OSCAR (such as DHCP) may conflict with your external network.

Once both adapters have been physically installed in the server node, you need to configure them.2 Any network configurator is sufficient; popular applications include neat, netcfg, or a text editor.

The following major requirements need to be satisfied:

Hostname::
  Most Linux distributions default to the hostname "localhost" (or "localhost.localdomain"). This must be changed in order   to successfully install OSCAR -- choose another name that does not include any underscores (_). This may involve editing _/etc/hosts_ by hand as some distributions hide the lines involving "localhost" in their graphical configuration tools. Do not remove all reference to `localhost` from _/etc/hosts_ as this will cause no end of problems. For example if your distribution automatically generates the _/etc/hosts_ file:
  ```
127.0.0.1 localhost.localdomain localhost yourhostname.yourdomain yourhostname
  ```

  This file should be separated as follows:
  ```
127.0.0.1 localhost.localdomain localhost
192.168.0.1 yourhostname.yourdomain yourhostname
  ```

  Additional lines may be needed if more than one network adapter is present.

Public adapter::
  This is the adapter that connects the server node to a public network. Although it is not required to have such an adapter, if you do have one, you must configure it as appropriate for the public network (you may need to consult with your network administrator).

Private adapter::
  This is the adapter connected to the TCP/IP network with the rest of the cluster nodes.

  This adapter must be configured as follows:

   * Use a private IP address

     There are three private IP address ranges: 10.0.0.0 to 10.255.255.255; 172.16.0.0 to 172.31.255.255; and 192.168.0.0 to 192.168.255.255. Additional information on private intranets is available in RFC 1918. You should not use the IP addresses 10.0.0.0 or 172.16.0.0 or 192.168.0.0 for the server. If you use one of these addresses, the network installs of the client nodes will fail.

   * Use an appropriate netmask4

     A class C netmask of 255.255.255.0 should be sufficient for most OSCAR clusters.

   * Ensure that the interface is activated at boot time
   * Set the interface control protocol to "none"

  Now reboot the server node to ensure that all the changes are propagated to the appropriate configuration files. To confirm that all ethernet adapters are in the "up" state, once the machine has rebooted, open another terminal window and enter the following command:
  ```
# ifconfig -a
  ```

  You should see UP as the first word on the third line of output for each adapter. If not, there is a problem that you need to resolve before continuing. Typically, the problem is that the wrong module is specified for the given device. Try using the network configuration utility again to resolve the problem.
