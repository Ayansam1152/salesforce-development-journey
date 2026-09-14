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
private class CarAvailabilityRestAPITest {
    @testSetup
    static void setupTestData() {
        List<Contact> contacts = TestDataFactory.createContacts(1);
        List<Car__c> cars  = TestDataFactory.createCars(1);
        List<Booking__c> bookings = TestDataFactory.createBookings(1, contacts, cars);
    }
    
    @isTest
    public static void getAvailableCars()
    {
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.params.put('startDate', formatDate(Date.today().addDays(10)));
        req.params.put('endDate', formatDate(Date.today().addDays(15)));
        req.params.put('location', 'Pune');
        
        RestContext.request = req;
        RestContext.response = res;
        
        CarAvailabilityRestAPI.ResponseWrapper response = CarAvailabilityRestAPI.getAvailableCars();
        
        Test.stopTest();
        
        System.debug(response);
        System.assertEquals(true, response.isSuccess);
    }
    
    private static String formatDate(Date inputDate){
        return inputDate.year()+'-'+inputDate.month()+'-'+inputDate.day();
    }
}