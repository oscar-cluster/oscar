---
layout: wiki
title: DeleteImage
meta: 
permalink: "wiki/DeleteImage"
category: wiki
---
<!-- Name: DeleteImage -->
<!-- Version: 4 -->
<!-- Author: bli -->

[Cluster Administrator Documentation](UserDocs) > Deleting node images

# Deleting node images

To delete an OSCAR image, you need to first unassign the image from the client(s) and then run the command `mksiimage`.

There is currently no way to "unassign" an image from client(s), you will need to delete the client node(s).  To do so, invoke the [OSCAR Wizard](OscarWizard) and select "Delete OSCAR Clients...".

`mksiimage` is a command from SystemInstaller which is used to manage SIS images on the headnode (image server).

Assuming the name of your image is `oscarimage`, here are the steps you need to do to fully delete an OSCAR image.

First delete the client(s) associated with the image, then execute:


    # mksiimage --delete --name oscarimage

In case some things go wrong, you can also use the command `si_rmimage` to delete the image, just pass it the name of the image as argument.

`si_rmimage` is a command from SystemImager which is the system OSCAR uses to deploy images to the compute nodes.  SystemImager images are typically stored in `/var/lib/systemimager/images`.

Note: If you want to use the `si_rmimage` command, execute the following commands to delete all data:

    # si_rmimage oscarimage -force
