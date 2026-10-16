@isTest
private class QueueableTotalCarValueTest {
    private static Booking__c createBooking(Id contactId, Id carId, String bookingStatus, Integer dayOffset) {
        return new Booking__c(
            Customer__c = contactId,
            Car__c = carId,
            Start_Date_Time__c = Date.today().addDays(dayOffset),
            End_Date_Time__c = Date.today().addDays(dayOffset + 3),
            Status__c = bookingStatus,
            Payment_Status__c = Constants.BOOKING_PAID,
            Final_Booking_Price__c = 100
        );
    }

    private static Payment_Transaction__c createSuccessfulPayment(Id bookingId, Decimal amount) {
        return new Payment_Transaction__c(
            Amount__c = amount,
            Booking__c = bookingId,
            Status__c = Constants.TRANSACTION_SUCCESS_STATUS,
            Transaction_Date__c = Datetime.now(),
            Type__c = Constants.INITIAL_PAYMENT
        );
    }

    @isTest
    static void sumsClosedBookingsAndIgnoresOtherStatuses() {
        List<Contact> contacts = TestDataFactory.createContacts(1);
        Contact contact = contacts[0];
        List<Car__c> cars = TestDataFactory.createCars(2);
        cars[1].Total_Bookings_Value__c = 40;
        update cars;

        List<Booking__c> bookings = new List<Booking__c>{
            createBooking(contact.Id, cars[0].Id, Constants.BOOKING_PENDING, 1),
            createBooking(contact.Id, cars[0].Id, Constants.BOOKING_PENDING, 5),
            createBooking(contact.Id, cars[1].Id, Constants.BOOKING_PENDING, 9)
        };
        insert bookings;

        List<Payment_Transaction__c> payments = new List<Payment_Transaction__c>{
            createSuccessfulPayment(bookings[0].Id, 125),
            createSuccessfulPayment(bookings[1].Id, 75),
            createSuccessfulPayment(bookings[2].Id, 300)
        };
        insert payments;

        Test.startTest();
        bookings[0].Status__c = Constants.BOOKING_CLOSED_STATUS;
        bookings[1].Status__c = Constants.BOOKING_CLOSED_STATUS;
        update new List<Booking__c>{ bookings[0], bookings[1] };
        Test.stopTest();

        Map<Id, Car__c> updatedCars = new Map<Id, Car__c>([
            SELECT Id, Total_Bookings_Value__c
            FROM Car__c
            WHERE Id IN :cars
        ]);
        System.assertEquals(200, updatedCars.get(cars[0].Id).Total_Bookings_Value__c);
        System.assertEquals(40, updatedCars.get(cars[1].Id).Total_Bookings_Value__c);
    }

    @isTest
    static void doesNothingWhenNoClosedBookingsMatch() {
        List<Contact> contacts = TestDataFactory.createContacts(1);
        Contact contact = contacts[0];
        List<Car__c> cars = TestDataFactory.createCars(1);
        Car__c car = cars[0];
        car.Total_Bookings_Value__c = 25;
        update car;

        Booking__c pendingBooking = createBooking(
            contact.Id,
            car.Id,
            Constants.BOOKING_PENDING,
            1
        );
        insert pendingBooking;
        Payment_Transaction__c payment = createSuccessfulPayment(pendingBooking.Id, 100);
        insert payment;

        Test.startTest();
        System.enqueueJob(new QueueableTotalCarValue(new List<Id>{ car.Id }));
        Test.stopTest();

        Car__c unchangedCar = [SELECT Total_Bookings_Value__c FROM Car__c WHERE Id = :car.Id];
        System.assertEquals(25, unchangedCar.Total_Bookings_Value__c);
    }
}