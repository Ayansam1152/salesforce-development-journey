public with sharing class CarTileListController {
    public class Filter{
        @AuraEnabled public String searchKey { get; set; }
        @AuraEnabled public String pickupLocation { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public Integer maxSeats { get; set; }
        @AuraEnabled public Decimal maxRentalRate { get; set; }
        @AuraEnabled public Decimal minRating { get; set; }
        @AuraEnabled public List<String> transmissionType { get; set; }
        @AuraEnabled public List<String> fuelType { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Car__c> getCars(Filter filter){
        List<String> criteria = new List<String>();
        String key, pickupLocation;
        Decimal maxSeat, maxRentalRate, minRating;
        List<String> transmissionType, fuelType;
        
        //default filter criteria
        String availableCars = Constants.CAR_AVAILABILITY_STATUS;
        criteria.add(' Availability_Status__c =: availableCars');
        
        // optional filter criteria
        if(String.isNotBlank(filter.searchKey))
        {
            key = '%'+filter.searchKey+'%';
            criteria.add(' Name like :key');
        }
        
        if(filter.maxSeats != null)
        {
            maxSeat = filter.maxSeats;
            criteria.add(' Number_of_Seats__c <= :maxSeat');
        }
        
        if(filter.maxRentalRate != null)
        {
            maxRentalRate = filter.maxRentalRate;
            criteria.add(' Rental_Rate_Per_Day__c <= :maxRentalRate');
        }
        
        if(filter.minRating != null)
        {
            minRating = filter.minRating;
            
            if(minRating == 0)
            {
                criteria.add(' (Average_Rating__c >= 0 OR Average_Rating__c = null)');
            }
            else {
                criteria.add(' Average_Rating__c >= : minRating');
            }
            
        }
        
        if(filter.transmissionType?.size() > 0)
        {
            transmissionType = filter.transmissionType;
            criteria.add(' Transmission_Type__c  in :transmissionType');
        }
        
        if(filter.fuelType?.size() > 0)
        {
            fuelType = filter.fuelType;
            criteria.add(' Fuel_Type__c in :fuelType');
        }
        
        if(String.isNotBlank(filter.pickupLocation))
        {
            pickupLocation = filter.pickupLocation;
            criteria.add(' PickupLocation__c = :pickupLocation');
        }
        
        DateTime startDateTime = DateTime.newInstance(filter.startDate, Time.newInstance(0,0,0,0));
        DateTime endDateTime = DateTime.newInstance(filter.endDate, Time.newInstance(23,59,59,0));
        
        Set<Id> bookedCarIds = new Set<Id>();
        
        for(Booking__c booking : [Select Id, Car__c From Booking__c WHERE Start_Date_Time__c >= :startDateTime And End_Date_Time__c  <= :endDateTime]){
            bookedCarIds.add(booking.Car__c);
        }
        
        if(!bookedCarIds.isEmpty())
        {
            criteria.add('Id not in :bookedCarIds');
        }
        
        String queryToGetCars = 'Select Id, Availability_Status__c,Average_Rating__c,Car_Description__c,Car_Family__c,Car_Image__c,Fuel_Type__c,Mileage_Limit_Per_Day__c,Model__c,Name,Number_of_Seats__c,PickupLocation__c,Primary_Image_Url__c,Rental_Rate_Per_Day__c,Transmission_Type__c From Car__c ';
        
        String whereClause = ' Where '+ String.join(criteria, ' AND ');
        queryToGetCars += whereClause;
        queryToGetCars += ' order by Name';
        
        System.debug('Query to get cars '+ queryToGetCars);
        
        try {
            return Database.query(queryToGetCars);
        } catch (Exception ex) {
            System.debug('Error mesg '+ex.getMessage());
            
            Log logger = Log.get();
            
            logger.publish('Error occurred while applying filter query to database');
            
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
}