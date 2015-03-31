Apex Trigger Framework for Salesforce
=====================================

Background and Motivation
-------------------------
* Globally disable all triggers with configuration
* Easily reuse of trigger functionality across multiple trigger invocations
* Simplify testing of trigger logic without requiring insertion of SObjects
* Declarative calls of update triggers only on modified field values
* Support for convention and/or configuration 
* Transactional isolation of trigger logic
* Trigger recursion detection and re-entry protection
* Asynchronous dispatching of handlers (Future)

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
			// Implement your trigger logic here
		}
	}
```

To use configuration based handlers, configure as follows:
 
```java
insert new Trigger_Handler_Configuration__c ( Name='AccountBeforeInsertTriggerHandler',
		Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'AccountBeforeInsertTriggerHandler', 
		Enabled__c = true, Trigger_Event__c = 'BeforeInsert');
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



