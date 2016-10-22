---
layout: wiki
title: SvnMerges
meta: 
permalink: "/wiki/SvnMerges"
category: wiki
---
<!-- Name: SvnMerges -->
<!-- Version: 3 -->
<!-- Author: bli -->

[Developer Documentation](/wiki/DevelDocs/) > SVN > Merges

# SVN Merges

SVN merges is a good way to merge code changes between different directories within a repository and this is done routinely during/after branches are created. Please use merges instead of double checkins (to trunk and branch), this reduces the chance for additional errors and incoherencies.

Jeff Squyres has written an excellent [email](http://www.mail-archive.com/oscar-devel@lists.sourceforge.net/msg04512.html) documenting how to do this within the OSCAR Project, it is definitely worth the read.

## Assisted half-automatic merges

Erich Focht has written a tool for merging changes between repositories one by one. The tool is available at [http://home.arcor.de/efocht/tools/svnmerge_1by1]. Its advantage is that it merges a given range of svn checkins one by one, keeping the original checkin messages. This way the checkin logs (which usually contain a lot of information on why the change happened) are surviving even big merges of many revisions.

Suppose your development repository is checked out to `/home/me/devel`
and the target repository is checked out to `/home/me/target` .

You should now find out which revision range from the source repository you
want to merge to the target repository. Only numbers are accepted as range, no
symbols! Suppose the range is between r330 and r340. 

What you need to do is

    svnmerge_1by1 --rev 330:340 /home/me/devel /home/me/target

This will go revision by revision:
 * extract the log message
 * merge the changes to the target
 * detect conflicts
 * offer you a simple menu on how to proceed:
   * *`y :`* commit this merge
   * *`n :`* don't commit this merge (warning: the merge is still in the target checkout). Typing "n" will proceed to the next merge if this is not the last one, thus giving you a chance to combine several merges into one.
   * *`q :`* try to revert changes to your target checkout and exit. This might fail if the last merge involved removing directories!
   * *`l :`* last commit, exit after it (does not merge the next change)
   * *`e :`* edit the log text for the commit to the target

If you have conflicts in one merge you will see a text telling you that and
listing the files with conflicts. Now you must go to another shell and resolve
the conflict in the file(s). Once you did that you'll need to do (manually):
  * `svn cleanup`
  * `svn resolved path_to_file`

Then return to the shell where svnmerge_1by1 is running and type "y" to
checkin the merge. It will re-check for conflicts and if there are some, it
will tell you again.

The part that is missing from this small program is something to resolve the
conflicts easilly. If you have tkdiff installed, you can call

    tkdiff -conflict path_to_file
to try to resolve the conflict.

Attention: we are talking about revision deltas here, so if you want to check in the change which lead to one particular revision, for example r330, you'll need to specify the revision range `--rev 329:330`!
