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
private class ReviewTriggerHandlerServiceTest {
    
    @TestSetup
    public static void makeData(){
        List<Contact> contacts = TestDataFactory.createContacts(5);
        List<Car__c> cars = TestDataFactory.createCars(5);
        List<Booking__c> bookings = TestDataFactory.createBookings(5, contacts, cars);
    }
    
    @isTest
    public static void testLowRatingReviewSharingWithCustomerAndCaseCreation_forNewReview()
    {
        Booking__c bookingRec = [Select Id, Status__c, Final_Booking_Price__c, Security_Deposit__c,Customer__c from Booking__c LIMIT 1];
        
        List<Payment_Transaction__c> paymentTransactions = new List<Payment_Transaction__c>();
        
        Payment_Transaction__c initialPayment = new Payment_Transaction__c();
        
        initialPayment.Amount__c = bookingRec.Final_Booking_Price__c;
        initialPayment.Booking__c = bookingRec.Id;
        initialPayment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        initialPayment.Transaction_Date__c = Datetime.now();
        initialPayment.Type__c = Constants.INITIAL_PAYMENT;
        
        Payment_Transaction__c securityPayment = new Payment_Transaction__c();
        
        securityPayment.Amount__c = bookingRec.Security_Deposit__c;
        securityPayment.Booking__c = bookingRec.Id;
        securityPayment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        securityPayment.Transaction_Date__c = Datetime.now();
        securityPayment.Type__c = Constants.SECURITY_DEPOSIT;
        
        paymentTransactions.add(initialPayment);
        paymentTransactions.add(securityPayment);
        
        // all payment done
        insert paymentTransactions;
        
        bookingRec.status__c = Constants.BOOKING_COMPLETED_STATUS;
        // update booking status to completed
        update bookingRec;
        
        Review__c reviewRec = new Review__C();
        
        reviewRec.Booking__c = bookingRec.Id;
        reviewRec.Rating__c = 1;
        reviewRec.Customer__c = bookingRec.Customer__c;
        reviewRec.Comments__c = 'Car was not up to the mark it stops many places ):';
        
        Test.startTest();
        insert reviewRec;
        Test.stopTest();
        
        
        Group customerSupportPubGroup = [Select Id From Group Where DeveloperName = :Constants.CUSTOMER_SUPPORT_PUBLIC_GROUP LIMIT 1];
        Booking__Share existingShare = [
            Select Id, AccessLevel, ParentId,RowCause,UserOrGroupId from Booking__Share WHERE ParentId = :bookingRec.Id And UserOrGroupId = :customerSupportPubGroup.Id Limit 1
        ];

        System.assertEquals(customerSupportPubGroup.Id, existingShare.UserOrGroupId, 'customer support group id is not matching...');
        System.assertEquals('Manual', existingShare.RowCause, 'Row Cause does not match with expected');
        System.assertEquals(Constants.SHARING_WITH_READ_ACCESS, existingShare.AccessLevel,'Access level of sharing records does not match');

        Case caseRecord = [Select Id, Related_Booking__c, ContactId,Type, Priority from Case ];

        System.assertEquals(bookingRec.Id, caseRecord.Related_Booking__c,'case booking id does not matching with booking');
        System.assertEquals(bookingRec.Customer__c, caseRecord.ContactId, 'case customer does not match with booking customer');
        System.assertEquals(Constants.CASE_PRIORITY_MEDIUM, caseRecord.Priority, 'Case priority also not matching');
        System.assertEquals(Constants.CASE_TYPE_NEGATIVE_REVIEW, caseRecord.Type, 'case type also not matching');
    }

     @isTest
    public static void testLowRatingReviewSharingWithCustomerAndCaseCreation_forExistingReview()
    {
        Booking__c bookingRec = [Select Id, Status__c, Final_Booking_Price__c, Security_Deposit__c,Customer__c from Booking__c LIMIT 1];
        
        List<Payment_Transaction__c> paymentTransactions = new List<Payment_Transaction__c>();
        
        Payment_Transaction__c initialPayment = new Payment_Transaction__c();
        
        initialPayment.Amount__c = bookingRec.Final_Booking_Price__c;
        initialPayment.Booking__c = bookingRec.Id;
        initialPayment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        initialPayment.Transaction_Date__c = Datetime.now();
        initialPayment.Type__c = Constants.INITIAL_PAYMENT;
        
        Payment_Transaction__c securityPayment = new Payment_Transaction__c();
        
        securityPayment.Amount__c = bookingRec.Security_Deposit__c;
        securityPayment.Booking__c = bookingRec.Id;
        securityPayment.Status__c = Constants.TRANSACTION_SUCCESS_STATUS;
        securityPayment.Transaction_Date__c = Datetime.now();
        securityPayment.Type__c = Constants.SECURITY_DEPOSIT;
        
        paymentTransactions.add(initialPayment);
        paymentTransactions.add(securityPayment);
        
        // all payment done
        insert paymentTransactions;
        
        bookingRec.status__c = Constants.BOOKING_COMPLETED_STATUS;
        // update booking status to completed
        update bookingRec;
        
        Review__c reviewRec = new Review__C();
        
        reviewRec.Booking__c = bookingRec.Id;
        reviewRec.Rating__c = 3;
        reviewRec.Customer__c = bookingRec.Customer__c;
        reviewRec.Comments__c = 'Car was not up to the mark it stops many places ):';

        insert reviewRec;

        Review__c existingReview = [Select Id, Rating__c from Review__c];
        
        Test.startTest();
        existingReview.Rating__c = 2;
        update existingReview;
        Test.stopTest();
        
        
        Group customerSupportPubGroup = [Select Id From Group Where DeveloperName = :Constants.CUSTOMER_SUPPORT_PUBLIC_GROUP LIMIT 1];
        Booking__Share existingShare = [
            Select Id, AccessLevel, ParentId,RowCause,UserOrGroupId from Booking__Share WHERE ParentId = :bookingRec.Id And UserOrGroupId = :customerSupportPubGroup.Id Limit 1
        ];

        System.assertEquals(customerSupportPubGroup.Id, existingShare.UserOrGroupId, 'customer support group id is not matching...');
        System.assertEquals('Manual', existingShare.RowCause, 'Row Cause does not match with expected');
        System.assertEquals(Constants.SHARING_WITH_READ_ACCESS, existingShare.AccessLevel,'Access level of sharing records does not match');

        Case caseRecord = [Select Id, Related_Booking__c, ContactId,Type, Priority from Case ];

        System.assertEquals(bookingRec.Id, caseRecord.Related_Booking__c,'case booking id does not matching with booking');
        System.assertEquals(bookingRec.Customer__c, caseRecord.ContactId, 'case customer does not match with booking customer');
        System.assertEquals(Constants.CASE_PRIORITY_MEDIUM, caseRecord.Priority, 'Case priority also not matching');
        System.assertEquals(Constants.CASE_TYPE_NEGATIVE_REVIEW, caseRecord.Type, 'case type also not matching');
        
    }
}