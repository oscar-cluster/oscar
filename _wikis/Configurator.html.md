---
layout: wiki
title: Configurator.html
meta: 
permalink: "/wiki/Configurator.html"
category: wiki
---
<!-- Name: Configurator.html -->
<!-- Version: 6 -->
<!-- Author: wesbland -->

[Development Documentation](/wiki/DevelDocs/) > [Command Line Interface](/wiki/CLI/) > Configurator.html

# configurator.html

Due to problems rendering the HTML for Configurator in a command line interface, there have been strict restrictions placed on the configurator.html files.  These are outlined below:

 1. *The entire document is now in XHTML instead of HTML.*[[BR]] 
 This is not as daunting as it sounds.  It only means that every opening tag must have a closing tag.  "Singleton" tags such as <br> and <hr> must also have a closing mark (<br /> and <hr /> respectively).
 1. *All _input_ tags must have a _name_ attribute.*[[BR]]
 This was standard anyway, but I want to mention it here for completeness. This is used to link the input tag with the database.
 1. *All text that describes an _input_ tag must be contained within the tag.*[[BR]]
 This is very different from what has been done in the past.  Usually _input_ tags are singleton, meaning they are an opening and closing tag.  Now _input_ tags need to have a separate closing tag and all descriptions about them should be contained within the tag.  As an example:[[BR]][[BR]]
 `<input type="text" name="foo">Enter data about foo</input>`[[BR]][[BR]]
 Looks like this:[[BR]][[BR]]
 ```
 #!html
 <input type="text" name="foo">Enter data about foo</input>
 ```
 [[BR]][[BR]]
 Notice that this means that now all descriptions of inputs must show up on the right-hand side of the input they are describing.  This is unavoidable because of the difficulty connecting inputs with their descriptions.  It does however make the document look cleaner when there are multiple inputs so in my opinion, this solution is better anyway.
 1. *All text that is not specifically describing an input needs to be contained in a _p_ tag.*[[BR]]
 This is necessary for the XML::Simple parser to be able to detect text that doesn't go with anything else.  This means that a _p_ tag is no longer a singleton tag.  There must be an opening and closing tag around any general description text.  In conjunction with the next requirement, it allows the text to be ordered explicitly so that when it is displayed in the CLI, it makes logical sense. This rule includes any text that is not enclosed in the _title_ tag including the header that is at the top of most pages that has an _h1_ and _center_ tag.
 1. *There must be a _form_ tag immediately following the _body_ tag.*[[BR]]
 This is to prevent unpredictable nesting when the XML::Simple parser tries to parse the configurator.html files.
 1. *All sections of text (_p_ or _input_) must have an _order_ attribute.*[[BR]] 
 This is the most important of all of the new requirements.  This is the one that makes everything appear in the correct order when it is parsed by XML::Simple so that everything "should" show up in the same order in the CLI that it does in the GUI.  All this means is that instead of having code that looks like this:[[BR]][[BR]]
 `<input type="checkbox" name="box1">`[[BR]][[BR]]
 Now it should look like this:[[BR]][[BR]]
 `<input type="checkbox" name="box1" order="12">`[[BR]][[BR]]
 It is not advised that you have two order attributes with the same number.  Chances are that the second one will get ignored, but the results are undefined. Note that this includes *all* p tags, including ones that enclose the header that is at the top of most pages that has an _h1_ and _center_ tag.
 1. *Only a small set of tags are supported.*[[BR]]
 There is a very small list of tags that are now supported.  This list includes:
 - <h1>, <h2>, <h3>
 - <b>
 - <i>
 - <center>
 - <br />
 - <hr />
 - <html>
 - <head>
 - <title>
 - <body>
 - <p>
 - <form>
 - <input>