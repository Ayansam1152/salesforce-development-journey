public with sharing class BookingTriggerHandlerService {
    
    public static void handleClosedBooking(List<Booking__c> bookings, Map<Id, Booking__c> oldBookingMap){
        List<Id> cardIds = new List<Id>();
        
        for(Booking__c booking : bookings)
        {
            Booking__c oldBooking = oldBookingMap.get(booking.Id);
            
            if(oldBooking.Status__c != Constants.BOOKING_CLOSED_STATUS && booking.Status__c == Constants.BOOKING_CLOSED_STATUS){
                cardIds.add(booking.Car__c);
            }
        }
        
        if(cardIds.isEmpty()){
            return;
        }
        
        System.enqueueJob(new QueueableTotalCarValue(cardIds));
    }
}