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

public without sharing class TriggerFramework {

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

    public interface IMapFactory {
        Map<Id,SObject> createEmpty();
    }

    // Used to track the object name and the level
    private static Map<String, Integer> recursionDepth = new Map<String, Integer>();

    private static Map<String, Savepoint> savePoints = new Map<String, Savepoint>();

    // Use to cache if conventionBasedHandlers are enabled
    private static Map<String, Boolean> conventionBasedHandlerEnabled = new Map<String, Boolean>();

    // Used to cache configuration for convention based handler
    private static Map<String, Configuration> conventionBasedHandler = new Map<String, Configuration>();

    private static String getSObjectTypeName(List<SObject> oldList, List<SObject> newList) {
        if(oldList != null && oldList.getSObjectType() != null) {
            return oldList.getSObjectType().getDescribe().getName();
        }

        if(newList != null && newList.getSObjectType() != null) {
            return newList.getSObjectType().getDescribe().getName();
        }

        return '';
    }

    public static Boolean enableConvention = false;

    private static Event getEvent(Boolean isBefore, Boolean isAfter, Boolean isDelete, Boolean isInsert, Boolean isUpdate, Boolean isUndelete) {
        if (isBefore && isInsert) return Event.BeforeInsert;
        else if (isBefore && isUpdate) return Event.BeforeUpdate;
        else if (isBefore && isDelete) return Event.BeforeDelete;
        else if (isAfter && isInsert) return Event.AfterInsert;
        else if (isAfter && isUpdate) return Event.AfterUpdate;
        else if (isAfter && isDelete) return Event.AfterDelete;
        else if (isAfter && isUndelete) return Event.AfterUndelete;         
        throw new TriggerException('invalid combination of trigger parameters');
    }

    // Cache all the convention based trigger handler class names
    private static Set<String> triggerHandlerClasses;

    private static Configuration getConfigByConvention(TriggerFramework.Context context)
    {
        // Convention example: AccountBeforeInsertTriggerHandler
        String className = shortensobjectTypeName(context.triggerObject) + context.event.name() + 'TriggerHandler';

        // Use cache
        if (conventionBasedHandler.containsKey(className)) {
            return conventionBasedHandler.get(className);
        }

        if (triggerHandlerClasses == null) {
            List<ApexClass> classes = new List<ApexClass>([SELECT Name FROM ApexClass WHERE NAME LIKE '%TriggerHandler']);
            triggerHandlerClasses = pluckString(classes, 'Name');
        }

        if (triggerHandlerClasses.contains(className)) {
            conventionBasedHandler.put(className, new Configuration(className, context));
        } else {
            conventionBasedHandler.put(className, null);
        }
        return conventionBasedHandler.get(className);
    }

    private static Set<String> pluckString(List<SObject> records, String fieldName){
        return pluckString(listToSet(records),fieldName);
    }

    private static Set<String> pluckString(Set<SObject> records, String fieldName) {
        return objectToString(pluck(records,fieldName));
    }

    private static Set<SObject> listToSet(List<SObject> records) {
        Set<SObject> returnValue = null;
        if(records != null) {
            returnValue = new Set<SObject>();
            if(records.size() > 0){
                for(SObject record : records) {
                    returnValue.add(record);
                }
            }
        }
        return returnValue;
    }

    private static Set<Object> pluck(List<SObject> records, String fieldName) {
        return pluck(listToSet(records),fieldName);
    }   
     
    private static Set<Object> pluck(Set<SObject> records, String fieldName) {
        Set<Object> returnValue = null;
        if(records != null) {
            returnValue = new Set<Object>();
            if(records.size() > 0 && isNotBlank(fieldName)){
                for(SObject record : records) {
                    returnValue.add(record.get(fieldName));
                }
            }
        }
        return returnValue;
    }

    private static boolean isNotBlank(String str) {
        return !isBlank(str);
    }

    private static boolean isBlank(String str) {
        return str == null || str.trim() == null || str.trim().length() == 0;
    }

    private static Set<String> objectToString(Set<Object> objectSet){
        if(objectSet == null){
            return null;    
        }
        Set<String> stringSet = new Set<String>();
        for(Object anObject : objectSet){
            if(anObject instanceof String){
                stringSet.add((String)anObject);
            }
        }
        return stringSet;
    }

    private static String shortensobjectTypeName(String objectTypeName) {
        if (objectTypeName.toLowerCase().endsWith('__c')) {
            Integer index = objectTypeName.toLowerCase().indexOf('__c');
            return objectTypeName.substring(0, index);
        }
        else
            return objectTypeName;
    }

    private static Boolean matchesConfiguration(TriggerFramework.Context context, Trigger_Handler_Configuration__c config, List<Sobject> oldList, List<Sobject> newList) {

        if (config.Object_Name__c != context.triggerObject || config.Trigger_Event__c != context.event.name())
            return false;

        // Get the comma list of configured fields
        Set<String> configuredFields = new Set<String>();
        if (config.Fields__c != null) {
            configuredFields.addAll(config.Fields__c.split('[,]{1}[\\s]?'));
        }

        // No configured fields means any field changes calls the handler
        if (configuredFields.isEmpty()) 
            return true;

        // Peform field by field comparison
        for (SObject source : context.oldList ) {
            SObject destination = context.newMap.get(source.Id);
            for (String nextCheckField : configuredFields) {                
                if (String.valueof(source.get(nextCheckField)) != String.valueof(destination.get(nextCheckField)) ) {
                    oldList.add(source);
                    newList.add(destination);
                }
            }                
        }

        // If matching fields with configuration have changed then update the context
        if (oldList.size() == 0) {
            return false;
        }

        return true;
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

    private static TriggerFramework.IHandler createTriggerHandler(Configuration config, Context context) {
        TriggerFramework.IHandler handler = (TriggerFramework.IHandler)config.handlerType.newInstance();
        return handler;
    }

    private static void setMapAndListConfigFromHandler(TriggerFramework.IHandler handler, Configuration config, Context context) {

        // Initialize the config with the new maps
        IMapFactory factory = (IMapFactory)handler;
        config.oldMap = factory.createEmpty();
        config.newMap = factory.createEmpty();

        for (SObject next : config.oldList) {
            config.oldMap.put(next.Id, next);
        }
        for (SObject next : config.newList) {
            config.newMap.put(next.Id, next);
        }
    }

    private static TriggerFramework.IDispatcher createDispatcher(Configuration config) {
        return new DefaultTriggerDispatcher();
    }

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
            this.triggerObject = getSObjectTypeName(oldList, newList);
            this.event = getEvent(isBefore, isAfter, isDelete, isInsert, isUpdate, isUnDelete);
            this.isExecuting = isExecuting;
            this.recursionKey = this.triggerObject + '_' + this.event;
            this.isUpdate = isUpdate;
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
        public Boolean checksModifiedFields { get; private set; }
        public List<SObject> oldList { get; set; }
        public List<SObject> newList { get; set; }
        public Map<Id,SObject> oldMap { get; set; }
        public Map<Id,SObject> newMap { get; set; }

        // Private ctor for factory method
        private Configuration(Trigger_Handler_Configuration__c config, TriggerFramework.Context context, List<Sobject> oldList, List<SObject> newList) { 
            
            this.handlerType = Type.forName(config.Apex_Trigger_Handler_Class__c);
            this.maxReentry = config.Max_ReEntry__c;
            this.useNewTransaction = config.Use_New_Transaction__c;
            this.checksModifiedFields = !(config.Fields__c == null || String.isEmpty(config.Fields__c));
            this.oldList = oldList;
            this.newList = newList;
        }

        // Private ctor for factory method
        private Configuration(String handlerType, TriggerFramework.Context context) {
            this.handlerType = Type.forName(handlerType);
            this.maxReentry = 1;
            this.useNewTransaction = false;
            this.checksModifiedFields = false;
        }
    }

    private static List<Configuration> findConfigFor(TriggerFramework.Context context) {

        List<Configuration> configurationsFound = new List<Configuration>();

        List<Trigger_Handler_Configuration__c> configurations =  Trigger_Handler_Configuration__c.getall().values();

        Configuration conventionConfig = (enableConvention) ? getConfigByConvention(context) : null;

        for (Trigger_Handler_Configuration__c config : configurations ) {

            if (config.Enabled__c) {
                List<SObject> oldList = new List<SObject>();
                List<SObject> newList = new List<SObject>();
                if (matchesConfiguration(context, config, oldList, newList)) {
                    configurationsFound.add(new Configuration(config, context, oldList, newList));
                }               
            } else if (conventionConfig != null) {
                // If the configuration has a disabled handler, check if the convention handler
                // is disabled in the configuration
                String key = config.Apex_Trigger_Handler_Class__c;
                if (!conventionBasedHandlerEnabled.containsKey(key)) {
                    conventionBasedHandlerEnabled.put(key, config.Enabled__c);
                }
                if (!conventionBasedHandlerEnabled.get(key)) {
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
                        TriggerFramework.IHandler handler = createTriggerHandler(config, context);
                        if (config.checksModifiedFields && handler instanceof IMapFactory) {
                            setMapAndListConfigFromHandler(handler, config, context);
                        }
                        TriggerFramework.IDispatcher dispatcher = createDispatcher(config);

                        if (config.checksModifiedFields) {
                            // Create a new context using the replaced maps and lists on the config
                            dispatcher.dispatch(
                                    new Context(config.oldList, config.newList, config.oldMap, config.newMap,
                                        Trigger.isBefore, Trigger.isAfter, Trigger.isDelete, Trigger.isInsert, Trigger.isUpdate, Trigger.isUnDelete,
                                        Trigger.isExecuting), 
                                    handler);
                        } else
                        {
                            dispatcher.dispatch(context, handler);    
                        }
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

    public with sharing class DefaultTriggerDispatcher implements TriggerFramework.IDispatcher {
        public void dispatch(Context triggerContext, IHandler handler) {
            handler.execute(triggerContext);
        }
    }

}