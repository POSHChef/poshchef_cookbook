POSHChef Cookbook
=================

This cookbook is the accompanying cookbook for POSHChef.  It contains recipes and resources that enhance the operation of POSHChef, such as scheduling POSHChef to run at specified intervals.  Whilst it is not strictly necessary to have this cookbook in your run list it is highly recommended.

It is inspired by the 'chef-client' cookbook for Chef - https://github.com/opscode-cookbooks/chef-client

Handlers
--------

The cookbook includes 3 report handlers that can be used to send information about the POSHChef run to a central repository.

  1.  ElasticSearch - store messages directly in ES
  2.  Graphite - Send information about the duration of the run to Graphite
  3.  Logstash - uses Redis to queue the messages that will be picked up by a Logstash server.

NOTE:  The logstash and ElasticSearch handlers are heavily influenced by Logstash.  If the ES handlers is used the index name and mapping from Logstash are assumed.

Requirements
------------

If the Logstash handler is being used then a logstash server needs to be configured so that the information can be given to this cookbook for configuration.

Attributes
----------
There are a lot of attributes associated with this cookbook, this is so that it is highly configurable and that other cookbooks can take advantage of the functionality that is provides.

+ node["POSHChef"]["interval"] - The time, in minutes, between each shceduled run of POSHChef.  Default: **30**
+ node["POSHChef"]["task"]["name"] - Name of the task in task scheduler. Default: **POSHChef**
+ node["POSHChef"]["task"]["description"] - Description of the task
+ node["POSHChef"]["task"]["folder"] - Folder within TaskScheduler to store the job. Default: **POSHChef**
+ node["POSHChef"]["task"]["triggers"] - Array of triggers that are associated with the job.
+ node["POSHChef"]["task"]["credentials"]["username"] - The account under which the scheduled task should run. Default: **Null**
+ node["POSHChef"]["task"]["credentials"]["username"] - The password associated with the specified account.  Default: **Null**

__"Once" Trigger__

["minutes"] - The delay to be applied before the first run of the scheduled task.  Default: **30**

__"Boot" Trigger__

["delay"]["minutes"] - The delay before the task is scheduled to run after the machine has booted.  Default: **2**

The following shows the default object for this which contains a "once" trigger and a "boot" trigger.

```JSON
[
  {
    "type": "once",
    "minutes": 30
  },
  {
    "type": "boot",
    "delay": {
      "minutes"@ 2
    }
  }
]
```

NOTE:  The above example shows the attributes being set using JSON.  In the cookbook attribute file they should be set in a PowerShell hashtable within the data file.

+ node["POSHChef"]["wsman"]["MaxEnvelopeSizekb"] - The size of the maximum enevlope size within WSMan.  The longer the run list in POSHChef the larger this will have to be.  Default: **2048**
+ node["POSHChef"]["wsman"]["shell\MaxMemoryPerShellMb"] - The amount of memory to be assigned to a PowerShell session, in KB.  Default: **1024**
+ node["POSHChef"]["paths"]["scripts"] - Default location for recipes to store scripts if they need to.  This is more for custom scripts that are built for third party application etc.  Default: **C:\Utilities\scripts**
+ node["POSHChef"]["paths"]["data"] - Default location for data for third party applications.  Default: **C:\Utilities\data**

The cookbook comes with 3 standard handlers.  The handlers are cookbook files and will be copied to the report handlers directory.  The defaults for these handlers are specified as attributes to this cookbook:

*graphite*

+ node["POSHChef"]["handlers"]["settings"]["grahite"]["server"] - Name or IP address of host running Graphite.  Default: **localhost**
+ node["POSHChef"]["handlers"]["settings"]["grahite"]["port"] - Port Graphite is running on.  Default: **2003**

*redis*

+ node["POSHChef"]["handlers"]["settings"]["redis"]["server"] - Name or IP address of host running Redis.  Default:  **localhost**
+ node["POSHChef"]["handlers"]["settings"]["redis"]["queue"] - Name of queue to add messages to.  Default:  **logstash**

*elasticsearch*

+ node["POSHChef"]["handlers"]["settings"]["elasticsearch"]["server"] - Name or IP address of host running Elasticsearch.  Default:  **localhost**
+ node["POSHChef"]["handlers"]["settings"]["elasticsearch"]["port"] - Port ElasticSearch is running on.  Default: **9200**
+ node["POSHChef"]["handlers"]["settings"]["elasticsearch"]["index"] - Name of the index to use on the ES server.  Todays date will be appended to this.  Default:  **logstash**
+ node["POSHChef"]["handlers"]["settings"]["elasticsearch"]["mapping"] - Name of the mapping to use in ES.  Default:  **logs**

A final array is specified to tell the system which handlers need to be enabled.

+ node["POSHChef"]["handlers"]["enabled"] = ["logstash-handler.ps1"]

Usage
-----
Add any of the following recipes to a run list in a role.  It is recommended that they are placed early on in the POSHChef run so that they things such as tasks and handlers are setup and deployed at the beginning.

#### POSHChef::default
This recipe performs three tasks:

  1. Ensure that the WSMAN settings are correct.  These are set in the attributes as detailed above.
  2. Ensure that all the directories for POSHChef all exist.
  3. Copy any enabled handlers to the machine.

#### POSHChef::task
Adds POSHChef as a scheduled task and a task to be run at boot up time.  The intervals etc for each of the tasks is configured using the attributes as specified in the cookbook.

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like dd_component_x)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Russell Seymour (<russell.seymour@turtlesystemsconsulting.co.uk>)

```text
Copyright:: 2010-2014, Turtlesystems Consulting, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
