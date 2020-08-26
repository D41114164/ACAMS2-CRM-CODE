public class ACAMSBeckerLMSTriggerHandler extends CCAviTriggerHandler {

     private List<BeckerLMS_Enrollment__c> newList;
    private List<BeckerLMS_Enrollment__c> oldList;
    private Map<Id, BeckerLMS_Enrollment__c> newMap;
    private Map<Id, BeckerLMS_Enrollment__c> oldMap;
    
    public static Boolean raiseException = false;
    public class customException extends Exception {}
    private static Boolean alreadyProcessedCreateLMSEnrollment = false;
    private static Boolean alreadyProcessedUpsertAssetEnrollments = false;
     @TestVisible
     private static Boolean alreadyProcessedInsertAssetEnrollments = false;
     private static Boolean alreadyProcessedUpdateAssetEnrollments = false;

    public static Boolean isLMSEnrollmentUpdated = false;
    public static Boolean isEnterpriseLMSEnrollmentExecutedInsert = false;
    public static Boolean isEnterpriseLMSEnrollmentExecutedUpdate = false;
    public static Boolean isAssetEnrollmentCreated = false;
    public static Boolean isAssetEnrollmentUpdated = false;
    public static Boolean isAttendeeEnrollmentCreated = false;
    public static Boolean isAttendeeEnrollmentUpdated = false;
    public static Boolean isCEUCreated = false;
    public static Boolean isdcCEUCreated = false;

      public ACAMSBeckerLMSTriggerHandler() {
        super();
        this.newList = (List<BeckerLMS_Enrollment__c>) Trigger.new;
        this.oldList = (List<BeckerLMS_Enrollment__c>) Trigger.old;
        this.newMap = (Map<Id, BeckerLMS_Enrollment__c>) Trigger.newMap;
        this.oldMap = (Map<Id, BeckerLMS_Enrollment__c>) Trigger.oldMap;
    }
    public override void afterInsert() {
       CreateLMSEnrollment(this.newList);
    }
    public override void afterUpdate() {
       UpdateLMSEnrollment(this.newList, this.oldMap);
    }
    

    public static void CreateLMSEnrollment(List<BeckerLMS_Enrollment__c> newEnrollments) {
        if (!alreadyProcessedCreateLMSEnrollment) {
            alreadyProcessedCreateLMSEnrollment = true;
            system.debug('LMSEnrollmentHelper_restructured, CreateLMSEnrollment Method started $$$$$_3');
            try {
                if (raiseException) throw new customException('Testing code');
                List<LMSUtility.LMSCreateEnrollmentRequest> lmsEnrollmentList = new List<LMSUtility.LMSCreateEnrollmentRequest>();
                String username = Global_Variable__c.getValues('LMS.Username').Value__c;
                User lmsUser = [SELECT Id FROM User WHERE Username = :username];
                System.debug('*****LMSEnrollmentHelper.CreateLMSEnrollment.newEnrollments: ' + newEnrollments);
                if (newEnrollments != NULL && newEnrollments.size() > 0) {
                    for (BeckerLMS_Enrollment__c e : newEnrollments) {
                        if (e.CreatedById != lmsUser.Id) {
                            LMSUtility.LMSCreateEnrollmentRequest lmse = new LMSUtility.LMSCreateEnrollmentRequest();
                            lmse.id = e.Id;
                            lmse.enrolleeId = e.Account__c;
                            lmse.lmsCourseId = e.LMS_Course_ID__c;
                            lmse.name = e.Name;
                            lmse.startDate = (e.Start_Date__c == NULL ? NULL : (datetime.newInstance(e.Start_Date__c.year(), e.Start_Date__c.month(), e.Start_Date__c.day())).format('YYYY-MM-dd'));
                            lmse.endDate = (e.End_Date__c == NULL ? NULL : (datetime.newInstance(e.End_Date__c.year(), e.End_Date__c.month(), e.End_Date__c.day())).format('YYYY-MM-dd'));
                            lmse.purchaseDate = (e.Purchase_Date__c == NULL ? NULL : (datetime.newInstance(e.Purchase_Date__c.year(), e.Purchase_Date__c.month(), e.Purchase_Date__c.day())).format('YYYY-MM-dd'));
                            lmsEnrollmentList.add(lmse);
                        }
                    }
                }
                System.debug('*****LMSEnrollmentHelper.CreateLMSEnrollment.lmsEnrollmentList: ' + lmsEnrollmentList);
                if (lmsEnrollmentList.size() > 0)
                    CalloutUtility.SendRequest('CreateEnrollmentIntegration', true, LMSUtility.BuildJson(lmsEnrollmentList));
            } catch (Exception ex) {
                
            }
            system.debug('LMSEnrollmentHelper_restructured, CreateLMSEnrollment Method Ended $$$$$_3');
        }
    }

    public static void UpdateLMSEnrollment(List<BeckerLMS_Enrollment__c> newEnrollments, Map<Id, BeckerLMS_Enrollment__c> oldMapEnrollments) {
          system.debug('LMSEnrollmentHelper_restructured, UpdateLMSEnrollment Method started $$$$$_4');
        try{
            if (raiseException) throw new customException('Testing code');

            List<LMSUtility.LMSUpdateEnrollmentRequest> lmsEnrollmentList = new List<LMSUtility.LMSUpdateEnrollmentRequest>();
            String username = Global_Variable__c.getValues('LMS.Username').Value__c;
            User lmsUser = [SELECT Id FROM User WHERE Username = :username];

            System.debug('*****LMSEnrollmentHelper.UpdateLMSEnrollment.newEnrollments: ' + newEnrollments);
            System.debug('*****LMSEnrollmentHelper.UpdateLMSEnrollment.oldMapEnrollments: ' + oldMapEnrollments);

            if (newEnrollments != NULL && newEnrollments.size() > 0 && oldMapEnrollments != NULL && oldMapEnrollments.size() > 0){
                for(BeckerLMS_Enrollment__c e : newEnrollments){
                    BeckerLMS_Enrollment__c oldE = oldMapEnrollments.get(e.Id);
                    if (oldE != NULL && e.LastModifiedById != lmsUser.Id && (e.End_Date__c != oldE.End_Date__c || (e.Status__c != oldE.Status__c && (new Set<String>{'Enrolled', 'Cancelled'}).contains(e.Status__c)))){
                        isLMSEnrollmentUpdated = true;
                        LMSUtility.LMSUpdateEnrollmentRequest lmse = new LMSUtility.LMSUpdateEnrollmentRequest();
                        lmse.id = e.Id;
                        lmse.endDate = (e.End_Date__c == NULL ? NULL : (datetime.newInstance(e.End_Date__c.year(), e.End_Date__c.month(),e.End_Date__c.day())).format('YYYY-MM-dd'));
                        lmse.status = e.Status__c;
                        lmsEnrollmentList.add(lmse);
                    }
                }
            }
            System.debug('*****LMSEnrollmentHelper.UpdateLMSEnrollment.lmsEnrollmentList: ' + lmsEnrollmentList);

            if (lmsEnrollmentList.size() > 0)
                CalloutUtility.SendRequest('UpdateEnrollmentIntegration', true, LMSUtility.BuildJson(lmsEnrollmentList));
        }
        catch(Exception ex){
            
        }
        system.debug('LMSEnrollmentHelper_restructured, UpdateLMSEnrollment Method Ended $$$$$_4');
    }

    public static void UpsertAssetEnrollments(Set<Id> newAssetIds, Map<Id, Asset> oldAssetsMap,Boolean isInsert, Boolean isUpdate) {
     if (!alreadyProcessedInsertAssetEnrollments && isInsert) {
            if(isInsert && !isUpdate){
                alreadyProcessedInsertAssetEnrollments = true;
                system.debug('debug--alreadyProcessedInsertAssetEnrollments'+alreadyProcessedInsertAssetEnrollments);
            }
           
           // alreadyProcessedUpsertAssetEnrollments = true;
            system.debug('LMSEnrollmentHelper_restructured, UpsertAssetEnrollments Method started $$$$$_5');
            system.debug('debug--UpsertAssetEnrollments$$$$$$$$$$$---');
            try {
                if (raiseException) throw new customException('Testing code');
                List<BeckerLMS_Enrollment__c> lmsEnrollmentsToInsert = new List<BeckerLMS_Enrollment__c>();
                List<BeckerLMS_Enrollment__c> lmsEnrollmentsToUpdate = new List<BeckerLMS_Enrollment__c>();
                Map<Id, BeckerLMS_Enrollment__c> assetIdLMSEnrollmentMap = new Map<Id, BeckerLMS_Enrollment__c>();
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.newAssetIds: ' + newAssetIds);
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.oldAssetsMap: ' + oldAssetsMap);
                if (newAssetIds != NULL && newAssetIds.size() > 0) {
                    for (BeckerLMS_Enrollment__c e : [SELECT Id, Asset__c, End_Date__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Asset__c IN :newAssetIds])
                        assetIdLMSEnrollmentMap.put(e.Asset__c, e);
                    System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.assetIdLMSEnrollmentMap: ' + assetIdLMSEnrollmentMap);
                    for (Asset a : [
                            SELECT Id, Name, Status__c, Assignee__c,Assignee__r.name,Assignee__r.accountid, account.name, Accountid, CC_Product__r.ProductCategory__c,Effective_Date__c,CC_Product__r.Level_1__c, Paid_Cert__c, PurchaseDate, InstallDate,CurrentExpirationDate__c , LMS_Access_Exp_Date__c, CancelDate__c, CC_Product__r.LMS_Course__c, CC_Product__r.ccrz__SKU__c, CreatedDate
                            FROM Asset
                            WHERE Id IN :newAssetIds
                            AND Assignee__c != NULL AND (Payment_Status__c =: 'Completed' OR Payment_Status__c =: 'Authorized') AND RecordType.Name != 'Registrant']) {
                             Asset oldAsset = ((oldAssetsMap != NULL && oldAssetsMap.containsKey(a.Id)) ? oldAssetsMap.get(a.Id) : NULL);
                        if (a.CC_Product__r.LMS_Course__c != NULL && a.CC_Product__r.ccrz__SKU__c != NULL) {
                            if (!assetIdLMSEnrollmentMap.containsKey(a.Id)  && a.LMS_Access_Exp_Date__c != null &&  (a.CC_Product__r.Level_1__c != 'Enterprise Bundle' )) {
                                isAssetEnrollmentCreated = true;
                                BeckerLMS_Enrollment__c lmsEnrollment = new BeckerLMS_Enrollment__c();
                                lmsEnrollment.Asset__c = a.Id;
                                lmsEnrollment.Contact__c = a.Assignee__c;
                                if(a.Assignee__r.name != null && a.account.name != null && a.Assignee__r.name != a.account.name  ){
                                    lmsEnrollment.Account__c = a.Assignee__r.accountid;
                                    
                                } else{
                                    lmsEnrollment.Account__c = a.Accountid;
                                }
                                Date startDate = (a.Effective_Date__c != NULL ? a.Effective_Date__c : System.today());
                                lmsEnrollment.Purchase_Date__c = startDate;
                                lmsEnrollment.Start_Date__c = startDate;
                                lmsEnrollment.End_Date__c = a.LMS_Access_Exp_Date__c;
                                lmsEnrollment.LMS_Course__c = a.CC_Product__r.LMS_Course__c;
                                lmsEnrollment.GenerateCEU__c = GenerateCEU(a.CC_Product__r.ccrz__SKU__c);
                                lmsEnrollmentsToInsert.add(lmsEnrollment);
                            } else if (oldAsset != NULL) {
                                isAssetEnrollmentUpdated = true;
                                BeckerLMS_Enrollment__c lmsEnrollment = ((assetIdLMSEnrollmentMap != NULL && assetIdLMSEnrollmentMap.containsKey(a.Id)) ? assetIdLMSEnrollmentMap.get(a.Id) : NULL);
                                if (lmsEnrollment != NULL) {
                                    Date endDate = (a.CC_Product__r.Level_1__c == 'Certification' ? a.LMS_Access_Exp_Date__c : a.CurrentExpirationDate__c);
                                    lmsEnrollment.End_Date__c = (a.Status__c == 'Inactive' ? a.CancelDate__c : endDate);
                                    /*The below statement is replaced by a new if else condition which will not update the enrollment record status to cancelled when it is completed and its asset turns inactive
                                * Date: 05/16/2018
                                * Developer: Ram
                                 lmsEnrollment.Status__c = (a.Status__c == 'Inactive' ? 'Cancelled' : lmsEnrollment.Status__c);
                                */
                                    if (lmsEnrollment.Status__c == 'Completed') {
                                        lmsEnrollment.Status__c = lmsEnrollment.Status__c;
                                    } else {
                                        if (a.CancelDate__c != null)
                                            lmsEnrollment.Status__c = 'Cancelled' ; else
                                                lmsEnrollment.Status__c = lmsEnrollment.Status__c ;
                                    }
                                    lmsEnrollmentsToUpdate.add(lmsEnrollment);
                                }
                            }
                        }
                    }
                }
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.lmsEnrollmentsToInsert: ' + lmsEnrollmentsToInsert);
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.lmsEnrollmentsToUpdate: ' + lmsEnrollmentsToUpdate);
                if (lmsEnrollmentsToInsert != NULL && lmsEnrollmentsToInsert.size() > 0) {
                    DMLUtility.InsertSObjects(lmsEnrollmentsToInsert);
                }
                if (lmsEnrollmentsToUpdate != NULL && lmsEnrollmentsToUpdate.size() > 0) {
                    DMLUtility.UpdateSObjects(lmsEnrollmentsToUpdate);
                }
            } catch (Exception ex) {
                
            }
            system.debug('LMSEnrollmentHelper_restructured, UpsertAssetEnrollments Method Ended $$$$$_5');
        }
              if (!alreadyProcessedUpdateAssetEnrollments && isUpdate) {
          
        /*    if(!isInsert && isUpdate){
                alreadyProcessedUpdateAssetEnrollments = true;
                system.debug('debug--alreadyProcessedUpdateAssetEnrollments'+alreadyProcessedUpdateAssetEnrollments);
            }*/
           // alreadyProcessedUpsertAssetEnrollments = true;
            system.debug('LMSEnrollmentHelper_restructured, UpsertAssetEnrollments Method started $$$$$_5');
            system.debug('debug--UpsertAssetEnrollments$$$$$$$$$$$---');
            try {
                if (raiseException) throw new customException('Testing code');
                List<BeckerLMS_Enrollment__c> lmsEnrollmentsToInsert = new List<BeckerLMS_Enrollment__c>();
                List<BeckerLMS_Enrollment__c> lmsEnrollmentsToUpdate = new List<BeckerLMS_Enrollment__c>();
                Map<Id, BeckerLMS_Enrollment__c> assetIdLMSEnrollmentMap = new Map<Id, BeckerLMS_Enrollment__c>();
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.newAssetIds: ' + newAssetIds);
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.oldAssetsMap: ' + oldAssetsMap);
                if (newAssetIds != NULL && newAssetIds.size() > 0) {
                    for (BeckerLMS_Enrollment__c e : [SELECT Id, Asset__c, End_Date__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Asset__c IN :newAssetIds])
                        assetIdLMSEnrollmentMap.put(e.Asset__c, e);
                    System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.assetIdLMSEnrollmentMap: ' + assetIdLMSEnrollmentMap);
                    for (Asset a : [
                            SELECT Id, Name, Status__c, Assignee__c, Assignee__r.name,Assignee__r.accountid, account.name, Accountid, CC_Product__r.ProductCategory__c,Effective_Date__c,CC_Product__r.Level_1__c, Paid_Cert__c, PurchaseDate, InstallDate,CurrentExpirationDate__c , LMS_Access_Exp_Date__c, CancelDate__c, CC_Product__r.LMS_Course__c, CC_Product__r.ccrz__SKU__c, CreatedDate
                            FROM Asset
                            WHERE Id IN :newAssetIds
                            AND Assignee__c != NULL AND (Payment_Status__c =: 'Completed' OR Payment_Status__c =: 'Authorized') AND RecordType.Name != 'Registrant'
                    ]) {
                        Asset oldAsset = ((oldAssetsMap != NULL && oldAssetsMap.containsKey(a.Id)) ? oldAssetsMap.get(a.Id) : NULL);
                        if (a.CC_Product__r.LMS_Course__c != NULL && a.CC_Product__r.ccrz__SKU__c != NULL) {
                            if (!assetIdLMSEnrollmentMap.containsKey(a.Id) && a.LMS_Access_Exp_Date__c != null  &&  (a.CC_Product__r.Level_1__c != 'Enterprise Bundle')){
                                isAssetEnrollmentCreated = true;
                                BeckerLMS_Enrollment__c lmsEnrollment = new BeckerLMS_Enrollment__c();
                                lmsEnrollment.Asset__c = a.Id;
                                lmsEnrollment.Contact__c = a.Assignee__c;
                                 if(a.Assignee__r.name != null && a.account.name != null && a.Assignee__r.name != a.account.name  ){
                                    lmsEnrollment.Account__c = a.Assignee__r.accountid;
                                    
                                } else{
                                    lmsEnrollment.Account__c = a.Accountid;
                                }
                                Date startDate = (a.Effective_Date__c != NULL ? a.Effective_Date__c : System.today());
                                lmsEnrollment.Purchase_Date__c = startDate;
                                lmsEnrollment.Start_Date__c = startDate;
                                lmsEnrollment.End_Date__c = a.LMS_Access_Exp_Date__c;
                               lmsEnrollment.LMS_Course__c = a.CC_Product__r.LMS_Course__c;
                               lmsEnrollment.GenerateCEU__c = GenerateCEU(a.CC_Product__r.ccrz__SKU__c);
                                alreadyProcessedUpdateAssetEnrollments = true;
                                lmsEnrollmentsToInsert.add(lmsEnrollment);
                            } else if (oldAsset != NULL) {
                                isAssetEnrollmentUpdated = true;
                                BeckerLMS_Enrollment__c lmsEnrollment = ((assetIdLMSEnrollmentMap != NULL && assetIdLMSEnrollmentMap.containsKey(a.Id)) ? assetIdLMSEnrollmentMap.get(a.Id) : NULL);
                                if (lmsEnrollment != NULL) {
                                    Date endDate = (a.CC_Product__r.Level_1__c == 'Certification' ? a.LMS_Access_Exp_Date__c : a.CurrentExpirationDate__c);
                                    lmsEnrollment.End_Date__c = (a.Status__c == 'Inactive' ? a.CancelDate__c : endDate);
                                    /*The below statement is replaced by a new if else condition which will not update the enrollment record status to cancelled when it is completed and its asset turns inactive
                                * Date: 05/16/2018
                                * Developer: Ram
                                 lmsEnrollment.Status__c = (a.Status__c == 'Inactive' ? 'Cancelled' : lmsEnrollment.Status__c);
                                */
                                    if (lmsEnrollment.Status__c == 'Completed') {
                                        lmsEnrollment.Status__c = lmsEnrollment.Status__c;
                                    } else {
                                        if (a.CancelDate__c != null)
                                            lmsEnrollment.Status__c = 'Cancelled' ; else
                                                lmsEnrollment.Status__c = lmsEnrollment.Status__c ;
                                    }
                                    lmsEnrollmentsToUpdate.add(lmsEnrollment);
                                }
                            }
                        }
                    }
                }
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.lmsEnrollmentsToInsert: ' + lmsEnrollmentsToInsert);
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.lmsEnrollmentsToUpdate: ' + lmsEnrollmentsToUpdate);
                if (lmsEnrollmentsToInsert != NULL && lmsEnrollmentsToInsert.size() > 0) {
                    DMLUtility.InsertSObjects(lmsEnrollmentsToInsert);
                }
                if (lmsEnrollmentsToUpdate != NULL && lmsEnrollmentsToUpdate.size() > 0) {
                    DMLUtility.UpdateSObjects(lmsEnrollmentsToUpdate);
                }
            } catch (Exception ex) {
                
            }
            system.debug('LMSEnrollmentHelper_restructured, UpsertAssetEnrollments Method Ended $$$$$_5');
        }
    }

    public static void UpsertAttendeeEnrollments(Set<Id> newAttendeeIds, Map<Id, Asset> oldAttendeesMap) {
        system.debug('LMSEnrollmentHelper_restructured, UpsertAttendeeEnrollments Method started $$$$$_6');
        try{
            if (raiseException) throw new customException('Testing code');
      String ProductCodeType;
            List<BeckerLMS_Enrollment__c> lmsEnrollmentsToInsert = new List<BeckerLMS_Enrollment__c>();
            List<BeckerLMS_Enrollment__c> lmsEnrollmentsToUpdate = new List<BeckerLMS_Enrollment__c>();
            Map<Id, BeckerLMS_Enrollment__c> attendeeIdLMSEnrollmentMap = new Map<Id, BeckerLMS_Enrollment__c>();
            List<Asset> attendees = new List<Asset>();
            Set<String> productCodes = new Set<String>();
            Map<String, Id> courseIdsByProductCodeMap = new Map<String, Id>();

            System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.newAttendeeIds: ' + newAttendeeIds);
            System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.oldAttendeesMap: ' + oldAttendeesMap);

            if (newAttendeeIds != NULL && newAttendeeIds.size() > 0){
                for(BeckerLMS_Enrollment__c e : [SELECT Id, Attendee__c, End_Date__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Attendee__c IN :newAttendeeIds])
                    attendeeIdLMSEnrollmentMap.put(e.Attendee__c, e);

                for(Asset a : [ SELECT Id, Name, Status__c,Payment_Status__c, Assignee__r.name,Assignee__r.accountid, account.name, RecordType.Name, Accountid,Assignee__c,Effective_Date__c, CC_Product__r.ProductCategory__c, Paid_Cert__c, PurchaseDate, InstallDate,CurrentExpirationDate__c , LMS_Access_Exp_Date__c, CancelDate__c, CC_Product__r.LMS_Course__c, CC_Product__r.ccrz__SKU__c, CreatedDate
                            FROM Asset
                            WHERE Id IN :newAttendeeIds
                            AND Assignee__c != NULL AND (Payment_Status__c =: 'Completed' OR Payment_Status__c =: 'Authorized') AND RecordType.Name =:'Registrant']){
                    if (String.isNotBlank(a.CC_Product__r.ccrz__SKU__c)){
                        productCodes.add(a.CC_Product__r.ccrz__SKU__c);
                        attendees.add(a);
                    }
                }

                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.productCodes: ' + productCodes);
                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.attendees: ' + attendees);

                for(ccrz__E_Product__c p : [SELECT Id, ccrz__SKU__c, LMS_Course__c  FROM ccrz__E_Product__c WHERE ccrz__SKU__c IN :productCodes]){
                    courseIdsByProductCodeMap.put(p.ccrz__SKU__c, p.LMS_Course__c);
                }

                System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.courseIdsByProductCodeMap: ' + courseIdsByProductCodeMap);
            System.debug(1);
                for(Asset a : attendees){
                    System.debug(2);
                    Asset oldAttendee = ((oldAttendeesMap != NULL && oldAttendeesMap.containsKey(a.Id)) ? oldAttendeesMap.get(a.Id) : NULL);
                    System.debug(oldAttendee);
                     System.debug(String.isNotBlank(a.CC_Product__r.ccrz__SKU__c) && courseIdsByProductCodeMap.containsKey(a.CC_Product__r.ccrz__SKU__c));
                    if (String.isNotBlank(a.CC_Product__r.ccrz__SKU__c) && courseIdsByProductCodeMap.containsKey(a.CC_Product__r.ccrz__SKU__c)){
                        System.debug(String.isNotBlank(a.CC_Product__r.ccrz__SKU__c) && courseIdsByProductCodeMap.containsKey(a.CC_Product__r.ccrz__SKU__c));
                         System.debug(!attendeeIdLMSEnrollmentMap.containsKey(a.Id) && ((a.Payment_Status__c == 'Completed') || (a.Payment_Status__c == 'Authorized'))  && a.CurrentExpirationDate__c != NULL && (oldAttendee == NULL || oldAttendee.Paid_Cert__c != a.Paid_Cert__c || a.CurrentExpirationDate__c !=oldAttendee.CurrentExpirationDate__c));
                        if(!attendeeIdLMSEnrollmentMap.containsKey(a.Id) && ((a.Payment_Status__c == 'Completed') || (a.Payment_Status__c == 'Authorized')) && a.CurrentExpirationDate__c != NULL){
                            isAttendeeEnrollmentCreated = true;
                            BeckerLMS_Enrollment__c lmsEnrollment = new BeckerLMS_Enrollment__c();
                            lmsEnrollment.Attendee__c = a.Id;
                            lmsEnrollment.Contact__c = a.Assignee__c;
                             if(a.Assignee__r.name != null && a.account.name != null && a.Assignee__r.name != a.account.name  ){
                                    lmsEnrollment.Account__c = a.Assignee__r.accountid;
                                    
                                } else{
                                    lmsEnrollment.Account__c = a.Accountid;
                                }
                            lmsEnrollment.LMS_Course__c = courseIdsByProductCodeMap.get(a.CC_Product__r.ccrz__SKU__c);
                            Date startDate = (a.Effective_Date__c != NULL ? a.Effective_Date__c : System.today());
                            lmsEnrollment.Purchase_Date__c = startDate;
                            Date eventStartDate = startDate;
                            Date todayDate = System.Today();
                            lmsEnrollment.Start_Date__c = (eventStartDate >= todayDate ? eventStartDate : todayDate);
                            lmsEnrollment.End_Date__c = a.CurrentExpirationDate__c;

                            lmsEnrollmentsToInsert.add(lmsEnrollment);
                        } else if (oldAttendee != NULL && (oldAttendee.CurrentExpirationDate__c != a.CurrentExpirationDate__c || a.Paid_Cert__c == false)) {
                            isAttendeeEnrollmentUpdated = true;
                            BeckerLMS_Enrollment__c lmsEnrollment = ((attendeeIdLMSEnrollmentMap != NULL && attendeeIdLMSEnrollmentMap.containsKey(a.Id)) ? attendeeIdLMSEnrollmentMap.get(a.Id) : NULL);
                            if (lmsEnrollment != NULL){
                                lmsEnrollment.End_Date__c = (a.Paid_Cert__c == false ? (a.CancelDate__c == NULL ? System.today() : a.CancelDate__c) : a.CurrentExpirationDate__c);
                                lmsEnrollment.Status__c = (a.Paid_Cert__c == false ? 'Cancelled' : lmsEnrollment.Status__c);
                                lmsEnrollmentsToUpdate.add(lmsEnrollment);
                            }
                        }
                    }
                }
            }

            System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.lmsEnrollmentsToInsert: ' + lmsEnrollmentsToInsert);
            System.debug('*****LMSEnrollmentHelper.UpsertEnrollment.lmsEnrollmentsToUpdate: ' + lmsEnrollmentsToUpdate);

            if (lmsEnrollmentsToInsert != NULL && lmsEnrollmentsToInsert.size() > 0){
                DMLUtility.InsertSObjects(lmsEnrollmentsToInsert);
            }
            if (lmsEnrollmentsToUpdate != NULL && lmsEnrollmentsToUpdate.size() > 0){
                DMLUtility.UpdateSObjects(lmsEnrollmentsToUpdate);
            }
        }
        catch(Exception ex){
           
        }
        system.debug('LMSEnrollmentHelper_restructured, UpsertAttendeeEnrollments Method Eneded $$$$$_6');
    }


    private static Boolean GenerateCEU(String productCode){
        return !(productCode.startsWith('ENTPRIV') || productCode.startsWith('GLODWT'));
    }
    
     public static void UpsertEnterpriseMembershipEnrollments(Set<Id> newAssetIdsmem, Set<Id> newAssetIds) {
         set<id> AccntId = new set<id>();
         Date tdy = system.today();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentsToInsert = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> lmsEnrollmentsToUpdate = new List<BeckerLMS_Enrollment__c>();
		 Map<Id, BeckerLMS_Enrollment__c> assetIdLMSEnrollmentMap = new Map<Id, BeckerLMS_Enrollment__c>();
         Map<Id, Asset> accountToAssetEnterpiseMap = new Map<Id, Asset>();
         Map<Id, BeckerLMS_Enrollment__c> accountToEnrollmentEnterpiseMap = new Map<Id, BeckerLMS_Enrollment__c>();
         for(Asset ast :  [
                            SELECT Id, Name, Status__c, Assignee__c, Assignee__r.name,Assignee__r.accountid, account.name, Accountid, CC_Product__r.ProductCategory__c,CC_Product__r.Level_1__c, Paid_Cert__c, PurchaseDate, InstallDate,CurrentExpirationDate__c , LMS_Access_Exp_Date__c, CancelDate__c, CC_Product__r.LMS_Course__c, CC_Product__r.ccrz__SKU__c, CreatedDate
                            FROM Asset
                            WHERE Id IN :newAssetIdsmem
                            AND Accountid != NULL
                    ]){
             system.debug(ast.CC_Product__r.Level_1__c);
             if(ast.CC_Product__r.Level_1__c == 'Enterprise Bundle'){
                 accountToAssetEnterpiseMap.put(ast.AccountId, ast);
             }
             system.debug(accountToAssetEnterpiseMap);
         }
         for(BeckerLMS_Enrollment__c blms : [select id, Account__c, LMS_Course__c from BeckerLMS_Enrollment__c where Account__c IN: accountToAssetEnterpiseMap.keyset() AND LMS_Course__c =:Label.EntLibId ] ){
             accountToEnrollmentEnterpiseMap.put(blms.Account__c,blms);
         }
         system.debug(accountToEnrollmentEnterpiseMap);
         for (BeckerLMS_Enrollment__c e : [SELECT Id, Asset__c, End_Date__c, Status__c FROM BeckerLMS_Enrollment__c WHERE Asset__c IN :newAssetIds]){
             assetIdLMSEnrollmentMap.put(e.Asset__c, e);
         }
             system.debug(assetIdLMSEnrollmentMap);           
         for(Asset astEnrollments :  [
                            SELECT Id, Name, Status__c, Assignee__c, Assignee__r.name,Assignee__r.accountid, account.name, Accountid, CC_Product__r.ProductCategory__c, Effective_Date__c, CC_Product__r.Level_1__c, Paid_Cert__c, PurchaseDate, InstallDate,CurrentExpirationDate__c , LMS_Access_Exp_Date__c, CancelDate__c, CC_Product__r.LMS_Course__c, CC_Product__r.ccrz__SKU__c, CreatedDate
                            FROM Asset
                            WHERE Id IN :newAssetIdsmem
                            AND Accountid != NULL 
                    ] ){
             if(astEnrollments.Paid_Cert__c == true && (!assetIdLMSEnrollmentMap.containsKey(astEnrollments.Id))){
                 system.debug('for 1'); 
             if(accountToEnrollmentEnterpiseMap.containskey(astEnrollments.AccountId)){
                 system.debug('for 2'); 
                 //update existing enrollment
                 BeckerLMS_Enrollment__c lmsEnrollment = accountToEnrollmentEnterpiseMap.get(astEnrollments.AccountId);
                 lmsEnrollment.End_Date__c= astEnrollments.CurrentExpirationDate__c;
                 lmsEnrollment.Asset__c = astEnrollments.id;
                 lmsEnrollmentsToUpdate.add(lmsEnrollment);
                 system.debug(lmsEnrollmentsToUpdate); 
             }
                 
             else if(astEnrollments.CC_Product__r.Level_1__c == 'Enterprise Bundle'){
                 system.debug('For 3'); 
                 //insert enrollment
                 		  		BeckerLMS_Enrollment__c lmsEnrollment = new BeckerLMS_Enrollment__c();
                                lmsEnrollment.Asset__c = astEnrollments.Id;
                                lmsEnrollment.Contact__c = astEnrollments.Assignee__c;
                                 if(astEnrollments.Assignee__r.name != null && astEnrollments.account.name != null && astEnrollments.Assignee__r.name != astEnrollments.account.name  ){
                                    lmsEnrollment.Account__c = astEnrollments.Assignee__r.accountid;
                                    
                                } else{
                                    lmsEnrollment.Account__c = astEnrollments.Accountid;
                                }
                                Date startDate = (astEnrollments.Effective_Date__c != NULL ? astEnrollments.Effective_Date__c : System.today());
                                lmsEnrollment.Purchase_Date__c = startDate;
                                lmsEnrollment.Start_Date__c = startDate;
                                lmsEnrollment.End_Date__c = astEnrollments.CurrentExpirationDate__c;
                              	 lmsEnrollment.LMS_Course__c = astEnrollments.CC_Product__r.LMS_Course__c;
                               	lmsEnrollment.GenerateCEU__c = GenerateCEU(astEnrollments.CC_Product__r.ccrz__SKU__c);
                               
                                lmsEnrollmentsToInsert.add(lmsEnrollment);
             }
         }
         }
          system.debug(lmsEnrollmentsToInsert); 
         if (lmsEnrollmentsToInsert != NULL && lmsEnrollmentsToInsert.size() > 0) {
             		isEnterpriseLMSEnrollmentExecutedInsert =true;
                    DMLUtility.InsertSObjects(lmsEnrollmentsToInsert);
             		system.debug('DML 1'); 
                }
                if (lmsEnrollmentsToUpdate != NULL && lmsEnrollmentsToUpdate.size() > 0) {
                    isEnterpriseLMSEnrollmentExecutedUpdate = true;
                    DMLUtility.UpdateSObjects(lmsEnrollmentsToUpdate);
                    system.debug('DML 2'); 
                }

         
     }

}