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

public with sharing class TriggerFramework {

	public Enum Event { 
		BeforeInsert, 
		BeforeUpdate, 
		BeforeDelete, 
		AfterInsert, 
		AfterUpdate, 
		AfterDelete, 
		AfterUndelete 
	}

	public interface IDispatcher {
		void dispatch(Context context, IHandler handler);
	}

	public interface IHandler {
		void execute(Context context);
	}

	// Used to track the object name and the level
	private static Map<String, Integer> recursionDepth = new Map<String, Integer>();

	private static Map<String, Savepoint> savePoints = new Map<String, Savepoint>();

	// Use to cache if conventionBasedHandlers are enabled
	private static Map<String, Boolean> conventionBasedHandlerEnabled = new Map<String, Boolean>();

	// Used to cache configuration for convention based handler
	private static Map<String, Configuration> conventionBasedHandler = new Map<String, Configuration>();

	private static String getSObjectTypeName(SObject so) {
		return so.getSObjectType().getDescribe().getName();
	}

	private static Event getEvent(Boolean isBefore, Boolean isAfter, Boolean isDelete, Boolean isInsert, Boolean isUpdate, Boolean isUndelete) {
		if (isBefore & isInsert) return Event.BeforeInsert;
		else if (isBefore && isUpdate) return Event.BeforeUpdate;
		else if (isBefore && isDelete) return Event.BeforeDelete;
		else if (isAfter && isInsert) return Event.AfterInsert;
		else if (isAfter && isUpdate) return Event.AfterUpdate;
		else if (isAfter && isDelete) return Event.AfterDelete;
		else if (isAfter && isUndelete) return Event.AfterUndelete;			
		throw new TriggerException('invalid combination of trigger parameters');
	}

    private static Configuration getConfigByConvention(String typeName, TriggerFramework.Event event)
    {
        // Convention example: AccountBeforeInsertTriggerHandler
        String className = shortensobjectTypeName(typeName) + event.name() + 'TriggerHandler';

        // Use cache
        if (conventionBasedHandler.containsKey(className)) {
        	return conventionBasedHandler.get(className);
        }

        // Loopup
        Integer matches = [SELECT COUNT() FROM ApexClass WHERE Name = :className];
        if (matches == 0) {
        	conventionBasedHandler.put(className, null);
        } else {
        	conventionBasedHandler.put(className, new Configuration(className));
        }
        return conventionBasedHandler.get(className);
    }

    private static String shortensobjectTypeName(String objectTypeName) {
        if (objectTypeName.toLowerCase().endsWith('__c')) {
            Integer index = objectTypeName.toLowerCase().indexOf('__c');
            return objectTypeName.substring(0, index);
        }
        else
            return objectTypeName;
    }   


	private static Boolean matchesConfiguration(String targetObjectName, String triggerEvent, String triggeringObjectName, TriggerFramework.Event event, 
		Set<String> updatedFieldNames, Set<String> configuredFields) {

		if (targetObjectName == triggeringObjectName && triggerEvent == event.name()) {
			
			// No configured fields means any field changes calls the handler
			if (configuredFields.isEmpty()) 
				return true;

			// No fields update check
			if (updatedFieldNames == null)
				return true;

			for (String nextUpdatedField : updatedFieldNames) {
				if (configuredFields.contains(nextUpdatedField)) {
					return true;
				}
			}				
		}
		return false;
	}

    private static Boolean validConfig(Configuration config, Context triggerContext) {

        if (config == null) {
            return false;
        }

        // Allow to re-enter
        if (triggerContext.getRecursionDepth() <= config.maxReentry) {
            return true;            
        }

        return false;
    }

    private static TriggerFramework.IHandler createTriggerHandler(Configuration config) {
        // TODO: handle exceptions for mis-configuration?
        return (TriggerFramework.IHandler)config.handlerType.newInstance();
    }

    private static TriggerFramework.IDispatcher createDispatcher(Configuration config) {
        return new DefaultTriggerDispatcher();
    }

	private static final List<Schema.DisplayType> STRING_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.base64
        ,Schema.DisplayType.Email
        ,Schema.DisplayType.MultiPicklist
        ,Schema.DisplayType.Phone
        ,Schema.DisplayType.Picklist
        ,Schema.DisplayType.String
        ,Schema.DisplayType.TextArea
        ,Schema.DisplayType.URL
    };
    private static final List<Schema.DisplayType> INTEGER_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.Integer
    };
    private static final List<Schema.DisplayType> ID_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.ID
        ,Schema.DisplayType.Reference
    };
    private static final List<Schema.DisplayType> DOUBLE_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.Currency
        ,Schema.DisplayType.Double
        ,Schema.DisplayType.Percent
    };
    private static final List<Schema.DisplayType> DATETIME_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.DateTime
    };
    private static final List<Schema.DisplayType> DATE_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.Date
    };
    private static final List<Schema.DisplayType> BOOLEAN_TYPES = new List<Schema.DisplayType>{
        Schema.DisplayType.Boolean
        ,Schema.DisplayType.Combobox
    };

   private static Boolean contains(List<Schema.DisplayType> aListActingAsSet, Schema.DisplayType typeToCheck) {
        if(aListActingAsSet != null && aListActingAsSet.size() > 0){
            for(Schema.DisplayType aType : aListActingAsSet){
                if(aType == typeToCheck){
                    return true;
                }
            }
        }
        return false;
    }

 	private static final Map<String,Schema.DescribeSObjectResult> cachedDescribes = new Map<String,Schema.DescribeSObjectResult>();
    private static Schema.DescribeSObjectResult getCachedDescribe(SObject obj){
        if(obj == null){
            return null;
        }
        final String objectApiName = ''+ obj.getsObjectType();
        if(!cachedDescribes.containsKey(objectApiName)){
            cachedDescribes.put(objectApiName, obj.getsObjectType().getDescribe());
        }
        return cachedDescribes.get(objectApiName);
    }

 	private static final Map<Schema.DescribeSObjectResult,Map<String,Schema.SObjectField>> cachedFieldDescribes = new Map<Schema.DescribeSObjectResult,Map<String,Schema.SObjectField>>();
    private static Map<String,Schema.SObjectField> getCachedFieldDescribe(SObject obj){
    	Schema.DescribeSObjectResult schema = getCachedDescribe(obj);
        if(schema == null){
            return null;
        }        
        if(!cachedFieldDescribes.containsKey(schema)){
            cachedFieldDescribes.put(schema, schema.fields.getMap());
        }
        return cachedFieldDescribes.get(schema);
    }

    private static Set<String> getModifiedFields(Context triggerContext) {

        /*  Valid for each event type:
            BeforeInsert   new
            BeforeUpdate   new      newMap  old     oldMap
            BeforeDelete                    old     oldMap
            AfterInsert    new      newMap
            AfterUpdate    new      newMap  old     oldMap
            AfterDelete                     old     oldMap
            AfterUndelete 
        */

        Set<String> modified = new Set<String>();

        if (triggerContext.event == TriggerFramework.Event.BeforeUpdate || triggerContext.event == TriggerFramework.Event.AfterUpdate) {
        	for (SObject source : triggerContext.newList ) {
        		SObject destination = triggerContext.oldMap.get(source.Id);
        		Map<String,Schema.SObjectField> sourceFields = getCachedFieldDescribe(source);
        		for(String fieldName : sourceFields.keySet()) { 
		            Schema.DescribeFieldResult sourceField = sourceFields.get(fieldName).getDescribe();
		            if(contains(STRING_TYPES,sourceField.getType())) {
		                if ((String)source.get(sourceField.getName()) != (String)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            } else if(contains(INTEGER_TYPES,sourceField.getType())) {
		                if ((Integer)source.get(sourceField.getName()) != (Integer)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            } else if(contains(ID_TYPES,sourceField.getType())) {
		                if ((Id)source.get(sourceField.getName()) != (Id)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            } else if(contains(DOUBLE_TYPES,sourceField.getType())) {
		                if ((Double)source.get(sourceField.getName()) != (Double)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            } else if(contains(DATETIME_TYPES,sourceField.getType())) {
		                if ((DateTime)source.get(sourceField.getName()) != (DateTime)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            } else if(contains(DATE_TYPES,sourceField.getType())) {
		                if ((Date)source.get(sourceField.getName()) != (Date)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            } else if(contains(BOOLEAN_TYPES,sourceField.getType())) {
		                if ((Boolean)source.get(sourceField.getName()) != (Boolean)destination.get(sourceField.getName())) {
		                	modified.add(sourceField.getName());
		                }
		            }
		        }
        	}
        }
        return modified;
    }

	public class Context {

		public Event event { get; private set;}	
		public List<SObject> oldList { get; private set; }
		public List<SObject> newList { get; private set; }
		public Map<Id, SObject> oldMap { get; private set; }
		public Map<Id, SObject> newMap { get; private set; }
		public String triggerObject { get; private set; }
		public Boolean isExecuting { get; private set; }
		public String recursionKey { get; private set; }
		public Boolean isUpdate { get; private set; }

		public Context(List<SObject> oldList, List<SObject> newList, Map<Id, SObject> oldMap, Map<Id, SObject> newMap,
									Boolean isBefore, Boolean isAfter, Boolean isDelete, Boolean isInsert, Boolean isUpdate, Boolean isUndelete, 
									Boolean isExecuting) {

			this.oldList = oldList;
			this.newList = newList;
			this.oldMap = oldMap;
			this.newMap = newMap;
			this.triggerObject = getSObjectTypeName((this.oldList != null && this.oldList.size() > 0) ? this.oldList[0] : this.newList[0]);
			this.event = getEvent(Trigger.isBefore, Trigger.isAfter, Trigger.isDelete, Trigger.isInsert, Trigger.isUpdate, Trigger.isUnDelete);
			this.isExecuting = isExecuting;
			this.recursionKey = this.triggerObject + '_' + this.event;
			this.isUpdate = ((this.event == TriggerFramework.Event.BeforeUpdate) || (this.event == TriggerFramework.Event.AfterUpdate));
		}

		public Integer getRecursionDepth() {
			if (!recursionDepth.containsKey(this.recursionKey)) {
				throw new TriggerException('enter not called');
			}
			return recursionDepth.get(this.recursionKey);	
		}

		public void enterObject() {
			if (!recursionDepth.containsKey(this.recursionKey)) {
				recursionDepth.put(this.recursionKey, 0);
			}
			recursionDepth.put(this.recursionKey, recursionDepth.get(this.recursionKey) + 1);
		}

		public void exitObject() {
			if (!recursionDepth.containsKey(this.recursionKey)) {
				throw new TriggerException('exit called without enter');
			}
			Integer i = recursionDepth.get(this.recursionKey) - 1;
			if (i < 0) {
				throw new TriggerException('enter/exit mismatch');	
			}
			recursionDepth.put(this.recursionKey, i);
		}

		public void beginTrans() {
			if (!savePoints.containsKey(this.triggerObject)) {
				Savepoint sp = Database.setSavepoint();
				savePoints.put(this.triggerObject, sp);
			}
		}

		public void rollbackTrans() {		
			if (!savePoints.containsKey(this.triggerObject)) {
				throw new TriggerException('No beginTrans() called for ' + this.triggerObject);
			} else {
				Savepoint sp = savePoints.get(this.triggerObject);
				Database.rollback(sp);
				savePoints.remove(this.triggerObject);
			}		
		}

	}	

	public class TriggerException extends Exception {}	

	public with sharing class Configuration {
		
		public Decimal maxReentry { get; private set; }
		public Boolean useNewTransaction { get; private set; }
		public Type handlerType { get; private set; }

		// Private ctor for factory method
		private Configuration(Trigger_Handler_Configuration__c config) { 
			this.handlerType = Type.forName(config.Apex_Trigger_Handler_Class__c);
			this.maxReentry = config.Max_ReEntry__c;
			this.useNewTransaction = config.Use_New_Transaction__c;
		}

		// Private ctor for factory method
		private Configuration(String handlerType) {
			this.handlerType = Type.forName(handlerType);
			this.maxReentry = 1;
			this.useNewTransaction = false;
		}
	}

	private static List<Configuration> findConfigFor(TriggerFramework.Context context) {

		List<Configuration> configurationsFound = new List<Configuration>();

		List<Trigger_Handler_Configuration__c> configurations =  Trigger_Handler_Configuration__c.getall().values();

		Configuration conventionConfig = getConfigByConvention(context.triggerObject, context.event);

		for (Trigger_Handler_Configuration__c config : configurations ) {

			if (config.Enabled__c) {

				// Get the comma list of configured fields
				Set<String> configuredFields = new Set<String>();
				if (config.Fields__c != null) {
					configuredFields.addAll(config.Fields__c.split('[,]{1}[\\s]?'));
				}

				// Only need to determine modified fields if there are fields configured
				// to check and this is an update
				Set<String> updatedFieldNames = new Set<String>();
				if (configuredFields.size() != 0 && context.isUpdate) {
					updatedFieldNames = getModifiedFields(context);
				}

				if (matchesConfiguration(config.Object_Name__c, config.Trigger_Event__c, context.triggerObject, context.event, updatedFieldNames, configuredFields)) {
					configurationsFound.add(new Configuration(config));
				}				
			} else if (conventionConfig != null) {
				// If the configuration has a disabled handler, check if the convention handler
				// is disabled in the configuration
				if (!conventionBasedHandlerEnabled.containsKey(config.Apex_Trigger_Handler_Class__c)) {
					conventionBasedHandlerEnabled.put(config.Apex_Trigger_Handler_Class__c, config.Enabled__c);
				}
				if (!conventionBasedHandlerEnabled.get(config.Apex_Trigger_Handler_Class__c)) {
					conventionConfig = null;
				}
			}
		}

		if (conventionConfig != null) {
			configurationsFound.add(conventionConfig);
		}

		return configurationsFound;
	}

    public static void handle()
    {
        Context context = new Context(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap,
            Trigger.isBefore, Trigger.isAfter, Trigger.isDelete, Trigger.isInsert, Trigger.isUpdate, Trigger.isUnDelete,
            Trigger.isExecuting);

        try {
            context.enterObject();
            List<TriggerFramework.Configuration> configs = findConfigFor(context);
            for (Configuration config : configs) {
                if (validConfig(config, context)) {
                    try {
                        if (config.useNewTransaction) {
                            context.beginTrans();
                        }
                        TriggerFramework.IHandler handler = createTriggerHandler(config);
        				TriggerFramework.IDispatcher dispatcher = createDispatcher(config);

                        // Use the dispatcher to dispatch this trigger context to the handler
                        dispatcher.dispatch(context, handler);

                    } catch (Exception ex) {
                        if (config.useNewTransaction) {
                            context.rollbackTrans();
                        } else {
                        	throw ex;
                        }

                    }
                }
            }            
        } finally {
        	context.exitObject();
        }
    }

	public with sharing class AsyncTriggerDispatcher implements TriggerFramework.IDispatcher {
		public void dispatch(Context triggerContext, IHandler handler) {
			// TODO: Use Queueable or other async method
			handler.execute(triggerContext);
		}
	}	

	public with sharing class DefaultTriggerDispatcher implements TriggerFramework.IDispatcher {
		public void dispatch(Context triggerContext, IHandler handler) {
			handler.execute(triggerContext);
		}
	}

}