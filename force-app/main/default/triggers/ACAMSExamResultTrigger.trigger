trigger ACAMSExamResultTrigger on Exam_Results__c (before insert, after insert, before update, after update) {
    if (UserInfo.getName() != 'Data Migration') {
        (new ACAMSExamResultTriggerHandler()).run();
    }
}