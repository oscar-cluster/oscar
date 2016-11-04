---
layout: wiki
title: CompleteTest
meta: 
permalink: "wiki/CompleteTest"
category: wiki
---
<!-- Name: CompleteTest -->
<!-- Version: 2 -->
<!-- Author: wesbland -->

[Development Documentation](DevelDocs) > [Command Line Interface](CLI) > Complete and Test Cluster Setup

# Complete and Test Cluster Setup

This step is completely automated.  The only requirement for this step is that before it can begin, the user must network boot the client nodes and allow them to download their images from the headnode.  Once this installation is complete, the nodes should reboot from their hard drives completely.  Then the user will type `continue` at the prompt and installation will continue.  This message will remind the user of this information:


    *************************************************************
    * Before continuing, network boot all of your nodes.        *
    * Once they have completed installation, reboot them from   *
    * the hard drive. Once all the machines and their ethernet  *
    * adaptors are up, type \'continue\' and press Enter.       *
    *************************************************************
