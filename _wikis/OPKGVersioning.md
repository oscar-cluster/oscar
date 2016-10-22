---
layout: wiki
title: OPKGVersioning
meta: 
permalink: "/wiki/OPKGVersioning"
category: wiki
---
<!-- Name: OPKGVersioning -->
<!-- Version: 9 -->
<!-- Author: wesbland -->

[Development Documentation](/wiki/DevelDocs/) > [OSCAR Set Manager](/wiki/OSM/) > [Package Set Manager](/wiki/SetManager/) > OPKG Versioning

# OPKG Versioning

The version of the OPKG has 4 parts based on a combination of the rpm and deb versioning scheme:

 1. Major
 1. Minor
 1. Subversion
 1. Release

When combined to form a single string, the version looks like this:

    Major.Minor.Subversion-Release

To compare two versions, the following algorithm will be used (adapted from the _Debian Policy Manual_^1^  with _release_ substituted for _debian_revision_):

The strings are compared from left to right.

First the initial part of each string consisting entirely of non-digit characters is determined.  These two parts (one of which may be empty) are compared lexically.  If a difference is found it is returned.  The lexical comparison is a comparison of ASCII values modified so that all the letters sort earlier than all the non-letters.

Then the initial part of the remainder of each string which consists entirely of digit characters is determined.  The numerical values of these two parts are compared, and any difference found is returned as the result of the comparison.  For these purposes an empty string (which can only occur at the end of one or both version strings being compared) counts as zero.

These two steps (comparing and removing initial non-digit strings and initial digit strings) are repeated until a difference is found or both strings are exhausted.

*NOTE -- This version comparing schema will NOT honor any kind of alpha or beta release versioning.  1.0b will be greater than 1.0.*

For example:

1a.3.5-1wb < 1a.3.5-1wb1

 1. Compares the digit (1) at the beginning of each string and sees that they have the same value and length.
 1. Compares the non-digits next (a.) and sees that they have the same value and length.
 1. Compares the digit next (3) and sees that they have the same value and length.
 1. Compares the non-digit next (.) and sees that they have the same value and length.
 1. Compares the digit next (5) and sees that they have the same value and length.
 1. Compares the non-digit next (-) and sees that they have the same value and length.
 1. Compares the digit next (1) and sees that they have the same value and length.
 1. Compares the non-digits next (wb) and sees that they have the same value and length.
 1. Compares the digit next (left has nothing, right has '1') and sees that the right has something and therefore wins.

If any digit or non-digit had had a higher value or had been longer, that string would have won.

A few other examples:


      1 < 1.0 < 1.1 < 1.1.1 < 1.1.1b < 1.1.2 < 1.1.2-wb < 2 < A < B < a < b

----

Debian Policy Manual <http://www.debian.org/doc/debian-policy/>