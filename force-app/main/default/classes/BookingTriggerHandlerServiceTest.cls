/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class BookingTriggerHandlerServiceTest {
    
    @TestSetup
    static void makeData(){
        List<Contact> contacts = TestDataFactory.createContacts(5);
        List<Car__c> cars = TestDataFactory.createCars(5);
        List<Booking__c> bookings = TestDataFactory.createBookings(5, contacts, cars);
    }
    
    @isTest
    public static void testTotalCarRevenueOfAssociatedClosedBooking()
    {
        Booking__c booking = [Select Id, Car__c, status__c, Final_Booking_Price__c, Security_Deposit__c, Total_Paid_Amount__c from Booking__c LIMIT 1];
        
        List<Payment_Transaction__c> paymentTransactions = new List<Payment_Transaction__c>();
        
        Payment_Transaction__c initialPayment = new Payment_Transaction__c();
        
        initialPayment.Amount__c = booking.Final_Booking_Price__c;
        initialPayment.Booking__c = booking.Id;
        initialPayment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        initialPayment.Transaction_Date__c = Datetime.now();
        initialPayment.Type__c = Constants.INITIAL_PAYMENT;
        
        Payment_Transaction__c securityPayment = new Payment_Transaction__c();
        
        securityPayment.Amount__c = booking.Security_Deposit__c;
        securityPayment.Booking__c = booking.Id;
        securityPayment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        securityPayment.Transaction_Date__c = Datetime.now();
        securityPayment.Type__c = Constants.SECURITY_DEPOSIT;
        
        paymentTransactions.add(initialPayment);
        paymentTransactions.add(securityPayment);
        
        insert paymentTransactions;
        
        Test.startTest();
        booking.Status__c = Constants.BOOKING_CLOSED_STATUS;
        update booking;
        Test.stopTest();
        
        Car__c updatedCar = [Select Id,Total_Bookings_Value__c from Car__c WHERE Id = :booking.Car__c];
        Booking__c updatedBooking = [Select Id, Total_Paid_Amount__c from Booking__c WHERE Id = :booking.Id];
        
        System.assertEquals(updatedBooking.Total_Paid_Amount__c, updatedCar.Total_Bookings_Value__c, 'Car value does not meet the expected value');
        
    }
}