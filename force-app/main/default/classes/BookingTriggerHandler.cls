public with sharing class BookingTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate(){
        BookingTriggerHandlerService.handleClosedBooking((List<Booking__c>)Trigger.new, (Map<Id, Booking__c>)Trigger.oldMap);
    }
    
    public override void beforeInsert(){
        BookingTriggerHandlerService.handleOverlapBooking((List<Booking__c>)Trigger.new);
    }
    
    public override void beforeUpdate(){
        List<Booking__c> bookings =(List<Booking__c>) Trigger.new;
        Map<Id, Booking__c> oldBookingMap = (Map<Id, Booking__c>)Trigger.oldMap;
        
        List<Booking__c> bookingsNeedToUpdate = new List<Booking__c>();
        
        for(Booking__c newBooking : bookings)
        {
            Booking__c oldBooking = oldBookingMap.get(newBooking.Id);
            
            if(
                newBooking.Status__c != Constants.BOOKING_CLOSED_STATUS && newBooking.Status__c != Constants.BOOKING_CANCELLED_STATUS &&
                (newBooking.Start_Date_Time__c != oldBooking.Start_Date_Time__c || newBooking.End_Date_Time__c != oldBooking.End_Date_Time__c))
            {
                bookingsNeedToUpdate.add(newBooking);
            }
        }
        
        if(bookingsNeedToUpdate.size() > 0)
        {
            BookingTriggerHandlerService.handleOverlapBooking((List<Booking__c>) Trigger.new);
        }
    }
}