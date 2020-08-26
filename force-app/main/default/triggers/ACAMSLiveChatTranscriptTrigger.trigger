trigger ACAMSLiveChatTranscriptTrigger on LiveChatTranscript (After insert) {
    if (UserInfo.getName() != 'Data Migration') {
        (new ACAMSLiveChatTranscriptTriggerHandler()).run();
    }
}