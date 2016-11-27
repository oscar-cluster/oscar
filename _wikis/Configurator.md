---
layout: wiki
title: Configurator
meta: 
permalink: "wiki/Configurator"
category: wiki
---
<!-- Name: Configurator -->
<!-- Version: 10 -->
<!-- Author: wesbland -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [Command Line Interface](CLI)

## Configurator

*This step is optional.*

### Interactive Version

The list of configurable packages will be printed followed by a prompt that takes these commands:[[BR]]
 `configure packageName`::
   Select a package to configure
 `file <filename>`::
   Reads in commands from a file
 `help`::
   Prints this message
 `devel <packageName>`::
   Skips getting info from the database and goes straight to parsing the configurator.html file associated with this package
 `quit/exit`
   Quits the configurator and continues with the next step

As the script runs, all user input is dumped to a file called selector.log. This file can be used later to recreate the current install by using it as the input file for the non-interactive version.

### Non-interactive Version

To enter the non-interactive version, at the command line, use the flag `--filename` or `-f` followed by the filename to be used.  This file will be read in just as input from the keyboard would.  All commands are the same as the interactive version and must be seperated by a newline.  A `quit` command is not necessary and will be automatically executed when the file is finished.

### External Tool Version

This version was included because of the way Ganglia uses the Configurator.  It needs to be able to call the Configurator later on in the OSCAR installer after the Configurator step has passed.  In order to accommodate for Ganglia, some flags were added to the configurator_cli script.  There are 3 flags and in order to use the external tool version of Donfigurator, all 3 must be present otherwise they will be ignored and Donfigurator will run normally.  These flags include:
 - `path`: The absolute path to the configurator.html file *including* the filename itself.
 - `package`: The name of the package being configured.
 - `context`: The context of the package.  After digging through the OSCAR code this looks like it can be one of two values.  Either `global` or `image:Some_Image_Name` where the image name is one of the images being deployed onto the OSCAR cluster.  Normally this value is `global`, but Ganglia appears to use the `image:` version.
 As an example of how to run the configurator_cli script with these flags::
 `configurator_cli --path=$ENV{OSCAR_HOME}/packages/sis/configurator.html --package=sis --context=global`

### configurator.html

Due to problems using the HTML version of the configurator as a command line tool, some changes had to occur to make the configurator.html files usable.  These changes are documented [here](Configurator.html).
