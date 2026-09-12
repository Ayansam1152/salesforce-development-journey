public with sharing class ReviewTriggerHandler extends TriggerHandler {
    
    List<Review__c> reviews =(List<Review__c>) Trigger.new;
    Map<Id,Review__c> oldReviewMap =(Map<Id,Review__c>) Trigger.oldMap;
    
    public override void afterInsert(){
        List<Review__c> lowRatingReview = new List<Review__c>();
        
        for(Review__c review : reviews)
        {
            if(review.Rating__c < Constants.LOW_RATING_THRESHOLD)
            {
                lowRatingReview.add(review);
            }
        }
        
        ReviewTRiggerHandlerService.shareLowRatingAndCreateCase(reviews);
    }
    
    public override void afterUpdate(){
        List<Review__c> lowRatingReview = new List<Review__c>();
        
        for(Review__c review : reviews)
        {
            Decimal newRating = review.Rating__c;
            Decimal oldRating = oldReviewMap.get(review.Id).Rating__c;
            
            if(newRating != oldRating && newRating < Constants.LOW_RATING_THRESHOLD)
            {
                lowRatingReview.add(review);
            }
        }
        
        ReviewTRiggerHandlerService.shareLowRatingAndCreateCase(reviews);
    }
    
}