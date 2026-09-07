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
private class PaymentTransactionTriggerHandlerTest {
    
    // Create Test Data
    @testSetup
    static void makeData() {
        List<Contact> contacts = TestDataFactory.createContacts(5);
        List<Car__c> cars = TestDataFactory.createCars(5);
        List<Booking__c> bookings = TestDataFactory.createBookings(5, contacts, cars);
    }
    
    @isTest
    static void testBookingAndPaymentStatus()
    {
        Booking__c bookingRec = [Select id, status__c from Booking__c LIMIT 1];
        
        // Create Payment Transaction
        Payment_Transaction__c payment = new Payment_Transaction__c();
        
        payment.Booking__c = bookingRec.Id;
        payment.Type__c = Constants.INITIAL_PAYMENT;
        payment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        payment.Amount__c = 90;
        payment.Type__c = Constants.INITIAL_PAYMENT;
        payment.Transaction_Date__c = Datetime.now();
        
        insert payment;

        String expectedPaymentStatus = Constants.BOOKING_PARTIAL_PAID;
        String expectedBookingStatus = Constants.BOOKING_CONFIRMED_STATUS;

        Booking__c updatedBookingRec = [Select id, status__c, Payment_Status__c from Booking__c WHERE id =: payment.Booking__c];

        System.assertEquals(expectedBookingStatus, updatedBookingRec.Status__c);
        System.assertEquals(expectedPaymentStatus, updatedBookingRec.Payment_Status__c);
    }
}