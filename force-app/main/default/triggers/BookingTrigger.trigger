trigger BookingTrigger on Booking__c (after update) {
    new MetadataTriggerHandler().run();
}