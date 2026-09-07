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
public class TestDataFactory {
    // create Contact
    public static List<Contact> createContacts(Integer numberOfContacts) {
        List<Contact> contacts = new List<Contact>();
        
        for (Integer i = 0; i < numberOfContacts; i++) {
            contacts.add(new Contact(
                FirstName = 'TestFirstName' + i,
            LastName = 'TestLastName' + i,
            Email = 'test' + i + '@gmail.com'
                ));
        }
        
        insert contacts;
        return contacts;
    }
    
    //Create Car
    public static List<Car__c> createCars(Integer numberOfCars) {
        List<Car__c> cars = new List<Car__c>();
        
        for (Integer i = 0; i < numberOfCars; i++) {
            cars.add(new Car__c(
            Name = 'TestCar' + i,
            Make__c = 'TestMake' + i,
            Model__c = 'TestModel' + i,
            Year__c = 2020 + i,
            Availability_Status__c = 'Available',
            Fuel_Type__c = 'Petrol',
            Transmission_Type__c = 'Automatic',
            Mileage_Limit_Per_Day__c = 100 + i,
            Rental_Rate_Per_day__c = 100 + i,
            Number_of_Seats__c = 5
            ));
        }
        
        insert cars;
        return cars;
    }
    //Create Booking
    public static List<Booking__c> createBookings(Integer numberOfBookings, List<Contact> contacts, List<Car__c> cars) {
        List<Booking__c> bookings = new List<Booking__c>();
        
        for (Integer i = 0; i < numberOfBookings; i++) {
            bookings.add(new Booking__c(
                Customer__c = contacts[Math.Mod(i, contacts.size())].Id,
                Car__c = cars[Math.MOD(i , cars.size())].Id,
                Start_Date_Time__c = Date.today().addDays(1+i),
                End_Date_Time__c = Date.today().addDays(1+i + 3),
                Status__c = Constants.BOOKING_PENDING,
                Payment_Status__c = Constants.BOOKING_PENDING,
                Final_Booking_Price__c = 300 + i
                //Security_Deposit__c = 100 + i
            ));
        }
        
        insert bookings;
        return bookings;
    }
    
}