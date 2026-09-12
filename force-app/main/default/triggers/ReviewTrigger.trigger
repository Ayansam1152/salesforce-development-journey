trigger ReviewTrigger on Review__c (after insert, after update, after delete) {
    new MetadataTriggerHandler().run();
}