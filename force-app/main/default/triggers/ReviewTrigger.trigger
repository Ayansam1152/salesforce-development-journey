trigger ReviewTrigger on Review__c (after insert, after update) {
    new MetadataTriggerHandler().run();
}