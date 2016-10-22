---
layout: wiki
title: opkg_gui
meta: 
permalink: "/wiki/opkg_gui"
category: wiki
---
<!-- Name: opkg_gui -->
<!-- Version: 1 -->
<!-- Author: mledward -->

This is a shell of a page of development ideas about the OSCAR GUI

 * A more wizard like interface than the current step by step process which allows for flexible decision making and easy extensibility depending on choices made.  For example, instead of an explicit configuration step, each package might display its default options and ask if the user wants to change them.

 * OPD Interface Improvement to encourage people to put packages that are not "finished" in the OPD repository

"It just seems to me that packages exist in various stages (there are a couple in the GSoC repository for instance) and I would like these to be able to appear in the GUI in a way that makes it clear what their status is so folks would be more comfortable putting them into the OPD repository.

For instance, the job monarch package could show up as


    
    Name         OSCAR Ver    Distro   Type         Info
    Job Monarch     5         FC 4     Experimental -Link to more-
    Ganglia         5         ALL      CORE         -Link to info-


Anyway, this is probably oversimiplified, or at least the distro list might be a bit long in some cases, but I hope this makes it a bit clearer what I am talking about.  Maybe." --Mike Edwards 04/10/2007