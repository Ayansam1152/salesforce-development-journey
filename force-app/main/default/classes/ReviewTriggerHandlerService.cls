public with sharing class ReviewTriggerHandlerService {
    
    public static void shareLowRatingAndCreateCase(List<Review__c> reviews)
    {
        Group customerSupportPubGroup = [Select Id From Group Where DeveloperName = :Constants.CUSTOMER_SUPPORT_PUBLIC_GROUP LIMIT 1];
        
        Set<Id> bookingIds = new Set<Id>();
        
        for(Review__c review : reviews)
        {
            if(review.Booking__c != null)
            {
                bookingIds.add(review.Booking__c);
            }
        }
        
        // find existing sharing
        
        List<Booking__Share> existingShare = [
            Select Id,ParentId
            from Booking__Share WHERE RowCause = :Schema.Booking__share.RowCause.MANUAL and UserOrGroupId = :customerSupportPubGroup.Id AND ParentId in :bookingIds 
        ];
        
        Set<Id> alreadySharedBookingIds = new Set<Id>();
        
        for(Booking__Share shareRecord : existingShare)
        {
            alreadySharedBookingIds.add(shareRecord.ParentId);
        }
        
        List<Booking__Share> sharingRecordList = new List<Booking__Share>();
        
        for(Id bookingId : bookingIds)
        {
            if(!alreadySharedBookingIds.contains(bookingId))
            {
                Booking__Share sharingRecord = new Booking__Share();
                
                sharingRecord.ParentId = bookingId;
                sharingRecord.AccessLevel = Constants.SHARING_WITH_READ_ACCESS;
                sharingRecord.UserOrGroupId = customerSupportPubGroup.Id;
                sharingRecord.RowCause = Schema.Booking__share.RowCause.MANUAL;
                
                sharingRecordList.add(sharingRecord);
            }
        }
        
        if(sharingRecordList.size() > 0)
        {
            try {
                insert sharingRecordList;
                
            } catch (Exception e) {
                Log logger = Log.get();
                
                logger.publish(e.getMessage());
            }
        }

        createCaseForLowRating(reviews);
    }
    
    private static void createCaseForLowRating(List<Review__c> reviews)
    {
        Id reviewIssueRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Constants.CASE_RECORD_TYPE_REVIEW_ISSUE).getRecordTypeId();
        
        Set<Id> reviewIds = new Set<Id>();
        
        for(Review__c review: reviews){
            reviewIds.add(review.Id);
        }
        
        List<Review__C> reviewList = [Select Id, Rating__c, Comments__c, Customer__c, Booking__c, Booking__r.Car__c From Review__c Where Id in :reviewIds];
        
        List<Case> existingCases = [
        Select Id, Review_ID__c 
        from Case 
        Where 
        RecordTypeId = :reviewIssueRecordTypeId and 
        Type = :Constants.CASE_TYPE_NEGATIVE_REVIEW and 
        Review_ID__c in :reviewIds];

        Set<Id> existingReviewIds = new Set<Id>();

        for(Case existingCase : existingCases){
            existingReviewIds.add(existingCase.Review_ID__c);
        }

        List<Case> casesToInsert = new List<Case>();
        for(Review__c review : reviewList){
            if(!existingReviewIds.contains(review.Id))
            {
                Case newCase = new Case();
                newCase.RecordTypeId = reviewIssueRecordTypeId;
                newCase.Type = Constants.CASE_TYPE_NEGATIVE_REVIEW;
                newCase.Priority =  Constants.CASE_PRIORITY_MEDIUM;
                newCase.Related_Booking__c = review.Booking__c;
                newCase.Review_ID__c = review.Id;
                newCase.Related_Car__c = review.Booking__r.Car__c;
                //newCase.Car__c = review.Booking__r.Car__c;
                newCase.ContactId  = review.Customer__c;
                newCase.Subject = 'Negative Review Case for Review ID: ' + review.Id +' with Rating: ' + review.Rating__c;
                newCase.Description = 'A negative review has been submitted with comments of ' + review.Comments__c + ' and a rating of ' + review.Rating__c + '. Please investigate the issue and take necessary actions.';

                casesToInsert.add(newCase);
            }
        }

        if(casesToInsert.size() > 0)
        {
            try {
                insert casesToInsert;
                
            } catch (Exception e) {
                Log logger = Log.get();
                
                logger.publish(e.getMessage());
            }
        }

    }
    
    // My Thought process
    public static void handleReviewLessThenThreeStars(List<Review__c> reviews)
    {
        /*
        // logic to share booking to customer support team
        List<Review__c> lowRatingReviews = new List<Review__c>();
        
        for(Review__c review : reviews)
        {
            if(review.Rating__c < 3)
            {
                lowRatingReviews.add(review);
            }
        }
        
        // share the record with the customer support team
        if(lowRatingReviews.size() == 0) return;
        
        List<Review__c> reviewWithBooking = [
            Select Id, 
            Booking__r.Id,
            Booking__r.Customer__c, 
            Booking__r.Total_Paid_Amount__c, 
            Booking__r.Car__c, 
            Booking__r.Booking_Duration__c  
            from Review__c  
            Where Id in : lowRatingReviews and Booking__c != null
                                            ];
        
        List<Booking__c> bookingToBeShare = new List<Booking__c>();
        
        for(Review__c review : reviewWithBooking)
        {
            //bookingIds.add(review.Booking__r);
        }
        
        Group customerSupportGroup = [Select Id From Group Where DeveloperName = 'Customer_Support_Review_Group' LIMIT 1];
        */
    }
}