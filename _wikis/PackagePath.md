---
layout: wiki
title: PackagePath
meta: 
permalink: "/wiki/PackagePath"
category: wiki
---
<!-- Name: PackagePath -->
<!-- Version: 2 -->
<!-- Author: efocht -->

# OSCAR::PackagePath

This perl module contains functions and variables for managing package repository path related things.

## SYNOPSIS

    use OSCAR::PackagePath;
    
    # return hash with available distro pools
    %pools = list_distro_pools();
    
    # path to OSCAR .url file specific to distro (OSCAR packages are here)
    $oscar_url_file = oscar_urlfile($os);
    
    # path to distro specific .url file (distro packages are here)
    $os = distro_detect_or_die();
    
    # list OSCAR repositories accessible for distro:
    @repo_list = repos_list_urlfile($oscar_url_file);
    
    # add a repository or more (add arguments)
    repos_add_urlfile($oscar_url_file, "http://slurp/path");
    
    # delete a repository or more
    repos_del_urlfile($oscar_url_file, "http://blah/path");
    

## Exported variables

 * *@PKG_SOURCE_LOCATIONS* : 
 * *$PGROUP_PATH* : 

## Exported Function

 * *list_distro_pools* : build a hash containing all distros which are configured, i.e. all distros that have a .url file in /tftpboot/distro/. The hash primary key is the distro string. Subkeys are:
  * os: a reference to the distro's detected $os structure.
  * oscar_repo: the oscar repositories configured for this distribution. Multiple repositories are separated by commas.
  * distro_repo: the distribution repositories configured for this distribution.
 * *distro_repo_url* : 
 * *oscar_repo_url*
 * repo_empty
 * repos_list_urlfile
 * repos_add_urlfile
 * repos_del_urlfile
 * os_distro_string
 * os_cdistro_string
 * pkg_extension
 * pkg_separator
 * distro_detect_or_die
