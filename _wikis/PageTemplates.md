---
layout: wiki
title: PageTemplates
meta: 
permalink: "/wiki/PageTemplates"
category: wiki
---
<!-- Name: PageTemplates -->
<!-- Version: 2 -->
<!-- Author: trac -->

= Wiki Page Templates = 

  _(since [0.11](http://trac.edgewall.org/milestone/0.11))_

The default content for a new wiki page can be chosen from a list of page templates. 

That list is made up from all the existing wiki pages having a name starting with _PageTemplates/_.
The initial content of a new page will simply be the content of the chosen template page, or a blank page if the special _(blank page)_ entry is selected. When there's actually no wiki pages matching that prefix, the initial content will always be the blank page and the list selector will not be shown (i.e. this matches the behavior we had up to now).

To create a new template, simply create a new page having a name starting with _PageTemplates/_.

(Hint: one could even create a _PageTemplates/Template_ for facilitating the creation of new templates!)

After you have created your new template, a drop-down selection box will automatically appear on any new wiki pages that are created.  By default it is located on the right side of the 'Create this page' button.

Available templates: 
[[TitleIndex(PageTemplates/)]]
----
See also: TracWiki