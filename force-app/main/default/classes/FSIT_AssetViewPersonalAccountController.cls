/**
 * @Decription create Asset view page based on "Asset Grouping" values
 * @Source: https://app.smartsheet.com/sheets/7jJVh96vC5pQQRRm9VvGWW7rf4454f9jcC7V2fp1?view=grid row 30
 * @Date: July 8, 2020 Rui
 */

public class FSIT_AssetViewPersonalAccountController {
    public List<Asset> pageAssetList {get ;set;}
    public List<Asset> displayAssetList {get; set;}

    public String assetGroupingValue {get; set{assetGroupingValue = value;}}
    public String searchText {get; set;}


    //setup assetGrouprecords,listofasset map
    public Map<String, List<Asset>> assetMap {get; set;}
    public List<ACAMSAssetSetting__mdt> assetSetting {get; set;}
    public Set<String> keyValues {get; set;}
    public Map<String, Integer> groupNameSizeMap {get; set;}
    public Id sobjectId {get;set;}


    public FSIT_AssetViewPersonalAccountController(ApexPages.StandardController stdController) {
        
        sobjectId = stdController.getId();
        System.debug('sssssssssobjectId---->'+sobjectId);
    }

    public FSIT_AssetViewPersonalAccountController(){
        if(String.isBlank(sobjectId)){
            if(!String.isBlank(ApexPages.currentPage().getParameters().get('recordId'))){
                sobjectId = ApexPages.currentPage().getParameters().get('recordId');
            }
        }

        if(String.isBlank(assetGroupingValue)){
            assetGroupingValue = ApexPages.currentPage().getParameters().get('pdId');
        }
    }

    public void dataInit(){
        //init
        assetMap = new Map<String, List<Asset>>();
        groupNameSizeMap = new Map<String, Integer> ();
        displayAssetList = new List<Asset>();

        //init
        if(sobjectId != null){
            pageAssetList=[SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.AccountId,Assignee__r.Name,Status__c,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c FROM Asset
            WHERE Assignee__r.AccountId =:sobjectId AND CancelDate__c = null AND CC_Product__c != NULL AND (Product_Level_1__c != NULL OR Product_Level_2__c != NULL) AND Status__c = 'Active' ORDER BY CurrentExpirationDate__c];
        }
        else{
            pageAssetList=[SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.Name,Status__c,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c FROM Asset
            WHERE CancelDate__c = null AND CC_Product__c != NULL AND (Product_Level_1__c != NULL OR Product_Level_2__c != NULL) AND Status__c = 'Active' ORDER BY CurrentExpirationDate__c LIMIT 1000];
        }
        assetSetting = [SELECT Id, Asset_Grouping__c FROM ACAMSAssetSetting__mdt LIMIT 1];
        List<String> assetGroupingValues = String.valueOf(assetSetting[0].Asset_Grouping__c).split(';');
        List<AssetWrapper> allAssetWrapper = assetTypeGenerator(pageAssetList);
        
        // put asset id, number to the map
        if(pageAssetList != null && assetSetting != null){
            for(String s : assetGroupingValues){
                assetMap.put(s,  new List<Asset>());
            }

            /*
            for(Asset a : pageAssetList){
                if(assetGroupingValues.contains(a.Product_Level_2__c)){
                    if(assetMap.keySet().contains(a.Product_Level_2__c)){
                        assetMap.get(a.Product_Level_2__c).add(a);
                    }
                }
            }
            */

            for(AssetWrapper aw : allAssetWrapper){
                if(assetGroupingValues.contains(aw.assetType)){
                    if(assetMap.keySet().contains(aw.assetType)){
                        assetMap.get(aw.assetType).add(aw.assetObj);
                    }
                }
            }

            for(String s : assetMap.keySet()){
                groupNameSizeMap.put(s, assetMap.get(s).size());
            }
            keyValues = groupNameSizeMap.keySet();
        }

        displayAssetList = assetMap.get(assetGroupingValue);
        
    }

    public void displayAssetsByGroupName(){
        displayAssetList = assetMap.get(assetGroupingValue);
    }

    public PageReference runSearch(){
        //ApexPages.currentPage() != null && ApexPages.currentPage().getParameters() != null && ApexPages.currentPage().getParameters().get('id')
        if(sobjectId != null){
            displayAssetList = [SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.Name,Assignee__r.AccountId,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c,Status__c FROM Asset
            WHERE Assignee__r.AccountId=:sobjectId AND CancelDate__c = null AND CC_Product__c != NULL AND (Product_Level_1__c != NULL OR Product_Level_2__c != NULL) AND  Status__c = 'Active' AND Name LIKE : '%'+searchText+'%' ORDER BY CurrentExpirationDate__c];
        }

        else{
            displayAssetList = [SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.Name,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c,Status__c FROM Asset
            WHERE CancelDate__c = null AND CC_Product__c != NULL AND (Product_Level_1__c != NULL OR Product_Level_2__c != NULL) AND  Status__c = 'Active' AND Name LIKE : '%'+searchText+'%' ORDER BY CurrentExpirationDate__c LIMIT 1000];
        }
        return null;
    }

    /**
     * @Description AssetTypeGenerator
     */

     public List<AssetWrapper> assetTypeGenerator(List<Asset> assetList){
         List<AssetWrapper> assetWrapperList = new List<AssetWrapper>();
        if(assetList != null){
            for(Asset a : assetList){
                if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Membership')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Membership';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Chapter') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Membership')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Chapter-Membership';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Certification') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('CAMS')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'CAMS';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Certification') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('CGSS')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'CGSS';
                    
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Certification') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('CKYCA')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'CKYCA';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Certification') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Advanced CAMS - Audit') && a.CC_Product__c != null){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'CAMS-Audit';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Certification') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Regime Exams')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Regime-Exams';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Conferences')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Conference';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Training') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Certificates')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Certificate';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Training') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Seminars')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Seminar';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Chapter') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Event')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Chapter-Event';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Training') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Event')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Webinars';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Risk Assessment')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Risk-Assessment';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null && String.valueOf(a.Product_Level_1__c).equals('Publications') && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Moneylaundering.com')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'MLDC';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null != null && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Advertising')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Advertising';
                    assetWrapperList.add(memberAsset);
                }
                else if(a.Product_Level_1__c != null != null && a.Product_Level_2__c != null && String.valueOf(a.Product_Level_2__c).equals('Other')){
                    AssetWrapper memberAsset = new AssetWrapper(a);
                    memberAsset.assetType = 'Other';
                    assetWrapperList.add(memberAsset);
                }
            }
        }

        return assetWrapperList;
     }

    /**
     * @Description assetWrapper
     */
    public class AssetWrapper{
        public String assetType {get;set;}
        public Asset assetObj {get;set;}

        public AssetWrapper(Asset assetObj){
            this.assetObj = assetObj;
        }
    }
}