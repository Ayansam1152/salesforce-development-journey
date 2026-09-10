public with sharing class BookingTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate(){
        BookingTriggerHandlerService.handleClosedBooking((List<Booking__c>)Trigger.new, (Map<Id, Booking__c>)Trigger.oldMap);
    }
}