trigger ACAMSBeckerLMSTrigger on BeckerLMS_Enrollment__c (after insert, after update) {
	if (UserInfo.getName() != 'Data Migration') {
		(new ACAMSBeckerLMSTriggerHandler()).run();
	}
}