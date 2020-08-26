trigger ACAMSValidateQueueNameTrigger on Assignment_Group_Queues__c (before insert, before update) {
    if (UserInfo.getName() != 'Data Migration') {
        (new ACAMSValidateQueueNameTriggerHandler()).run();
    }
}