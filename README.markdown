Apex Trigger Framework for Salesforce
=====================================

Background and Motivation
-------------------------
TBD

Documentation 
-------------

Configure all your triggers as follows:

```java
	trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete ) {
		TriggerFramework.handle();
	}
```

To use convention based handlers, name the class using the following approach:

```java
	public with sharing class AccountBeforeInsertTriggerHandler implements TriggerFramework.IHandler {
		public void execute(TriggerFramework.Context context) {
		}
	}
```

The class will be called before insert of the Account object.  The Context object contains the following:

Property      | Description
--------------|-------------
Event         | An enumeration of the 7 possible events (BeforeInsert, AfterInsert, BeforeUpdate, AfterUpdate, BeforeDelete, AfterDelete, AfterUndelete)
oldList       | List<SObject> of the old objects
newList       | List<SObject> of the new objects
oldMap        | Map<Id, SObject> of the old objects
newMap        | Map<Id, SObject> of the new objects
triggerObject | The name of the object triggering
isExecuting   | Is the trigger executing

Release History
---------------
TBD

About the Author
----------------

Hi, I'm Mark Lindell.  I am a architect working for Philips Healthcare.  You may reach me via twitter on [marklindell](http://twitter.com/marklindell)



