public class ACAMSAssetTriggerHandler extends CCAviTriggerHandler {

    private List<Asset> newList;
    private List<Asset> oldList;
    private Map<Id, Asset> newMap;
    private Map<Id, Asset> oldMap;
    private Boolean isInsert;
    private Boolean isUpdate;
    public static Boolean isLMSUserCreated = false;
    private static boolean isRecursiveChapterCheck = false;
    private static boolean isRecursiveBeforeUpdate = false;
    public static Boolean isHLContactUpdated = false;
    public static Boolean isWhitepaperUpdated = false;
    public static Boolean isauthorizedStatusUpdated = false;
    public static Boolean isrecertExpDateUpdated = false;
    

    public static set<Id> assetIds=new set<Id>();

    
    public ACAMSAssetTriggerHandler() {
        super();
        this.newList = (List<Asset>) Trigger.new;
        this.oldList = (List<Asset>) Trigger.old;
        this.newMap = (Map<Id, Asset>) Trigger.newMap;
        this.oldMap = (Map<Id, Asset>) Trigger.oldMap;
        this.isInsert =  Trigger.isInsert;
        this.isUpdate =  Trigger.isUpdate;
    }

     /**
     ** @description: added logic for 2. Certification Asset: Populate the LMS access expiration Date upon
     *the payment.
     * @Date: July 2, 2020 - Rui
     * @source: issue/Defect UAT LOG Row 301 "Layout" -
     * https://app.smartsheet.com/sheets/CQ2rPHChHxfRvwPQ4m38fwVVcx4V6xCMmgf2pHw1?view=grid
     */
    public override void beforeInsert() {
        updateLMSExpirationDate(this.newList, null);
    }

    public override void beforeUpdate(){
        updateLMSExpirationDate(this.newList, this.oldMap);
    }
    /**  ended  */
      public override void afterInsert() {
          if(!ACAMSBeckerLMSTriggerHandler.isAssetEnrollmentCreated){
              if (!isLMSUserCreated ){
          UpsertLMSUser(this.newList);
              }
           ACAMSBeckerLMSTriggerHandler.UpsertAssetEnrollments(this.newMap.KeySet(), NULL,this.isInsert,this.isUpdate);
          }
          if(!ACAMSBeckerLMSTriggerHandler.isEnterpriseLMSEnrollmentExecutedInsert){
           ACAMSBeckerLMSTriggerHandler.UpsertEnterpriseMembershipEnrollments(this.newMap.KeySet(), this.newMap.KeySet());
          }
          if (!ACAMSBeckerLMSTriggerHandler.isAttendeeEnrollmentCreated ) {
                ACAMSBeckerLMSTriggerHandler.UpsertAttendeeEnrollments(this.newMap.KeySet(), NULL); 
          }
            if (!isHLContactUpdated ) {
          updateHLGrouponContact(this.newList,null);
           }
         
    }
    public override void afterUpdate() {
        if((!ACAMSBeckerLMSTriggerHandler.isAssetEnrollmentUpdated || !ACAMSBeckerLMSTriggerHandler.isAssetEnrollmentCreated)){
        if (!isLMSUserCreated){
            UpsertLMSUser(this.newList);
        }
            ACAMSBeckerLMSTriggerHandler.UpsertAssetEnrollments(this.newMap.KeySet(), this.oldMap,this.isInsert ,this.isUpdate);
        }
              AcamsHelperMethod(this.newList,this.oldList);
        if(!ACAMSBeckerLMSTriggerHandler.isEnterpriseLMSEnrollmentExecutedUpdate){
        ACAMSBeckerLMSTriggerHandler.UpsertEnterpriseMembershipEnrollments(this.newMap.KeySet(), this.newMap.KeySet());
        }
        if (!ACAMSBeckerLMSTriggerHandler.isAttendeeEnrollmentUpdated || !ACAMSBeckerLMSTriggerHandler.isAttendeeEnrollmentCreated)  {
             //ACAMSBeckerLMSTriggerHandler.UpsertAttendeeEnrollments(this.newMap.KeySet(), this.oldMap);
        }
         if (!isHLContactUpdated ) {
          updateHLGrouponContact(this.newList, this.oldList);
           }
         deactivateHLGrouponContact(this.newList,this.oldMap);
        if(!ACAMSAssetTriggerHandler.isWhitepaperUpdated){
        whitePaperUpdate(this.newMap,this.oldMap);
        }
        if(!ACAMSAssetTriggerHandler.isauthorizedStatusUpdated){
        authorizedStatus(this.newList,this.oldMap);
        }
        if(!ACAMSAssetTriggerHandler.isrecertExpDateUpdated){
        recertExpDate(this.newList,this.oldMap);
        }

    }
      public static void UpsertLMSUser(List<Asset> newAssets) {
    if(isRecursiveChapterCheck == false){
    isRecursiveChapterCheck = true;
        system.debug('AssetHelperRestructure, UpsertLMSUser Method started $$$$$');
        system.debug('debug--UpsertLMSUser$$$$$$$$$$$---');
        try{
            

            Set<Id> contactIds = new Set<Id>();
            Map<Id, User> contactUserMap = new Map<Id, User>();
            List<LMSUtility.LMSUserRequest> lmsuserList = new List<LMSUtility.LMSUserRequest>();

            System.debug('*****AssetHelperRestructure.UpsertLMSUser.newAssets: ' + newAssets);

            if (newAssets != NULL && newAssets.size() > 0){
                for(Asset newA : newAssets){
                    if (newA.AccountId != NULL){
                        isLMSUserCreated = true;
                        contactIds.add(newA.AccountId);
                    }
                }
                System.debug('*****AssetHelperRestructure.UpsertLMSUser.contactIds: ' + contactIds);

                if (contactIds.size() > 0){
                    for(Account c : [SELECT Id, FirstName,personemail,CommunityUser__r.Username,CommunityUser__r.LMS_Role__c, LastName FROM Account WHERE Id IN: contactIds]){
                        LMSUtility.LMSUserRequest lmsuser = new LMSUtility.LMSUserRequest();
                        lmsuser.contactId = c.Id;
                        lmsuser.firstName = c.FirstName;
                        lmsuser.lastName = c.LastName;
                        lmsuser.language = '';
                        lmsuser.enabled = true;
                        lmsuser.username = c.CommunityUser__r.Username;
                       	lmsuser.role = c.CommunityUser__r.LMS_Role__c;
                        lmsuserList.add(lmsuser);
                    }
                }
                System.debug('*****AssetHelperRestructure.UpsertLMSUser.contactIds: ' + contactIds);

                if (contactIds.size() > 0){
                    for(User u : [SELECT Id,ContactId,AccountId, Username, LMS_Role__c, TimeZoneSidKey  FROM User WHERE AccountId IN: contactIds]){
                        contactUserMap.put(u.AccountId, u);
                    }
                    for(LMSUtility.LMSUserRequest lmsU : lmsuserList){
                        if (contactUserMap.containsKey(lmsU.contactId)){
                            User u = contactUserMap.get(lmsU.contactId);
                            lmsU.username = u.Username;
                            lmsU.role = u.LMS_Role__c;
                            lmsU.timezone = ''; //lmsU.timezone = u.TimeZoneSidKey; -- Waiting for Timezone Integration
                        }
                    }
                    System.debug('*****AssetHelperRestructure.UpsertLMSUser.contactUserMap: ' + contactUserMap);
                }
            }
            System.debug('*****AssetHelperRestructure.UpsertLMSUser.lmsuserList: ' + lmsuserList);

            if (lmsuserList.size() > 0)
                CalloutUtility.SendRequest('UserIntegration', true, LMSUtility.BuildJson(lmsuserList));
        }
        catch(Exception ex){
           
        }
        
        system.debug('AssetHelperRestructure, UpsertLMSUser Method started $$$$$');
    }
    }
     public static void AcamsHelperMethod(list<asset> newids,list<asset> oldids){
         system.debug('debug--Acams_helper_metho_RT$$$$$$$$$$$---');
           if(isRecursiveBeforeUpdate == false){
              isRecursiveBeforeUpdate = true ;
        for(asset astn: newids){
            for(asset asto:oldids){
                system.debug('Old values'+asto.status__c);
                system.debug('New values'+astn.status__c);
                
                if(astn.status__c != asto.status__c){
                    if(astn.status__c == 'Inactive' && (astn.Enterprise_Product_HL__c =='ENTLATAM-S' || astn.Enterprise_Product_HL__c =='ENTLATAM-P')){
                        assetIds.add(astn.id);
                    }
                }
            }
        }
        List<BeckerLMS_Enrollment__c> BlmsList = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> UpdateBlmsList = new List<BeckerLMS_Enrollment__c>();
        BlmsList=[select id, name, asset__c from BeckerLMS_Enrollment__c where status__c !='Completed' AND asset__c IN:assetIds ];
        try{ for(BeckerLMS_Enrollment__c b:BlmsList){
            b.status__c = 'Cancelled';
            UpdateBlmsList.add(b);
        }
          if(UpdateBlmsList.size()>0){
        update UpdateBlmsList;
    }
           }
        catch(DmlException e) {
    System.debug('The following exception has occurred: ' + e.getMessage());
   }
           }
    }
    

    /**
     ** @description: added logic for 2. Certification Asset: Populate the LMS access expiration Date upon
     *the payment.
     * @Date: July 2, 2020 - Rui
     * @source: issue/Defect UAT LOG Row 301 "Layout" -
     * https://app.smartsheet.com/sheets/CQ2rPHChHxfRvwPQ4m38fwVVcx4V6xCMmgf2pHw1?view=grid
     */

    /**
    public static void updateLMSExpirationDate(List<Asset> newAssets, Map<Id,Asset> oldMap) {
        if(newAssets != null && newAssets.size() > 0){
            for(Asset a : newAssets){
                if(a.Product_level_1__c == 'Certification' && a.Exam_Pass_Date__c != null && oldMap == null){
                    if(a.CC_Product__c != null){
                        Integer daysToExpire = a.CC_Product__r.Days_to_Expire__c != null ?
                        Integer.valueOf(a.CC_Product__r.Days_to_Expire__c) : 365;
                        a.LMS_Access_Exp_Date__c = a.Exam_Pass_Date__c.addDays(daysToExpire);

                    }
                }

                else if(a.Product_level_1__c == 'Certification' && a.Exam_Pass_Date__c != null && oldMap != null){
                    if(a.CC_Product__c != null && a.Exam_Pass_Date__c != null && oldMap.get(a.Id).Exam_Pass_Date__c != a.Exam_Pass_Date__c){
                        Integer daysToExpire = a.CC_Product__r.Days_to_Expire__c != null ?
                        Integer.valueOf(a.CC_Product__r.Days_to_Expire__c) : 365;
                        a.LMS_Access_Exp_Date__c = a.Exam_Pass_Date__c.addDays(daysToExpire);

                    }
                }
            }
        }
    }
    */
    
    /**
     * @Description: added updated logic for 2. for all assets: Populate the LMS access expiration date upon the payment (asset install date)
     * @Date: July 23, 2020, Rui.
     * @Source: Adtalem Email : Thu 7/23/2020 4:19 PM , subject "LMS enrollment Logic"
     * @ RQ changed on Aug 21,2020. ACAMS Email : Fri 8/21/2020 8:17 AM
     */

    public static void updateLMSExpirationDate(List<Asset> newAssets, Map<Id,Asset> oldMap) {
        if(newAssets != null && newAssets.size() > 0){
            /**
             * @ in before trigger, parent reference objectAPI__r.field__c will be null and not working
             */
            Map<Id,Decimal> daysToExpireMap = new Map<Id,Decimal>();
            Map<Id,String> expirationDateLogicMap = new Map<Id,String>();
            Map<Id,String> lmsCourseMap = new Map<Id,String>();

            Set<String> ccProductIds = new Set<String>();

            for(Asset a : newAssets){
                if(!String.isBlank(a.CC_Product__c)){
                    ccProductIds.add(a.CC_Product__c);
                }
            }

            List<ccrz__E_Product__c> ccProdList = [SELECT Id, LMS_Course__c, Expiration_Date_Logic__c, Days_to_Expire__c FROM ccrz__E_Product__c WHERE Id IN: ccProductIds AND LMS_Course__c != null];

            for(ccrz__E_Product__c pd : ccProdList){
                daysToExpireMap.put(pd.Id,pd.Days_to_Expire__c);
                expirationDateLogicMap.put(pd.Id,pd.Expiration_Date_Logic__c);
                lmsCourseMap.put(pd.Id,pd.LMS_Course__c);
            }

            for(Asset a : newAssets){
                
                if(a.CC_Product__c != null && 
                !String.isBlank(lmsCourseMap.get(a.CC_Product__c)) && daysToExpireMap.get(a.CC_Product__c) != null && expirationDateLogicMap.get(a.CC_Product__c) != null){
                    /**
                     * add LMS expire date equals to null in condition, per requirement changed in Email: Fri 8/21/2020 8:17 AM
                     */
                    if(a.LMS_Access_Exp_Date__c == null && String.valueOf(expirationDateLogicMap.get(a.CC_Product__c)).equals('Event Date') && a.Event_Date__c != null){
                        a.LMS_Access_Exp_Date__c = a.Event_Date__c.addDays(Integer.valueOf(daysToExpireMap.get(a.CC_Product__c)));
                    }
                    else if(a.LMS_Access_Exp_Date__c == null && String.valueOf(expirationDateLogicMap.get(a.CC_Product__c)).equals('Payment') && a.CreatedDate  != null ){
                        a.LMS_Access_Exp_Date__c = Date.newInstance((a.CreatedDate).year(),(a.CreatedDate).month(),(a.CreatedDate).day()).addDays(Integer.valueOf(daysToExpireMap.get(a.CC_Product__c)));
                    }
                }
            }
        }


    }
      public static void updateHLGrouponContact(List<Asset> newAssets,List<Asset> oldAssets) {
         
         Set<String> ccProductIds = new Set<String>();
         Map<Id,String> hlGroupMap = new Map<Id,String>();
         Map<Id,String> hlCommMap = new Map<Id,String>();
         Map<Id,String> hlSecMap = new Map<Id,String>();
         List<Contact> hlCommContactlst = new List<Contact>();
         List<Contact> hlSecContactlst = new List<Contact>();
         List<Contact> hlCommContactupdatelst = new List<Contact>();
         List<Contact> hlSecContactupdatelst = new List<Contact>();
         
         for(Asset a : newAssets){
             if(oldAssets == null){
              if(!String.isBlank(a.CC_Product__c) && a.Paid_Cert__c == true){
                    ccProductIds.add(a.CC_Product__c);
                }
             }
             else{
                 for(Asset aold : oldAssets){
                     if(!String.isBlank(a.CC_Product__c) && a.Paid_Cert__c == true && a.Paid_Cert__c != aold.Paid_Cert__c){
                    ccProductIds.add(a.CC_Product__c);
                }
             } 
         }
         }
         system.debug(ccProductIds);
         if(ccProductIds.size()>0){
         List<ccrz__E_Product__c> ccProdList = [SELECT Id, HigherLogic_Group__c FROM ccrz__E_Product__c WHERE Id IN: ccProductIds AND HigherLogic_Group__c!= null];
     for(ccrz__E_Product__c pd : ccProdList){
             hlGroupMap.put(pd.Id,pd.HigherLogic_Group__c);
             
         }
         system.debug(hlGroupMap);
         for(Asset a : newAssets){
             if(a.ContactId != null){
                 if(hlGroupMap.size()>0 && hlGroupMap.get(a.CC_Product__c) != null ){
               if(String.valueOf(hlGroupMap.get(a.CC_Product__c)).contains('HL Community')){
                   hlCommMap.put(a.ContactId,a.Group_Key__c);
               }
                 }
                  if(hlGroupMap.size()>0 && hlGroupMap.get(a.CC_Product__c) != null){
             if(String.valueOf(hlGroupMap.get(a.CC_Product__c)).contains('HL Security Group')){
                   hlSecMap.put(a.ContactId,a.Group_Key__c);
               }
                  }
             }
         }
         system.debug(hlCommMap);
         system.debug(hlSecMap);
         hlCommContactlst = [select id, HL_Communities__c,Is_Active__c from contact where id in: hlCommMap.keyset() ];
         system.debug(hlCommContactlst);
         for(Contact c : hlCommContactlst){
             If(c.HL_Communities__c == null){
                 c.HL_Communities__c = String.valueOf(hlCommMap.get(c.id));
                 c.Is_Active__c =true;
                 system.debug(c.HL_Communities__c);
                 system.debug(String.valueOf(hlCommMap.get(c.id)));
             }
             else{
                 String Comm;
                 comm = c.HL_Communities__c ;
                 comm= comm + ';' + String.valueOf(hlCommMap.get(c.id));
                 c.HL_Communities__c = comm;
                 c.Is_Active__c =true;
                 system.debug(c.HL_Communities__c );
                 system.debug(String.valueOf(hlCommMap.get(c.id)));
             }
             hlCommContactupdatelst.add(c);
             system.debug(hlCommContactupdatelst);
         }
         try{    
              if(hlCommContactupdatelst.size()>0){
          Update hlCommContactupdatelst; 
              }
         } catch(DmlException e) {
         System.debug('The following exception has occurred: ' + e.getMessage());
      }    
         hlSecContactlst = [select id, HL_Security_Groups__c,Is_Active__c from contact where id in: hlSecMap.keyset() ];
         system.debug(hlSecContactlst);
         for(Contact c : hlSecContactlst){
             If(c.HL_Security_Groups__c == null){
                 c.HL_Security_Groups__c = String.valueOf(hlSecMap.get(c.id));
                 c.Is_Active__c =true;
                 system.debug(c.HL_Security_Groups__c);
                 system.debug(String.valueOf(hlSecMap.get(c.id)));
             }
             else{
                 String Comm;
                 comm = c.HL_Security_Groups__c ;
                 comm= comm + ';' + String.valueOf(hlSecMap.get(c.id));
                 c.HL_Security_Groups__c = comm;
                 c.Is_Active__c =true;
                 system.debug(c.HL_Security_Groups__c );
                 system.debug(String.valueOf(hlSecMap.get(c.id)));
             }
             hlSecContactupdatelst.add(c);
             system.debug(hlSecContactupdatelst);
         }
        try{
             if(hlSecContactupdatelst.size()>0){
          Update hlSecContactupdatelst;  
             }
      }
          catch(DmlException e) {
         System.debug('The following exception has occurred: ' + e.getMessage());
      }  
         
         isHLContactUpdated = true;
         }
     }
     public static void deactivateHLGrouponContact(List<Asset> newAssets,Map<Id, Asset> oldAssets) {
          Map<Id,String> assetIdHlMap = new Map<Id,String>();
          List<contact> cntLst = new List<contact>();
         List<contact> cntUpdateLst = new List<contact>();
         
         for(Asset a: newAssets){
             if(a.Status__c != oldAssets.get(a.id).Status__c && a.Status__c == 'Inactive' && a.HigherLogic_Group__c != null){
                 assetIdHlMap.put(a.ContactId, a.Group_Key__c);
                 
             }
         }
         system.debug('assetIdHlMap -'+assetIdHlMap);
         if(assetIdHlMap.size()>0){
         cntLst = [select id, HL_Communities__c, HL_Security_Groups__c from contact where id in:assetIdHlMap.keyset()];
         }
         system.debug('cntLst -'+cntLst);
         for(contact c : cntLst ){
             if(assetIdHlMap.size()>0 && c.HL_Communities__c != null && assetIdHlMap.get(c.id) != null){
             system.debug('String.valueOf(c.HL_Communities__c).contains(String.valueOf(assetIdHlMap.get(c.id))) -'+String.valueOf(c.HL_Communities__c).contains(String.valueOf(assetIdHlMap.get(c.id))));
             if(String.valueOf(c.HL_Communities__c).contains(String.valueOf(assetIdHlMap.get(c.id)))){
                 String Comm;
                 comm = c.HL_Communities__c ;
                 comm= comm.remove(String.valueOf(assetIdHlMap.get(c.id)));
                 c.HL_Communities__c = comm;
             }
             }
             if(assetIdHlMap.size()>0 && c.HL_Security_Groups__c != null && assetIdHlMap.get(c.id) != null){ 
             system.debug('String.valueOf(c.HL_Security_Groups__c).contains(String.valueOf(assetIdHlMap.get(c.id))) -'+String.valueOf(c.HL_Security_Groups__c).contains(String.valueOf(assetIdHlMap.get(c.id))));
             if(String.valueOf(c.HL_Security_Groups__c).contains(String.valueOf(assetIdHlMap.get(c.id)))){
                 String secGrp;
                 secGrp = c.HL_Security_Groups__c ;
                 secGrp= secGrp.remove(String.valueOf(assetIdHlMap.get(c.id)));
                 c.HL_Security_Groups__c = secGrp;
             }
             }
          cntUpdateLst.add(c);
             
         }
         system.debug('cntUpdateLst -'+cntUpdateLst);
           try{
             if(cntUpdateLst.size()>0){
          Update cntUpdateLst;  
             }
      }
          catch(DmlException e) {
         System.debug('The following exception has occurred: ' + e.getMessage());
      }  
             
             
     }
     public static void whitePaperUpdate( Map<Id,Asset> newMap, Map<Id,Asset> oldMap) {
        ACAMSAssetTriggerHandler.isWhitepaperUpdated =true;
         List<Asset> assetLst = new List<Asset>();
         List<Asset> assetUpdate = new List<Asset>();
         assetLst = [select id, White_Paper_Assignment_Approved__c, White_Paper_Approved_Date__c from Asset where id IN:newMap.keyset() ];
         for(Asset a : assetLst){
         
            if(a.White_Paper_Assignment_Approved__c != oldMap.get(a.id).White_Paper_Assignment_Approved__c && a.White_Paper_Assignment_Approved__c  && a.White_Paper_Approved_Date__c != null){
                a.CurrentExpirationDate__c = Date.newInstance(a.White_Paper_Approved_Date__c.addYears(3).year(), 12, 15);
                assetUpdate.add(a);
            }
     }
           try{
             if(assetUpdate.size()>0){
                 
          Update assetUpdate;  
             }
               }
             catch(DmlException e) {
         System.debug('The following exception has occurred: ' + e.getMessage());
      }  
     }
    public static void authorizedStatus(List<Asset> newAssets, Map<Id,Asset> oldMap) {
        ACAMSAssetTriggerHandler.isauthorizedStatusUpdated = true;
          Set<Id> contactIds = new Set<Id>();
        Set<Id> assetIds = new Set<Id>();
        List<Asset> assetlst = new List<Asset>();
        List<Asset> assetUpdate = new List<Asset>();
        for (Asset asset : newAssets) {
            if (asset.Assignee__c != null && asset.Payment_Status__c != oldMap.get(asset.id).Payment_Status__c && asset.Payment_Status__c == 'Authorized') {
                contactIds.add(asset.Assignee__c);
                assetIds.add(asset.id);
            }
        }
        assetlst = [SELECT
                        AccountId,
                        Assignee__c,
                        Assignee__r.CAMS_Audit_Expiration_Date__c,
                        Assignee__r.CAMS_Expiration_Date__c,
                        Assignee__r.CAMS_FCI_Expiration_Date__c,
                        Assignee__r.CAMSRM_Expiration_Date__c,
                        Assignee__r.CGSS_Expiration_Date__c,
                        Assignee__r.CKYCA_Expiration_Date__c,
                        CC_Order_Item__c,
                        CC_Product__c,
                        CC_Product__r.Days_to_Expire__c,
                        CC_Product__r.Event_Date__c,
                        CC_Product__r.Expiration_Date_Logic__c,
                        CC_Product__r.Level_1__c,
                        CC_Product__r.Level_2__c,
                        CC_Product__r.Level_3__c,
                        CreatedDate,
                        CurrentExpirationDate__c,
                        Effective_Date__c,
                        Exam_Pass_Date__c,
                        Id,
                        LMS_Access_Exp_Date__c,
                        Name,
                        Paid_Cert__c,
            			Payment_Status__c,
                        RecordTypeId,
                        Status__c,
                        Subscription_Term__c
                FROM
                        Asset where id in: assetIds ];
            Map<Id, Contact> idToContactMap = new Map<Id, Contact>(ACAMSAccountDAO.getContactsByContactIds(contactIds));
        for(Asset asset : assetlst){
            if(asset.Payment_Status__c != oldMap.get(asset.id).Payment_Status__c && asset.Payment_Status__c == 'Authorized'){
            asset.Status__c = 'Active';
            Integer term = asset.Subscription_Term__c != null ? Integer.valueOf(asset.Subscription_Term__c) : 12;
            if (asset.Name == ACAMSUtil.MEMBERSHIP) {
                if (idToContactMap.get(asset.Assignee__c) != null &&
                        idToContactMap.get(asset.Assignee__c).Member_Expire_Date__c != NULL &&
                        idToContactMap.get(asset.Assignee__c).Member_Expire_Date__c >= Date.today()) {
                                 
                    asset.Effective_Date__c = idToContactMap.get(asset.Assignee__c).Member_Expire_Date__c;
                    asset.CurrentExpirationDate__c =
                            idToContactMap.get(asset.Assignee__c).Member_Expire_Date__c.addMonths(term);
                            
                } else {
                    asset.Effective_Date__c = Date.today();
                    asset.CurrentExpirationDate__c = Date.today().addMonths(term);
                }
            } else if (asset.Name == ACAMSUtil.CHAPTER + ' ' + ACAMSUtil.MEMBERSHIP) {
                if (idToContactMap.get(asset.Assignee__c) != NULL &&
                        idToContactMap.get(asset.Assignee__c).Chapter_Member_Expire_Date__c != NULL &&
                        idToContactMap.get(asset.Assignee__c).Chapter_Member_Expire_Date__c >= Date.today()) {
                    asset.Effective_Date__c = idToContactMap.get(asset.Assignee__c).Chapter_Member_Expire_Date__c;
                    asset.CurrentExpirationDate__c =
                            idToContactMap.get(asset.Assignee__c).Chapter_Member_Expire_Date__c.addMonths(term);
                } else {
                    asset.Effective_Date__c = Date.today();
                    asset.CurrentExpirationDate__c = Date.today().addMonths(term);
                }
            } else if (asset.Name == ACAMSUtil.MONEYLAUNDERINGDOTCOM) {
                if (idToContactMap.get(asset.Assignee__c) != NULL &&
                        idToContactMap.get(asset.Assignee__c).MLDC_Expiration_Date__c != NULL &&
                        idToContactMap.get(asset.Assignee__c).MLDC_Expiration_Date__c >= Date.today()) {
                    asset.Effective_Date__c = idToContactMap.get(asset.Assignee__c).MLDC_Expiration_Date__c;
                    asset.CurrentExpirationDate__c =
                            idToContactMap.get(asset.Assignee__c).MLDC_Expiration_Date__c.addMonths(term);
                } else {
                    asset.Effective_Date__c = Date.today();
                    asset.CurrentExpirationDate__c = Date.today().addMonths(term);
                }
            } else if (asset.Name == ACAMSUtil.ACAMS_TODAY + ' ' + ACAMSUtil.PRINTED_SUBSCRIPTION) {
                if (idToContactMap.get(asset.Assignee__c) != NULL &&
                        idToContactMap.get(asset.Assignee__c).ACAMS_Today_Expiration_Date__c != NULL &&
                        idToContactMap.get(asset.Assignee__c).ACAMS_Today_Expiration_Date__c >= Date.today()) {
                    asset.Effective_Date__c = idToContactMap.get(asset.Assignee__c).ACAMS_Today_Expiration_Date__c;
                    asset.CurrentExpirationDate__c =
                            idToContactMap.get(asset.Assignee__c).ACAMS_Today_Expiration_Date__c.addMonths(term);
                } else {
                    asset.Effective_Date__c = Date.today();
                    asset.CurrentExpirationDate__c = Date.today().addMonths(term);
                }
            } else {
                if (asset.CC_Product__r.Level_1__c != ACAMSUtil.CERTIFICATION) {
                    asset.Effective_Date__c = Date.today();
                    Integer daysToExpire = asset.CC_Product__r.Days_to_Expire__c != null ?
                            Integer.valueOf(asset.CC_Product__r.Days_to_Expire__c) : 5;
                    if (asset.CC_Product__r.Expiration_Date_Logic__c != null &&
                            asset.CC_Product__r.Expiration_Date_Logic__c == ACAMSUtil.PAYMENT) {
                        asset.CurrentExpirationDate__c = Date.today().addDays(daysToExpire);
                    } else {
                        Date eventDate = asset.CC_Product__r.Event_Date__c != null &&
                                asset.CC_Product__r.Event_Date__c >= Date.today() ? asset.CC_Product__r.Event_Date__c :
                                Date.today();
                        asset.CurrentExpirationDate__c = eventDate.addDays(daysToExpire);
                    }
                }
                
                if(asset.CC_Product__r.Level_1__c == ACAMSUtil.CERTIFICATION && asset.CC_Product__r.Level_3__c == 'Retake/Extension' ){
                    asset.Effective_Date__c = Date.today();
                }

            }
          
          assetUpdate.add(asset);
        }
         
        
    }
            try{
             if(assetUpdate.size()>0){
                 
          Update assetUpdate;  
             }
               }
             catch(DmlException e) {
         System.debug('The following exception has occurred: ' + e.getMessage());
      } 
    }
    public static void recertExpDate(List<Asset> newAssets, Map<Id,Asset> oldMap) {
        ACAMSAssetTriggerHandler.isrecertExpDateUpdated =true;
                    /**
                     * @description:Recertifications: expiration dates are automatically populated to upon
                     * purchase/creation to December 15, 3 years after the latest certification/recertification
                     * expiration date.
                     * @Date: July 6, 2020 - Rui
                     * @Source: https://app.smartsheet.com/sheets/PmRwr2pvMQC65M3XQQGhq6HMrjr3hcVHqHC5rFm1?view=grid&filterId=792913769719684   item 14
             
*/
		        List<Asset> assetlst = new List<Asset>();
				        Set<Id> assetIds = new Set<Id>();
					        List<Asset> assetUpdate = new List<Asset>();

        for(Asset asset : newAssets){
        if((asset.Payment_Status__c != oldMap.get(asset.id).Payment_Status__c && asset.Payment_Status__c == 'Completed' && asset.Certification_Approved_Application__c) || (asset.Certification_Approved_Application__c != oldMap.get(asset.id).Certification_Approved_Application__c && asset.Certification_Approved_Application__c && asset.Payment_Status__c == 'Completed' )){
         assetIds.add(asset.id);
        }
        }
        assetlst = [SELECT
                        AccountId,
                        Assignee__c,
                        Assignee__r.CAMS_Audit_Expiration_Date__c,
                        Assignee__r.CAMS_Expiration_Date__c,
                        Assignee__r.CAMS_FCI_Expiration_Date__c,
                        Assignee__r.CAMSRM_Expiration_Date__c,
                        Assignee__r.CGSS_Expiration_Date__c,
                        Assignee__r.CKYCA_Expiration_Date__c,
                        CC_Order_Item__c,
                        CC_Product__c,
                        CC_Product__r.Days_to_Expire__c,
                        CC_Product__r.Event_Date__c,
                        CC_Product__r.Expiration_Date_Logic__c,
                        CC_Product__r.Level_1__c,
                        CC_Product__r.Level_2__c,
                        CC_Product__r.Level_3__c,
                        CreatedDate,
                        CurrentExpirationDate__c,
                        Effective_Date__c,
                        Exam_Pass_Date__c,
                        Id,
                        LMS_Access_Exp_Date__c,
                        Name,
                        Paid_Cert__c,
            			Payment_Status__c,
                        RecordTypeId,
                        Status__c,
                        Subscription_Term__c
                FROM
                        Asset where id in: assetIds ];
            for(Asset asset : assetlst){
            if (asset.CC_Product__c != null && asset.CC_Product__r.Level_3__c == 'Recertification') {
                        if (asset.CreatedDate != null) {
                            if (asset.CC_Product__c != null && asset.CC_Product__r.Level_2__c != null &&
                                    String.valueOf(asset.CC_Product__r.Level_2__c).contains('CKYCA')) {
                                if (asset.Assignee__c != null && asset.Assignee__r.CKYCA_Expiration_Date__c != null) {
                                     asset.Effective_Date__c = Date.today();
                                    asset.CurrentExpirationDate__c =
                                            asset.Assignee__r.CKYCA_Expiration_Date__c.addYears(1);
                                }
                            } else if (asset.CC_Product__c != null && asset.CC_Product__r.Level_2__c != null &&
                                    String.valueOf(asset.CC_Product__r.Level_2__c).contains('CAMS')) {
                                if (asset.Assignee__c != null && asset.Assignee__r.CAMS_Expiration_Date__c != null) {
                                    asset.Effective_Date__c = Date.today();
                                    asset.CurrentExpirationDate__c = Date.newInstance(
                                            asset.Assignee__r.CAMS_Expiration_Date__c.year() + 3, 12, 15
                                    );
                                }

                                if (asset.Assignee__c != null && asset.Assignee__r.CAMSRM_Expiration_Date__c != null) {
                                     asset.Effective_Date__c = Date.today();
                                    asset.CurrentExpirationDate__c = Date.newInstance(
                                            asset.Assignee__r.CAMSRM_Expiration_Date__c.year() + 3, 12, 15
                                    );
                                }

                                if (asset.Assignee__c != null &&
                                        asset.Assignee__r.CAMS_Audit_Expiration_Date__c != null) {
                                     asset.Effective_Date__c = Date.today();
                                            asset.CurrentExpirationDate__c = Date.newInstance(
                                            asset.Assignee__r.CAMS_Audit_Expiration_Date__c.year() + 3, 12, 15
                                    );
                                }

                                if (asset.Assignee__c != null &&
                                        asset.Assignee__r.CAMS_FCI_Expiration_Date__c != null) {
                                     asset.Effective_Date__c = Date.today();
                                            asset.CurrentExpirationDate__c = Date.newInstance(
                                            asset.Assignee__r.CAMS_FCI_Expiration_Date__c.year() + 3, 12, 15
                                    );
                                }

                            } else if (asset.CC_Product__c != null && asset.CC_Product__r.Level_2__c != null &&
                                    String.valueOf(asset.CC_Product__r.Level_2__c).contains('CGSS')) {
                                if (asset.Assignee__c != null && asset.Assignee__r.CGSS_Expiration_Date__c != null) {
                                    asset.Effective_Date__c = Date.today();
                                    asset.CurrentExpirationDate__c = Date.newInstance(
                                            asset.Assignee__r.CGSS_Expiration_Date__c.year() + 3, 12, 15
                                    );
                                }
                            }
                        }
                    }
             assetUpdate.add(asset);
            }
            try{
                
             if(assetUpdate.size()>0){
          Update assetUpdate;  
             }
               }
             catch(DmlException e) {
         System.debug('The following exception has occurred: ' + e.getMessage());
      } 
    }
}