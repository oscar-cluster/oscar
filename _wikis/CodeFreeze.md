---
layout: wiki
title: CodeFreeze
meta: 
permalink: "/wiki/CodeFreeze"
category: wiki
---
<!-- Name: CodeFreeze -->
<!-- Version: 6 -->
<!-- Author: valleegr -->

[Developer Documentation](/wiki/DevelDocs/) > Code Freeze and Release

# Code Freeze for the Preparation of a New Release

When code in the development trunk has enough new features for a new release, an appropriate branch will be created by the Release Manager and the branch will be in code freeze.  Trunk will still be open for check-ins however all developers are strongly encouraged to help in stabilizing the code in branch such that we can put out a release sooner.

During code freeze, only bugs that are assigned to the particular milestone pertaining to the created branch or otherwise allowed by the Release Manager can be checked-in.  Code that is checked in without the consent of the Release Manager will be reverted.  Note that code changes without logic change (eg. string modifications) and documentation are allowed during code freeze as they do not change the execution behaviour.

Bugs such as missing (S)RPMs in the code repository as well as not up-to-date (S)RPMs do not require special permission to be checked in.

Weekly bug reviews are held on the IRC channel irc.freenode.net #oscar-cluster to review bugs that are currently in the system and to assign them to appropriate miletones.  The Release Manager will discuss with other team members to decide which bugs should be fixed for a particular release.  While the Release Manager will try to be accomodating to all developers' requests, the ultimate decision regarding which bugs are to be fixed for a release is up to the Release Manager having release deadlines in mind.  If you have a bug which would like to be assigned to the upcoming milestone, please either add the Release Manager to the Cc: list or forward the bug to the oscar-devel mailing-list such that the Release Manager can take a look at the issue at the earliest convenience.

Bugs regardless should be fixed in trunk.  If the fix is for a bug assigned to a milestone we are currently trying to reach, then it is necessary to merge the change to the branch.  Please make sure that you are merging the code and not simply copying the code from trunk -> branch as the code might have changed in trunk which may then introduce some new features into branch.

Please refer to page [SVN Merges](/wiki/SvnMerges/) for more information on how this is performed.

