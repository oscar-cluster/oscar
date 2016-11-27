---
layout: wiki
title: SvnTrac
meta: 
permalink: "wiki/SvnTrac"
category: wiki
---
<!-- Name: SvnTrac -->
<!-- Version: 3 -->
<!-- Author: dikim -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > SVN

## Trac integration with SVN

Trac is tightly integrated with Subversion and as such, provides some really nice functionalities, one of which is giving Trac specific commands via SVN log messages.

For instance there is an open bug and your check-in is supposed to fix it.  By using specific keywords (commands) in the log, Trac will automatically close and reference that check-in.  Commands such as 'closes', 'fixes', 'completes', etc. are supported.  The following is an example of a check-in log message:


    This check-in fixes #123 - there was a missing semi-colon on line 20.
                  fix
                  fixed
                  closes
                  closed
                  close
                  completes
                  completed
                  complete

This will automatically close !#123 and also put the above check-in message as the last comment of the ticket.  Note that the command needs to be immediately followed by the ticket number (starting with '#').

Special characters like '#' (for ticket number) and 'r' (for revision number) are parsed and automatically hyperlinked within Trac.
