---
layout: wiki
title: online_oscar_repos
meta: 
permalink: "/wiki/online_oscar_repos"
category: wiki
---
<!-- Name: online_oscar_repos -->
<!-- Version: 1 -->
<!-- Author: valleegr -->

# OSCAR Online Repositories

OSCAR now supports online repositories: all OSCAR related binary packages are available via APT or YUM repositories. 

## List of Mirrors

Right now, we do not have any production type repository, but a server is provided by the Oak Ridge National Laboratory in order to perform the first phase of testing and stabilize the software:

http://bear.csm.ornl.gov/repos *This server may be shutdown at any time, without notifications. The management of this repository is also restricted (not everyone can have a account in order to upload binary packages).*

## Creation of Your Own Mirror

Currently the only solution is to create a new online repository from scratch. For that, the WebORM tool has been developed (PHP5 interface for the creation and management of OSCAR respositories). For more information, visit the [WebORM wiki page](/wiki/weborm/).