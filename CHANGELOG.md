 CHANGELOG

This file is used to list changes made in each version of the POSChef cookbook.

0.0.10
------
- [Russell Seymour] - Handlers are now files within the cookbook and read the attributes directly.  They do not need to be statically created.

0.0.9
-----
- [Russell Seymour] - Modified handlers so they are now a function

0.0.8
-----
- [Russell Seymour] - When a 'once' task is added to the task scheduler a time to start has to be specified.  This was set at 2 mins after the creation however as POSHCHef is running when this gets created it means that another POSHChef runs starts 2 mins later.  This has been changed to be the current time plus the time interval that has been set in the attributes.

0.0.7
-----
- [Russell Seymour] - Modified dedault recipe so that the handlers are added to the correct directory on the server

0.0.6
-----
- [Russell Seymour] - Updated default reciepe so that it will now drop the enabled default handlers onto the machine.
- There are no enabled handlers by default, it is expected that roles will set the handlers that are to be enabled

0.0.5
-----
- [Russell Seymour] - Added new TaskScheduler resource to cookbook to test new functions to perform this work.
    + This is instead of the built in scheduler

0.0.4
-----
- [Russell Seymour] - Added xNetworking resource to the cookbook

0.0.3
-----
- [Russell Seymour] - Recipes updated to handle accepting all the attributes from the node

0.0.2
-----
- [Russell Seymour] - Updated 'task' recipe so that it can now get the named account details from an
                      encrypted databag
                      Attributes have been added that allow the vault and vault_item_id to be specified

0.1.0
-----
- [Russell Seymour] - Initial release of POSHChef

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
