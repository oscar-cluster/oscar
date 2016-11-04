---
layout: wiki
title: DevSanityCheck
meta: 
permalink: "wiki/DevSanityCheck"
category: wiki
---
<!-- Name: DevSanityCheck -->
<!-- Version: 3 -->
<!-- Author: bli -->

# The Sanity_Check framework

## The OPKG Module

This module checks the status of the different OPKGs. For that, we check the list of OPKGs:
   - shipped with OSCAR,
   - available via the default package set,
   - installable via data in the database.
Note that the only real error is when the list of OPKGs in the default package set does not match the list of installable OPKGs.

## The Image Module

This component checks if ODA, the SIS database and the file system are synchronized regarding images. Typically it gets the list of images:
   - in the SIS database,
   - in ODA,
   - in the file system (i.e., directories in _/var/lib/systemimager/images_).
Then it compares these lists. If errors are reported, you may want to execute the script _$OSCAR_HOME/scripts/oscar_image_cleanup_, but be aware that the script will try to remove all images that are corrupted.

## How to use the Sanity_Check framework?

The easiest way to go is to execute the script _scripts/sanity_check_. That will check your system (useful if you witness weird behaviors).
