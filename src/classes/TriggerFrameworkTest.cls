/*
	The MIT License (MIT)

	Copyright (c) 2015 Douglas Mark Lindell

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

@isTest
public with sharing class TriggerFrameworkTest { 

	public static testmethod void integration_conventionBasedHandlerExists_isCalled() {		
		TriggerFramework.enableConvention = true;
		insert new Account(Name='foobar');
		system.assertEquals(1, AccountBeforeInsertTriggerHandler.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeInsert, AccountBeforeInsertTriggerHandler.contexts[0].event);
		system.assertEquals('Account', AccountBeforeInsertTriggerHandler.contexts[0].triggerObject);
	}	
	
	public static testmethod void integration_conventionBasedHandlerIsDisabledInConfiguration_notCalled() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'AccountBeforeInsertTrigger', 
				Apex_Trigger_Handler_Class__c = 'AccountBeforeInsertTrigger',
				Object_Name__c = 'Account',
				Enabled__c = false, 
				Trigger_Event__c = 'BeforeInsert');
		TriggerFramework.enableConvention = true;
		insert new Account(Name='foobar');
		system.assertEquals(0, AccountBeforeInsertTriggerHandler.contexts.size());
	}

	public static testmethod void integration_configurationBasedHandlerEnabled_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',				
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeInsert');		
		insert new Account(Name='foobar');		
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeInsert, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForAfterInsert_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterInsert');
		insert new Account(Name='foo');
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterInsert, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForBeforeUpdate_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='bar';
		update a;
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForAfterUpdate_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='bar';
		update a;
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterUpdate, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForBeforeDelete_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeDelete');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		delete a;
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeDelete, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForAfterDelete_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterDelete');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		delete a;
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterDelete, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForAfterUndelete_isCalled() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUndelete');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		delete a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		undelete a;
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterUnDelete, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_defaultRentrant_isNotAllowed() {		
		
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 				
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate');

		Account a = new Account(Name='foo');
		insert a;

		TestHandlerForConfiguration.reentrantTest = true;
		a.Name='baz';
		update a;

		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterUpdate, TestHandlerForConfiguration.contexts[0].event);
	}

	public static testmethod void integration_setRentrant_onlyMaxIsAllowed() {
		
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 				
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate',
				Max_ReEntry__c = 2);

		Account a = new Account(Name='foo');
		insert a;

		TestHandlerForConfiguration.reentrantTest = true;
		a.Name='baz';
		update a;

		system.assertEquals(2, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterUpdate, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals(TriggerFramework.Event.AfterUpdate, TestHandlerForConfiguration.contexts[1].event);
	}

	public static testmethod void integration_configuredFieldChangedCallsBeforeUpdateHandler() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='bar';
		update a;

		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[0].event);
	}

	public static testmethod void integration_fieldNotChanged_doesNotCallBeforeUpdateHandler() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Description='bar';
		update a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
	}

	public static testmethod void integration_fieldUpdatedToSameValue_doesNotCallBeforeUpdateHandler() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='foo';
		update a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
	}

	public static testmethod void integration_configuredFieldChangedCallsAfterUpdateHandler() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='bar';
		update a;

		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterUpdate, TestHandlerForConfiguration.contexts[0].event);
	}

	public static testmethod void integration_fieldNotChanged_doesNotCallAfterUpdateHandler() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Description='bar';
		update a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
	}

	public static testmethod void integration_fieldUpdatedToSameValue_doesNotCallAfterUpdateHandler() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='foo';
		update a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
	}

	public static testmethod void integration_allHandlersConfigured_callsAll() {
		insert new Trigger_Handler_Configuration__c ( Name='AccountBeforeInsert',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeInsert');
		insert new Trigger_Handler_Configuration__c ( Name='AccountAfterInsert',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterInsert');
		insert new Trigger_Handler_Configuration__c ( Name='AccountBeforeUpdate',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate');
		insert new Trigger_Handler_Configuration__c ( Name='AccountAfterUpdate',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate');
		insert new Trigger_Handler_Configuration__c ( Name='AccountBeforeDelete',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeDelete');
		insert new Trigger_Handler_Configuration__c ( Name='AccountAfterDelete',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterDelete');
		insert new Trigger_Handler_Configuration__c ( Name='AccountAfterUndelete',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterUndelete');
		Account a = new Account(Name='foo');
		insert a;
		a.Description='bar';
		update a;
		delete a;
		undelete a;
		system.assertEquals(7, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeInsert, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals(TriggerFramework.Event.AfterInsert, TestHandlerForConfiguration.contexts[1].event);
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[2].event);
		system.assertEquals(TriggerFramework.Event.AfterUpdate, TestHandlerForConfiguration.contexts[3].event);
		system.assertEquals(TriggerFramework.Event.BeforeDelete, TestHandlerForConfiguration.contexts[4].event);
		system.assertEquals(TriggerFramework.Event.AfterDelete, TestHandlerForConfiguration.contexts[5].event);
		system.assertEquals(TriggerFramework.Event.AfterUndelete, TestHandlerForConfiguration.contexts[6].event);
	}

	public static testmethod void integration_usesNewTransaction_doesNotFailOtherTransaction() {

		TestHandlerForConfiguration.throwExceptionOn = TriggerFramework.Event.BeforeInsert;

		insert new Trigger_Handler_Configuration__c ( Name='AccountBeforeInsert',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeInsert', Use_New_Transaction__c = true);

		insert new Trigger_Handler_Configuration__c ( Name='AccountAfterInsert',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterInsert');

		Account a = new Account(Name='foo');
		insert a;

		system.assertEquals(2, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeInsert, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals(TriggerFramework.Event.AfterInsert, TestHandlerForConfiguration.contexts[1].event);
	}

	public static testmethod void integration_doesNotUseNewTransaction_exceptionStopsProcessing() {

		TestHandlerForConfiguration.throwExceptionOn = TriggerFramework.Event.BeforeInsert;

		insert new Trigger_Handler_Configuration__c ( Name='AccountBeforeInsert',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeInsert', Use_New_Transaction__c = false);

		insert new Trigger_Handler_Configuration__c ( Name='AccountAfterInsert',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterInsert');

		String message = '';
		try {
			Account a = new Account(Name='foo');
			insert a;
		} Catch (Exception ex) {
			message = ex.getMessage();
		}
		system.assert(message.contains('AccountTrigger: execution of BeforeInsert'));
	}

	public static testmethod void integration_configuredFieldChangedPassesObjectsInContextThatChanged() {
		insert new Trigger_Handler_Configuration__c ( Name='TestHandlerForConfiguration',
				Object_Name__c = 'Account', Apex_Trigger_Handler_Class__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');

		List<Account> accounts = new List<Account>();
		Account a1 = new Account(Name='foo1');
		accounts.Add(a1);
		Account a2 = new Account(Name='foo2');
		accounts.Add(a2);
		insert accounts;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a1.Name='bar';
		update accounts;

		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals(1, TestHandlerForConfiguration.contexts[0].oldList.size());
		system.assertEquals(1, TestHandlerForConfiguration.contexts[0].newList.size());
		system.assertEquals(1, TestHandlerForConfiguration.contexts[0].oldMap.size());
		system.assertEquals(1, TestHandlerForConfiguration.contexts[0].newMap.size());
		system.assertEquals('foo1', ((Account)TestHandlerForConfiguration.contexts[0].oldList[0]).Name);
		system.assertEquals('bar', ((Account)TestHandlerForConfiguration.contexts[0].newList[0]).Name);
		system.assertEquals('foo1', ((Account)TestHandlerForConfiguration.contexts[0].oldMap.get(a1.Id)).Name);
		system.assertEquals('bar', ((Account)TestHandlerForConfiguration.contexts[0].newMap.get(a1.Id)).Name);
	}


}