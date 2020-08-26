trigger ACAMSAssetTrigger on Asset (after insert, after update, before insert, before update) {
    if (UserInfo.getName() != 'Data Migration') {
        (new ACAMSAssetTriggerHandler()).run();
    }
}