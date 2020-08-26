trigger ACAMSCaseScoreTrigger on Contact_Center_Scorecard__c (before insert, before update ) {
    if (UserInfo.getName() != 'Data Migration') {
        (new ACAMSCaseScoreTriggerHandler()).run();
    }
}