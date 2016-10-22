---
layout: wiki
title: FAQ_Trac
meta: 
permalink: "/wiki/FAQ_Trac"
category: wiki
---
<!-- Name: FAQ_Trac -->
<!-- Version: 2 -->
<!-- Author: bli -->

# Trac FAQ

## How to submit tickets to Trac

This document describes how to submit a ticket to Trac for the OSCAR Project.

The goal of submitting a ticket is to alert the developers that there is an issue with the code and/or provide feature requests which will enhance your experience with OSCAR.

Please try to fill out as much information as possible, here are some guidelines:

  * *Your email or username*: If you would like to be notified when the ticket is updated, please put down your email address.  However this makes your address publically available so do not enter it here if you do not want that!  Alternatively if you have a Trac account, log in first before you submit a ticket then your username will automatically appear in this field.  To apply for a Trac account, send an email to [mailto:oscar-devel@lists.sourceforge.net oscar-devel@lists.sourceforge.net].

  * *Short summary*: Short description of the problem/enhancement - be as precise and concise as possible.

  * *Type*: Choose from the drop-down menu the most appropriate type: bug, enhancement, task.

  * *Full description*: Please use WikiFormatting as much as possible to make the text more viewable in the Trac system.

  * *Priority*: Importance of the ticket.

  * *Component*: Component which the ticket belongs to - if unsure, just leave it at "Other".

  * *Keywords*: Enter keywords for easy searching and report generation (eg. pvm, rpm, selinux).

  * *Cc*: List of users/email addresses who are on the notification list when the ticket is updated.

  * *Milestone*: This field indicates when the ticket (bug/feature request) will be addressed/incorporated.  New tickets should be set to "Future" and it is the responsibility of the ReleaseManager to associate the ticket with an appropriate milestone.  During CodeFreeze, only tickets that are associated to the milestone of the particular branch can be addressed.

  * *Version*: The OSCAR version the ticket references.  This could be a released version like "4.2" or a specific branch like "branch-5-0".  If you are submitting an enhancement ticket, put in "trunk".

  * *Assigned to*: The developer to whom the ticket should be assigned to.  If unsure, use "nobody" (default).

See also the original TracTickets description.