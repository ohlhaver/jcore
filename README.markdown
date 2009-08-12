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
rake specs:all

Author
------
Ram Singla

Copyright
---------
Jurnalo.com (c) 2009

