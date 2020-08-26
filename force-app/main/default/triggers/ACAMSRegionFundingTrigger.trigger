trigger ACAMSRegionFundingTrigger on Regional_Funding__c (Before insert,Before update,After insert,After update) {
    if (UserInfo.getName() != 'Data Migration') {
        (new ACAMSRegionFundingTriggerHandler()).run();
    }
}