/**
 * Controller for retrieving car reviews and average rating information.
 */
public with sharing class CarReviewController {
    
    /**
     * Retrieves the reviews and average rating for a car.
     *
     * @param carId The Id of the car to fetch reviews for.
     * @return A wrapper containing the average rating and reviews for the specified car.
     */
    @AuraEnabled(cacheable = true)
    public static ReviewWrapper getCarReviews(Id carId)
    {
        Car__c car = [Select Id,Average_Rating__c From Car__c Where Id = :carId WITH USER_MODE LIMIT 1];
        
        Decimal averageRating = 0;
        
        if(car.Average_Rating__c == null)
        {
            averageRating = 0;
        }
        else
        {
            averageRating = car.Average_Rating__c;
        }
        
        List<Review__c> reviews = [
            Select Id,Comments__c, Rating__c, CreatedDate,  Booking__r.Car__c 
            From Review__c 
            Where Booking__r.Car__c = : carId 
            WITH USER_MODE
            Order BY CreatedDate DESC
        ];
        
        Integer totalReviews = reviews.size();
        
        Map<Integer, Integer> ratingDistributionMap = new Map<Integer,Integer>();
        
        for(integer i = 0;i<6;i++)
        {
            ratingDistributionMap.put(i, 0);
        }
        
        for(Review__c review : reviews)
        {
            Integer rating =(Integer) review.Rating__c;
            
            ratingDistributionMap.put(rating, ratingDistributionMap.get(rating)+1);
        }
        
        ReviewWrapper reviewWrapper = new ReviewWrapper(reviews,ratingDistributionMap,totalReviews,averageRating);
        
        return reviewWrapper;
    }
    
    
    public class ReviewWrapper{
        @AuraEnabled
        public List<Review__c> reviews;
        @AuraEnabled
        public Map<Integer,Integer> ratingDistribution;
        @AuraEnabled
        public Integer totalReviews;
        @AuraEnabled
        public Decimal averageRating;
        
        public ReviewWrapper(
            List<Review__c> reviews,
        Map<Integer,Integer> ratingDistribution,
        Integer totalReviews,
        Decimal averageRating
            )
        {
            this.reviews = reviews;
            this.ratingDistribution = ratingDistribution;
            this.totalReviews = totalReviews;
            this.averageRating = averageRating;
        }
    }
}