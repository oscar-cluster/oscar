---
layout: wiki
title: CodingStyle
meta: 
permalink: "wiki/CodingStyle"
category: wiki
---
<!-- Name: CodingStyle -->
<!-- Version: 8 -->
<!-- Author: valleegr -->

[Documentations](Document) > [Developer Documentations](DevelDocs)

## Coding Style (preliminary)

The OSCAR infrastructure code is written almost entirely in Perl. It is spread over many files and modules and has been contributed by many developers with their own opinion on how nice Perl code should look like.

In order to make the OSCAR infrastructure code easier to maintain the developers are urged to follow the coding style guidelines defined in this document. Developers are also encouraged to clean up old code and adapt it to the guidelines. 

### Indentation

Use 4 characters deep indentations, i.e., 1st level is 4 characters indented, 2nd level is 8 characters, etc... This is the default indentation in emacs perl-mode. Don't use less indentation, it's too hard to read. If you use more (8 characters), we don't get reasonably complex code inside an 80 characters screen.

Then, you have the choice between using real tabulations (typically the '\t' character) or only spaces. In the OSCAR project, we do not care about which one you decide to use if you do not mix them. If you start to mix real tabulations and spaces, you can be sure that all developers who are not using exactly the same development configuration on their machine will have troubles. For instance, it is very bad to use spaces for the 1st level indentation and then real tabulations.

Keep code within 80 characters width. If this is exceeded significantly and in big parts of code, it gets unreadable. If you're needing more than 80 characters over big parts of code, you probably should rethink the structure of your code: maybe splitting things out into a separate function makes it more readable.

(Quoting from the kernel coding style document:)

Don't put multiple statements on a single line unless you have
something to hide:

``` perl
    if (condition) { 
        do_this;
        do_that; $a = $a + 1; ...
    }
```

The Perl style "if" located after the statement is hard to read and see. If you have no good reason for it (some symmetry in the code which makes it easy to see the structure), avoid it.
Perl offers loads of ways to obfuscate code and make it "write-only". Try to discipline yourself and think whether other will understand easily the code you write.

Also: use blanks to separate expressions and make them better readable:
   `if (a >= b) {`

is much better than
   `if(a>= b){`

Get a decent editor and don't leave whitespace at the end of lines.


### Placing braces

(quoting from the kernel coding style document, again)

The other issue that always comes up in C styling is the placement of
braces.  Unlike the indent size, there are few technical reasons to
choose one placement strategy over the other, but the preferred way, as
shown to us by the Kernighan and Ritchie, is to put the opening
brace last on the line, and put the closing brace first:

``` perl
    if (x is true) {
        we do y
    }
```
Note that the closing brace is empty on a line of its own, _except_ in
the cases where it is followed by a continuation of the same statement,
i.e., a "while" in a do-statement or an "else" in an if-statement, like
this:

``` perl
    do {
        body of do-loop
    |
```
and

``` perl
    if (x == y) {
        ..
    } elsif (x > y) {
        ...
    } else {
        ....
    }
```
Rationale: K&R.

Also, note that this brace-placement also minimizes the number of empty
(or almost empty) lines, without any loss of readability.  Thus, as the
supply of new-lines on your screen is not a renewable resource (think
25-line terminal screens here), you have more empty lines to put
comments on.

Following constructs are considered bad style and should be wiped from our code:

```perl
use strict;

    if (condition)
    {
        do_something;
    }
    else
    {
        do_something_else;
    }
```

### Naming, Variables and Subroutines

Variable and function or subroutine naming is worth spending a few minutes. Give them meaningful names but don't try to describe useless things in names. Inside a loop you can well call a string "$line", there's probably no need to call it "$configurationLine". Also: inside a Perl module there's no need to give terribly long and fully explanatory names to subroutines which are not exported.

Long names make it difficult to keep code short, thus to stay within the 80 characters. As opposed to Java, Perl names are traditionally lowercase, rather short and composed with "_". That means you should rather use "get_var()" instead of "getVariableFromDatabase()".

### Code Replication

Code replication is the worst maintenance nightmare. Never ever replicate code! If you think you can quickly hack a routine by copying another one and changing one line, forget it! Make a subroutine or a module and parametrize your need for change.
