---
layout: wiki
title: GSoC/V2M
meta: 
permalink: "wiki/GSoC/V2M"
category: wiki
folder: wiki
---
<!-- Name: GSoC/V2M -->
<!-- Version: 28 -->
<!-- Author: pyzhang -->
Here's where some thoughts about the V2M extension project are going to live.

Major milestones

PHASE 1 - Learning
 1. Learning about Current Virtual Machine Architecture(KVM, Lguest,Xen, VMware)
  a. Understanding how Virtual machine works
  a. learn how to manage virtual machine
   * VM management interface
   * Network Bridgng/NAT
 1. Learning about current V2M library
  a. understand the V2M architecture
 1. Clean the code base, Init the test environment
  a. Build the Test environment: CentOS 5.1(X86_64)
  a. do some test of V2M

PHASE 2 - Basics
 1. Validation tools
  a. add validation tools for current implementation
 1. V2M Extension with Lguest[1]
  a. Preparation
   * i386 guest support and x86_64 guest(Experimental support) support evaluation
  a. implementation
   * add lguest.cpp lguest.h for lguest support
   * Lguest VM Image create, Lguest::create_image()
   * Lguest VM deploy
    a. CDROM
    a. Network
    a. (Optional New Feature)directly create image from local OS, like VMware's vmware converter [http://www.vmware.com/products/converter/], or by using "dd" command to create image from local disk.
    * automatically check whether the image exists? if exist, use the old one. else generate one for usage.
    * automatically select the VM image format.
   * Nework config support
   * Bridge config
   * Boot Lguest VM support
  a. Validation(specify a test suite)
   * write test suite to validate the code. automatic test? Different vm config files for test? need to figure out a way.
    * VM Deployment Phase
     * Automatically Image Creation
      * If VM image file exists, generate configure file for test, else generate VM Image and config file.
     * OS Deployment Phase
      * create image via CDROM, generate config file
      * network install, generate related config file.
      * Using OSCAR to test the installation of virtual machine
    * Boot Phase
     * Network config validate config file
      * Boot without NIC's
      * Boot with one NIC' and NAT mode in Host OS
      * Boot with one NIC and Bridge mode in Host OS
    * Optional Features
     * VM Pause/Resume/Migrate Operation test.
  a. generate patch and check-in to trunk
 1. V2M Extension with KVM
  a. implementation
   * KVM VM Image Create, implement KVM::create_image()
   * KVM VM install 
    a. CDROM, implemnet KVM::install_vm_from_cdrom()
    a. Network, implemnt KVM::install_vm_from_net()
   * Network Config support
    a. Support NAT networking KVM::generate_nat_network_config_file()
    a. Support TAP Bridge networking KVM::generate_bridged_network_config_file()
   * Support Migration, Pause,unpause
   * Support Bootup the KVM with config script KVM::boot_vm()
   * KVM status KVM::status()
  a. Validation Stage(specify a test suite)
   * Steps almost the same with Lguest Validation stage
  a. generate patch and check-in to trunk

 1. V2M Extension with VMWare
  a. Familiar with VMware management tools API
   a. Some different tools are provided
    a. vmware command, different for different versions 
     * vmware server, use "vmware-cmd"
     * vmware workstation, use "vmrun"
    a. open-vm-tools? need to investigate
   a. vmware.cpp/vmware.h?
  a. implementation
   * Boot/install VM
   * VM Image Operation
    a. Create VM Image
    a. Mount VM Image
    a. umount VM Image
    a. Use the tools "vmware-vdiskmanager" to create/expands/shrink disk;use "vmware-mount" to mount the virtual disk for operation
   * Network Config file generate
    a. Bridge
    a. NAT
   * VM Status 
   * Migrate, Pause/Unpause
   * Bootup VM with config
  a. Validation(specify a test suite)
   * Steps almost the same with Lguest Validation stage
  a. generate patch and check-in to trunk

PHASE 2 - Test and Document writting, Other VM support(Optional)
 1. Code Test and improvement
 1. Writing Document/make patch

Reference

[1]Lguest Homepage [http://lguest.ozlabs.org/]

[2]KVM Homepage [http://kvm.qumranet.com/kvmwiki]

[3]KVM howto on Centos [http://wiki.centos.org/HowTos/KVM]

[4] VMWare Homepage [http://www.vmware.com]
