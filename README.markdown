Jurnalo Crawler Core
====================

This library implements extraction of web data from instance based learning. 
Given a set of pages from a Web site, the proposed technique takes a labeled
page ( user labels the items that need to be extracted ). The system then
stores a certain number of consecutive prefix and suffix tokens (tags) of
each item. After that it can extract target items from each new page from
the Web site which uses the same template.

Requirements
------------
- Ruby 1.8.6
- Gems: rspec (1.2.6) [required for specs]

Specs
-----
<pre><code>
rake specs:all
</code></pre>

Scripts
-------

Sources Learned: NY Times, Times
NOTE: Following commands are to be run from jCore ROOT\_DIRECTORY.

### How to learn?

<pre><code>
ruby script/learn -s times
ruby script/learn -s nytimes
</code></pre>

This will learn about Times and NY Times pages respectively.
The labeled data is stored in <code>LIB\_ROOT/data/labeled_stories</code>.
The file naming follows following convention: <code>&lt;source&gt;\_ddd.kd+.html</code> where
<code>d</code> represents digit and <code>d+</code> represents one or more digits. E.g.

<code>nytimes\_001.k5.html</code> tells that source is <code>nytimes</code> and maximum
prefix/suffix length for the template is <code>5</code>.

To add more sources, the labeled data should be created and then learn script be run.

### How to inspect the template learned?

<pre><code>
ruby script/template -s times
ruby script/template -s nytimes
</code></pre>

This will show the template structure.

### How to extract information?

<pre><code>
ruby script/extract -s times -u "http://www.time.com/time/nation/article/0,8599,1915835,00.html"
ruby script/extract -s nytimes -u "http://www.nytimes.com/2009/08/14/opinion/14krugman.html"
</code></pre>

This will display the information that is extracted using templates.
If information is not extracted then it reports "Information not found".

Author
------
Ram Singla

Copyright
---------
Jurnalo.com (c) 2009

