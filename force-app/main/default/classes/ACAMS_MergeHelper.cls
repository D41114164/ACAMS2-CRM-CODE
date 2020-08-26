public class ACAMS_MergeHelper {

     public static void MergeLMSUser(List<Account> oldContacts, Map<Id, Account> oldMapContacts,String masterIDmerge, String cntIDmerge, String usernamemerge) {

         try{
         Set<Id> conmap=new Set<Id>();
         for(Account con:oldContacts){
            if(con.MasterRecordId != null )
        conmap.add(con.MasterRecordId);       
         }
          List<Account> contactlist=[SELECT Id,firstname,lastname,personemail FROM Account WHERE Id IN:conmap];
          string json_string;
          List<LMSUtility.LMSMergeRequest> lmsusermergeList = new List<LMSUtility.LMSMergeRequest>();
          LMSUtility.LMSMergeRequestList lmsusermergecontactList = new LMSUtility.LMSMergeRequestList();   
         

            System.debug('*****ContactHelper.MergeLMSUser.oldContacts: ' + oldContacts);
            System.debug('*****ContactHelper.MergeLMSUser.oldMapContacts: ' + oldMapContacts);
           
            if (oldContacts != NULL && oldContacts.size() > 0 && oldMapContacts != NULL && oldMapContacts.size() > 0 ){
              for(Account cwon :contactlist)
                for(Account c : oldContacts){
                    Account oldC = oldMapContacts.get(c.Id);
                    if (oldC != NULL  && c.MasterRecordId != null){
                       
                        LMSUtility.LMSMergeRequest lmsmergeuserfailed = new LMSUtility.LMSMergeRequest();
                        String cntId = c.Id;
                        lmsmergeuserfailed.contactId = cntId.capitalize();
                        lmsmergeuserfailed.firstName = c.FirstName;
                        lmsmergeuserfailed.lastName = c.LastName;
                        lmsmergeuserfailed.username = c.personemail;
                        lmsmergeuserfailed.master = false;
                        
                        LMSUtility.LMSMergeRequest lmsmergeuserwon = new LMSUtility.LMSMergeRequest();
                        String MasterId =c.MasterRecordId;
                        lmsmergeuserwon.contactId = MasterId.capitalize();
                        lmsmergeuserwon.firstName = cwon.FirstName;
                        lmsmergeuserwon.lastName = cwon.LastName;
                        lmsmergeuserwon.username = cwon.personemail;
                        lmsmergeuserwon.master = true;
                        
                       
                        lmsusermergeList.add(lmsmergeuserfailed);
                        lmsusermergeList.add(lmsmergeuserwon);
						lmsusermergecontactList.MergeAccounts = lmsusermergeList;
                        json_string = JSON.serialize(lmsusermergecontactList);
                       
                        system.debug(lmsusermergeList);
                        system.debug(lmsusermergecontactList);
                        system.debug(json_string);

                 	if (lmsusermergecontactList != null)
		                CalloutUtility.SendRequestMerge('AccountMergeIntegration', true, json_string, masterIDmerge,cntIDmerge,usernamemerge);
                    
                }
            }
                 
        }
          
         }
           catch(Exception ex){
          
            }
         
     }
  
 
       public static void MergeEnrollment(String masterID, String cntId, String username, String LibID) {
    
         List<BeckerLMS_Enrollment__c> lmsEnrollmentstomergemast = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentstomergedeac = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentstomerge2 = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentstomerge3 = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentstomerge4 = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentstomerge5 = new List<BeckerLMS_Enrollment__c>();
         BeckerLMS_Enrollment__c obj1 = new BeckerLMS_Enrollment__c();
         BeckerLMS_Enrollment__c obj2 = new BeckerLMS_Enrollment__c();
         Datetime st1;
         Datetime st2;
         String masterenrId;
   
          Set<Id> blist = new Set<Id>();
           try{
       lmsEnrollmentstomergemast = [SELECT Id, name, LMS_Course__c,Purchase_Date__c,LMS_Course_ID__c,Score__c,LastModifiedDate,Username__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Account__c = :masterID AND LMS_Course__c =:LibID ORDER BY LastModifiedDate asc LIMIT 1];
				system.debug(lmsEnrollmentstomergemast);
      
           if(lmsEnrollmentstomergemast.size()==1){
				 masterenrId=lmsEnrollmentstomergemast[0].id;
         
          lmsEnrollmentstomergedeac = [SELECT Id, name, LMS_Course__c,Purchase_Date__c,LMS_Course_ID__c,Score__c,LastModifiedDate,Username__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Account__c = :masterID AND LMS_Course__c =:LibID AND id !=: masterenrId ORDER BY LastModifiedDate desc];
               if(lmsEnrollmentstomergedeac.size()>0){
               system.debug(lmsEnrollmentstomergedeac);
               for(BeckerLMS_Enrollment__c blst:lmsEnrollmentstomergedeac){
                   blist.add(blst.id);
               }
               }
               system.debug(masterenrId);
          
              lmsEnrollmentstomerge2 = [SELECT Id, name, LMS_Course__c,Score__c,Username__c,BeckerLMS_Enrollment__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Account__c = :masterID AND BeckerLMS_Enrollment__c IN: blist ];
         		system.debug(lmsEnrollmentstomerge2);
             for(BeckerLMS_Enrollment__c blms:lmsEnrollmentstomerge2){
                 blms.BeckerLMS_Enrollment__c=masterenrId;
                 lmsEnrollmentstomerge3.add(blms);
             }
              
             update lmsEnrollmentstomerge3;
               system.debug(lmsEnrollmentstomerge3);
               
                     
                 List<LMSUtility.EnrollmentMergeRequest> lmsenrollmentmergeList = new List<LMSUtility.EnrollmentMergeRequest>();
          LMSUtility.EnrollmentMergeRequestList lmsenrollmentmergecontactList = new LMSUtility.EnrollmentMergeRequestList(); 
             
               for(BeckerLMS_Enrollment__c bmerge4:lmsEnrollmentstomergedeac) {
                    LMSUtility.EnrollmentMergeRequest lmsmergeenrollmentfailed = new LMSUtility.EnrollmentMergeRequest();
               Date failedtoConvert =  bmerge4.Purchase_Date__c ;    	
             String faileddate = datetime.newInstance(failedtoConvert.year(), failedtoConvert.month(), failedtoConvert.day()).format('YYYY-MM-dd');
                        lmsmergeenrollmentfailed.contactId = cntId.capitalize();
             lmsmergeenrollmentfailed.username = username;
                        lmsmergeenrollmentfailed.subscriptionId = bmerge4.id;
                        lmsmergeenrollmentfailed.purchaseDate = faileddate;
                        lmsmergeenrollmentfailed.master = false;
                   lmsenrollmentmergeList.add(lmsmergeenrollmentfailed);
               }
               system.debug(lmsenrollmentmergeList);
                         LMSUtility.EnrollmentMergeRequest lmsmergeenrollmentwon = new LMSUtility.EnrollmentMergeRequest();
             Date wontoConvert =  lmsEnrollmentstomergemast[0].Purchase_Date__c;
                       String wondate = datetime.newInstance(wontoConvert.year(), wontoConvert.month(), wontoConvert.day()).format('YYYY-MM-dd');
                        lmsmergeenrollmentwon.contactId = masterID.capitalize();
                      lmsmergeenrollmentwon.username = lmsEnrollmentstomergemast[0].Username__c;
                       lmsmergeenrollmentwon.subscriptionId = lmsEnrollmentstomergemast[0].id;
                       lmsmergeenrollmentwon.purchaseDate = wondate;
                        lmsmergeenrollmentwon.master = true;
               
                        system.debug(lmsmergeenrollmentwon);
                       string json_string;
      
                   
                        lmsenrollmentmergeList.add(lmsmergeenrollmentwon);
                 system.debug(lmsenrollmentmergeList);
						lmsenrollmentmergecontactList.MergeSubscriptionEnrollmentProgress = lmsenrollmentmergeList;
                        json_string = JSON.serialize(lmsenrollmentmergecontactList);
             system.debug(json_string);
               CalloutUtility.SendRequest('EnrollmentMergeIntegration', true, json_string);
         
         }
           }
            catch(Exception ex){
       
            }
           
      
         
     }
 
}