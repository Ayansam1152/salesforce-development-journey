@isTest
private class CarTileListControllerTest {
    @isTest
    static void filtersCarsAndExcludesBookedCar() {
        List<Contact> contacts = TestDataFactory.createContacts(1);
        List<Car__c> cars = TestDataFactory.createCars(2);
        TestDataFactory.createBookings(1, contacts, cars);

        CarTileListController.Filter filter = new CarTileListController.Filter();
        filter.startDate = Date.today().addDays(1);
        filter.endDate = Date.today().addDays(5);

        List<Car__c> results = CarTileListController.getCars(filter);

        System.assertEquals(1, results.size());
        System.assertEquals(cars[1].Id, results[0].Id);
    }

    @isTest
    static void appliesPositiveMinimumRating() {
        Car__c car = TestDataFactory.createCars(1)[0];
        car.Average_Rating__c = 4;
        update car;

        CarTileListController.Filter filter = new CarTileListController.Filter();
        filter.startDate = Date.today();
        filter.endDate = Date.today().addDays(7);
        filter.minRating = 4;

        List<Car__c> results = CarTileListController.getCars(filter);

        System.assertEquals(1, results.size());
        System.assertEquals(car.Id, results[0].Id);
    }
}