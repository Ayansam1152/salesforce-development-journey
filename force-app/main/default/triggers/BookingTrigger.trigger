trigger BookingTrigger on Booking__c (after update, before insert, before update) {
    new MetadataTriggerHandler().run();
}