trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete ) {
	TriggerFramework.handle();
}