Apex Trigger Framework for Salesforce
=====================================

Background and Motivation
-------------------------
TBD

Documentation 
-------------
TBD

Examples
--------

Configure all your triggers as follows:

```java
	trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete ) {
		TriggerFramework.handle();
	}
```

Release History
---------------
TBD

About the Author
----------------

Hi, I'm Mark Lindell.  I am a architect working for Philips Healthcare.  You may reach me via twitter on [marklindell](http://twitter.com/marklindell)



