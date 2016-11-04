---
layout: wiki
title: Selector
meta: 
permalink: "wiki/Selector"
category: wiki
---
<!-- Name: Selector -->
<!-- Version: 7 -->
<!-- Author: wesbland -->

[Development Documentation](wiki/DevelDocs) > [Command Line Interface](wiki/CLI) > Selector

# Selector

This section will represent the current Step 1 in the GUI installer.

## Interactive Version

The list of packages will be printed:[[br]]

    <Checked/Unchecked> <Short name> <class> <version>
Then a prompt will appear that will take these commands:[[br]]
 `select package`::
   Selects a package to be installed.
 `unselect package`::
   Prevents a package from being installed.
 `list [class]`::
   Lists all the packages by default.  If a class is present, only lists that class.
 `quit`::
   Leaves this step with the current packages selected.
 `file filename`::
   Reads the package names and selections from a file.
 `help`::
   Prints out the help text to give more detail about the commands.

The file should be in this format:

    select package1
    unselect package2
By default, when the program starts, it will be in "install mode."  Meaning that it will set all packages labeled as `core` and `include` to checked and all other packages to unchecked.
To start the program in maintainance mode and maintain the current package state, use the flag '-m'

As the script runs, all user input is dumped to a file called selector.log.  This file can be used later to recreate the current install by using it as the input file for the non-interactive version.

## Non-interactive Version

To enter the non-interactive version, at the command line, use the flag `--filename` or `-f` followed by the filename to be used.  This file will be read in just as input from the keyboard would.  All commands are the same as the interactive version and must be seperated by a newline.  A `quit` command is not necessary and will be automatically executed when the file is finished.
