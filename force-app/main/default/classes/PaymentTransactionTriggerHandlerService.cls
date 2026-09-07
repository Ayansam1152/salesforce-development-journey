public with sharing class PaymentTransactionTriggerHandlerService {
    
    public static void handlePaymentTransaction(List<Payment_Transaction__c> paymentTractions)
    {
       // System.debug('HANDLE PAYMENT TRANSACTION STARTED');
        Set<Id> bookingIds = new Set<Id>();
        
        for(Payment_Transaction__c paymentTransaction : paymentTractions)
        {
            bookingIds.add(paymentTransaction.Booking__c);
        }

        //System.debug('Booking Ids: ' + bookingIds);
        
        Set<String> paymentTypes = new Set<String>();
        
        paymentTypes.add(Constants.INITIAL_PAYMENT);
        paymentTypes.add(Constants.SECURITY_DEPOSIT);
        paymentTypes.add(Constants.PARTIAL_PAYMENT);
        
        List<Booking__c> existingBookings = [
            Select Id, 
                status__c,
                payment_status__c,
                Total_Paid_Amount__c, 
                Total_Security_Deposit_Paid__c, 
                Final_Booking_Price__c, 
                Security_Deposit__c, 
    
                (Select Id, 
                        status__c, 
                        type__c ,
                        Amount__c
                        from Payment_Transactions__r 
                where Status__c= 'Success' and Type__c in : paymentTypes)

            from Booking__c 
            Where Id in : bookingIds
        ];

        System.debug('Existing Bookings: ' + existingBookings);
        
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        
        for(Booking__c booking : existingBookings)
        {
            decimal initialPayment = 0;
            decimal partialPayment = 0;
            decimal securityPayment = 0;
            
            for(Payment_Transaction__c paymentTransaction : booking.Payment_Transactions__r)
            {
                if(paymentTransaction.Type__c == Constants.INITIAL_PAYMENT)
                {
                    initialPayment += paymentTransaction.Amount__c;
                }
                else if(paymentTransaction.Type__c == Constants.PARTIAL_PAYMENT)
                {
                    partialPayment += paymentTransaction.Amount__c;
                }
                else if(paymentTransaction.Type__c == Constants.SECURITY_DEPOSIT)
                {
                    securityPayment += paymentTransaction.Amount__c;
                }
            }
            
            System.debug('Initial Payment: ' + initialPayment);
            System.debug('Partial Payment: ' + partialPayment);
            System.debug('Security Payment: ' + securityPayment);

            /*
            // update payment status based on the total payments made
            if(initialPayment == 0 && partialPayment == 0 && securityPayment == 0)
            {
                booking.payment_status__c = Constants.BOOKING_PENDING;
            }
            else if(initialPayment+partialPayment >= booking.Final_Booking_Price__c && securityPayment >= booking.Security_Deposit__c)
            {
                booking.payment_status__c = Constants.BOOKING_PAID;
            }
            else
            {
                booking.payment_status__c = Constants.BOOKING_PARTIAL_PAID;
            }
            
            //System.debug('Booking Payment Status: ' + booking.payment_status__c);
            //update booking status based on the payment status
            if(booking.Status__c == Constants.BOOKING_PENDING && (initialPayment > 0 || partialPayment > 0 || securityPayment > 0))
            {
                booking.status__c = Constants.BOOKING_CONFIRMED_STATUS;
            }
            
            System.debug('Booking Status: ' + booking.status__c);
            */

            booking.payment_status__c = getPaymentStatus(initialPayment, partialPayment, securityPayment, booking);
            booking.status__c = getBookingStatus(booking.Status__c, initialPayment, partialPayment, securityPayment);

            bookingsToUpdate.add(booking);
        }
        
        if(bookingsToUpdate.size() > 0)
        {
            try {
                
                update bookingsToUpdate;

            } catch (Exception e) {
                System.debug('Error occurred while updating the payment status and booking status' + e.getMessage());
                
                Log logger = Log.get();
                
                logger.publish('Error occurred while updating the payment status and booking status' + e.getMessage());
                
            }
        }
    }

    private static String getPaymentStatus(decimal initialPayment, decimal partialPayment, decimal securityPayment, Booking__c booking) {
        
        if(initialPayment == 0 && partialPayment == 0 && securityPayment == 0)
        {
            return Constants.BOOKING_PENDING;
        }

        if(initialPayment+partialPayment >= booking.Final_Booking_Price__c && securityPayment >= booking.Security_Deposit__c)
        {
            return Constants.BOOKING_PAID;
        }
        else
        {
            return Constants.BOOKING_PARTIAL_PAID;
        }
    }

    private static String getBookingStatus(String currentStatus, decimal initialPayment, decimal partialPayment, decimal securityPayment) {
        
        if(currentStatus == Constants.BOOKING_PENDING && (initialPayment > 0 || partialPayment > 0 || securityPayment > 0))
        {
            return Constants.BOOKING_CONFIRMED_STATUS;
        }
        
        return currentStatus;
    }
}