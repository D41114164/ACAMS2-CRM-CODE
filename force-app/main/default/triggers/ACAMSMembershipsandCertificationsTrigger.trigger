trigger ACAMSMembershipsandCertificationsTrigger on Memberships_and_Certifications__c (after insert, after update) {
     if (UserInfo.getName() != 'Data Migration') {
          (new ACAMSMemsandCertTriggerHandler()).run();
     }
}