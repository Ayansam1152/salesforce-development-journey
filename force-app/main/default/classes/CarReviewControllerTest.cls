@isTest
private class CarReviewControllerTest {
    @isTest
    static void returnsEmptyReviewSummaryForUnreviewedCar() {
        Car__c car = TestDataFactory.createCars(1)[0];

        CarReviewController.ReviewWrapper result = CarReviewController.getCarReviews(car.Id);

        System.assertEquals(0, result.totalReviews);
        System.assertEquals(0, result.averageRating);
        System.assertEquals(0, result.ratingDistribution.get(0));
        System.assertEquals(0, result.ratingDistribution.get(5));
        System.assertEquals(0, result.reviews.size());
    }

    @isTest
    static void returnsReviewAndAverageRating() {
        List<Contact> contacts = TestDataFactory.createContacts(1);
        List<Car__c> cars = TestDataFactory.createCars(1);
        Booking__c booking = TestDataFactory.createBookings(1, contacts, cars)[0];

        List<Payment_Transaction__c> payments = new List<Payment_Transaction__c>{
            new Payment_Transaction__c(
                Booking__c = booking.Id,
                Type__c = Constants.INITIAL_PAYMENT,
                Status__c = Constants.TRANSACTION_SUCCESS_STATUS,
                Amount__c = booking.Final_Booking_Price__c,
                Transaction_Date__c = Datetime.now()
            ),
            new Payment_Transaction__c(
                Booking__c = booking.Id,
                Type__c = Constants.SECURITY_DEPOSIT,
                Status__c = Constants.TRANSACTION_SUCCESS_STATUS,
                Amount__c = 50,
                Transaction_Date__c = Datetime.now()
            )
        };
        insert payments;

        booking.Status__c = Constants.BOOKING_COMPLETED_STATUS;
        booking.Payment_Status__c = Constants.BOOKING_PAID;
        update booking;

        insert new Review__c(
            Booking__c = booking.Id,
            Customer__c = contacts[0].Id,
            Rating__c = 5,
            Comments__c = 'Excellent car'
        );

        Car__c ratedCar = [SELECT Id, Average_Rating__c FROM Car__c WHERE Id = :cars[0].Id];
        CarReviewController.ReviewWrapper result = CarReviewController.getCarReviews(ratedCar.Id);

        System.assertEquals(1, result.totalReviews);
        System.assertEquals(1, result.ratingDistribution.get(5));
        System.assertEquals(5, result.averageRating);
        System.assertEquals('Excellent car', result.reviews[0].Comments__c);
    }
}