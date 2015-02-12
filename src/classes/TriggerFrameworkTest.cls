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

/*
	public static testmethod void integration_conventionBasedHandlerExists_isCalled() {		
		insert new Account(Name='foobar');
		system.assertEquals(1, AccountBeforeInsertTriggerHandler.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeInsert, AccountBeforeInsertTriggerHandler.contexts[0].event);
		system.assertEquals('Account', AccountBeforeInsertTriggerHandler.contexts[0].triggerObject);
	}

	public static testmethod void integration_conventionBasedHandlerIsDisabledInConfiguration_notCalled() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'AccountBeforeInsertTriggerHandler', 
				Enabled__c = false, 
				Trigger_Event__c = 'BeforeInsert');
		
		insert new Account(Name='foobar');
		system.assertEquals(0, AccountBeforeInsertTriggerHandler.contexts.size());
	}

	public static testmethod void integration_configurationBasedHandlerEnabled_isCalled() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeInsert');		
		insert new Account(Name='foobar');		
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeInsert, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForAfterInsert_isCalled() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'AfterInsert');
		insert new Account(Name='foo');
		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.AfterInsert, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals('Account', TestHandlerForConfiguration.contexts[0].triggerObject);
	}

	public static testmethod void integration_configurationBasedHandlerForBeforeUpdate_isCalled() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
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
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
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
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
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
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
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
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
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
		
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 				
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate');

		Account a = new Account(Name='foo');
		insert a;

		TestHandlerForConfiguration.reentrantTest = true;
		a.Name='baz';
		update a;

		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[0].event);
	}

*/
	public static testmethod void integration_setRentrant_onlyMaxIsAllowed() {
		
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 				
				Enabled__c = true, Trigger_Event__c = 'AfterUpdate',
				Max_ReEntry__c = 2);

		Account a = new Account(Name='foo');
		insert a;

		TestHandlerForConfiguration.reentrantTest = true;
		a.Name='baz';
		update a;

		system.assertEquals(2, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[0].event);
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[1].event);
	}

/*
	public static testmethod void integration_configuredFieldChangedCallsHandler() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='bar';
		update a;

		system.assertEquals(1, TestHandlerForConfiguration.contexts.size());
		system.assertEquals(TriggerFramework.Event.BeforeUpdate, TestHandlerForConfiguration.contexts[0].event);
	}

	public static testmethod void integration_fieldNotChanged_doesNotCallHandler() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Description='bar';
		update a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
	}

	public static testmethod void integration_fieldUpdatedToSameValue_doesNotCallHandler() {
		insert new Trigger_Handler_Configuration__c (
				Name = 'Account', Trigger_Handler_Class_Name__c = 'TestHandlerForConfiguration', 
				Enabled__c = true, Trigger_Event__c = 'BeforeUpdate', Fields__c = 'Name');
		Account a = new Account(Name='foo');
		insert a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
		a.Name='foo';
		update a;
		system.assertEquals(0, TestHandlerForConfiguration.contexts.size());
	}
*/
}