/**
 *      @author Kumar Ganadurai
 *      @date   06/05/2017 - Initial Version
        @description    ManageAttachments trigger on Attachment object created for certification eligibility calculation 
        
 */

trigger ManageAttachments on Attachment (after insert) {
 public Data_Migration_User__mdt  dMig = new Data_Migration_User__mdt();
   dMig = [select MasterLabel, ProfileId__c from Data_Migration_User__mdt where MasterLabel =: 'ProfileId' limit 1 ];
   String pfid= dMig.ProfileId__c;
     ID ProfId = userinfo.getProfileId();
     system.debug(ProfId );
     system.debug(pfid );
     system.debug(ProfId  != pfid);
     if(ProfId  != pfid ){
 AttachmentHelper.EvaluateCreditOnCerttification(trigger.new);
 }
}