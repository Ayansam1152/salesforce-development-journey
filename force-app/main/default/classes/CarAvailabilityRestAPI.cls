@restResource(urlMapping='/v1/cars/available/*')
global with sharing class CarAvailabilityRestAPI {
    
    @HttpGet
    global static ResponseWrapper getAvailableCars(){
        // get the query parameters from the request
        RestRequest req = RestContext.request;
        
        // Date startDate = Date.valueOf(req.params.get('startDate'));
        // Date endDate = Date.valueOf(req.params.get('endDate'));
        String rawStartDate = req.params.get('startDate');
        String rawEndDate = req.params.get('endDate');
        String location = req.params.get('location');
        String fuelType = req.params.get('fuelType');
        String transmissionType = req.params.get('transmissionType');
        Date startDate;
        Date endDate;
        
        if(rawStartDate == null || rawEndDate == null)
        {
            RestContext.response.statusCode = 400;
            return new ResponseWrapper(false, 'Start date and end date are required', null);
        }
        
        if(String.isBlank(location))
        {
            RestContext.response.statusCode = 400;
            return new ResponseWrapper(false, 'Location is required', null);
        }
        
        try {
            startDate = Date.valueOf(rawStartDate);
            endDate = Date.valueOf(rawEndDate);
        } catch (Exception e) {
            RestContext.response.statusCode = 400;
            return new ResponseWrapper(false, 'Invalid date format. Please use YYYY-MM-DD format (e.g., 2026-09-14).', null);
        }
        
        if(startDate > endDate)
        {
            RestContext.response.statusCode = 400;
            return new ResponseWrapper(false, 'Start date cannot be after end date', null);
        }
        
        Set<Id> bookedCarIds = new Set<Id>();
        
        DateTime  startDateTime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = Datetime.newInstance(endDate, Time.newInstance(0, 0, 0, 0));
        
        for(Booking__c booking : [Select Id, Car__c from Booking__c WHERE Start_Date_Time__c >= :startDateTime And End_Date_Time__c <= : endDateTime and status__c != :Constants.BOOKING_CANCELLED_STATUS and status__c != :Constants.BOOKING_CLOSED_STATUS])
        {
            bookedCarIds.add(booking.Car__c);
        }
        
        String availableCarStatus = Constants.CAR_AVAILABILITY_STATUS;
        
        String query = 'Select Id, Name, Rental_Rate_Per_Day__c,Primary_Image_Url__c,Fuel_Type__c,Car_Family__c,Transmission_Type__c,Car_Description__c, PickupLocation__c From Car__c Where Id not in :bookedCarIds and PickupLocation__c = :location and Availability_Status__c = :availableCarStatus';
        
        if(!String.isBlank(fuelType))
        {
            query = query + ' and Fuel_Type__c = :fuelType';
        }
        
        if(!String.isBlank(transmissionType))
        {
            query = query+' and Transmission_Type__c= :transmissionType';
        }
        
        List<Car__c> cars = Database.query(query);
        
        if(cars.isEmpty())
        {
            return new ResponseWrapper(false, 'No cars available for the given criteria', new List<CarResponseWrapper>());
        }
        
        List<CarResponseWrapper> availableCars = new List<CarResponseWrapper>();
        
        for(Car__c car : cars)
        {
            CarResponseWrapper carResponse = new CarResponseWrapper(car);
            availableCars.add(carResponse);
        }
        
        return new ResponseWrapper(true, Constants.CAR_API_SUCCESS_MESSAGE, availableCars);
    }
    
    global class ResponseWrapper{
        Boolean isSuccess;
        String message;
        List<CarResponseWrapper> availableCars;
        
        public ResponseWrapper(Boolean success, String message, List<CarResponseWrapper> availableCars){
            this.isSuccess = success;
            this.message = message;
            this.availableCars = availableCars;
        }
    }
    
    global class CarResponseWrapper{
        String carId;
        String carName;
        Decimal rentalRate;
        String imgUrl;
        String fuelType;
        String carFamily;
        String transmissionType;
        String description;
        String carLocation;
        
        public CarResponseWrapper(Car__c car){
            this.carId = car.Id;
            this.carName = car.Name;
            this.rentalRate = car.Rental_Rate_Per_Day__c;
            this.imgUrl = car.Primary_Image_Url__c;
            this.fuelType = car.Fuel_Type__c;
            this.carFamily = car.Car_Family__c;
            this.transmissionType = car.Transmission_Type__c;
            this.description = car.Car_Description__c;
            this.carLocation = car.PickupLocation__c;
        }
    }
    
}