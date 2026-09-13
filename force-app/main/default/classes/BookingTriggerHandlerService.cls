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
    
    public static void handleOverlapBooking(List<Booking__c> bookings){
        Set<Id> carIds = new Set<Id>();
        Set<Id> existingBookingIds = new Set<Id>();
        
        String closedStatus = Constants.BOOKING_CLOSED_STATUS;
        String cancelledStatus = Constants.BOOKING_CANCELLED_STATUS;
        
        for(Booking__c booking : bookings)
        {
            carIds.add(booking.Car__c);
            
            if(booking.Id != null)
            {
                existingBookingIds.add(booking.Id);
            }
        }
        
        // List<Booking__c> re = [Select Id, Car__c, Start_Date_Time__c, End_Date_Time__c, Status__c from Booking__c where Status__c != :Constants.BOOKING_CLOSED_STATUS and Status__c != :Constants.BOOKING_CANCELLED_STATUS and Car__c in : carIds and Id Not in :existingBookingIds];
        
        String query = 'Select Id, Car__c, Start_Date_Time__c, End_Date_Time__c, Status__c from Booking__c where Status__c != :closedStatus and Status__c != :cancelledStatus and Car__c in : carIds';
        
        if(existingBookingIds.size() > 0)
        {
            query = query+' and Id Not in :existingBookingIds';
        }
        
        List<Booking__c> existingActiveBooking = Database.query(query);
        Map<Id, List<Booking__c>> mapCarWithExistingBookings = new Map<Id, List<Booking__c>>();
        
        for(Booking__c existingBooking : existingActiveBooking)
        {
            if(!mapCarWithExistingBookings.containsKey(existingBooking.Car__c))
            {
                mapCarWithExistingBookings.put(existingBooking.Car__c, new List<Booking__c>());
            }
            
            mapCarWithExistingBookings.get(existingBooking.Car__c).add(existingBooking);
        }
        
        for(Booking__c booking : bookings)
        {
            if(isOverlap(booking, mapCarWithExistingBookings?.get(booking.Car__c)))
            {
                // show the error to the user
                break;
            }
        }
    }
    
    private static Boolean isOverlap(Booking__c newBooking, List<Booking__c> existingBookings){
        if(existingBookings == null || existingBookings.isEmpty()) return false;
        
        Datetime startDate = newBooking.Start_Date_Time__c;
        Datetime endDate = newBooking.End_Date_Time__c;
        
        for(Booking__c existingBooking : existingBookings)
        {
            if(startDate <= existingBooking.End_Date_Time__c && endDate >= existingBooking.Start_Date_Time__c)
            {
                newBooking.addError(System.Label.Overlap_Booking_Error_Message+ ' from '+ existingBooking.Start_Date_Time__c.format()+' to '+ existingBooking.End_Date_Time__c.format());
                
                return true;
            }
        }
        
        return false;
    }
}