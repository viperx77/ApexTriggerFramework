public with sharing class AccountBeforeInsertTriggerHandler implements TriggerFramework.IHandler {
	public static List<TriggerFramework.Context> contexts = new List<TriggerFramework.Context>();
	public void execute(TriggerFramework.Context context) {
		contexts.add(context);
	}
}