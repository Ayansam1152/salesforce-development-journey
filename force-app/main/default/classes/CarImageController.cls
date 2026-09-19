public with sharing class CarImageController {
    @AuraEnabled
    public static void createFile(
        String documentId,
    String recordId,
    Boolean isPrimaryImage
        )
    {
        List<ContentVersion> contentVersions = [
            Select Id, ContentDocumentId 
            From ContentVersion 
            Where IsLatest = true and ContentDocumentId = :documentId
            Order By CreatedDate DESC 
            LIMIT 1
        ];
        
        if(contentVersions.isEmpty())
        {
            throw new AuraHandledException('Content version not found for the document Id '+documentId);
        }
        
        Car_Image__c carImage = new Car_Image__c(
            Car__c = recordId,
        Image_Url__c = '/sfc/servlet.shepherd/version/download/'+contentVersions[0].Id
            );
        
        if(isPrimaryImage)
        {
            carImage.Primary_Image__c = true;
        }
        
        try {
            insert carImage;
        } catch (Exception e) {
            
            System.debug(e.getMessage());
            Log logger = Log.get();
            logger.publish(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Car_Image__c> getCarImages(Id carId){
        try {
            List<Car_Image__c> images = [Select Id, Car__r.Name, Image_Url__c from Car_Image__c Where Car__c =: carId];
            System.debug('Car Images loaded size '+images.size());
            return images;
        } catch (Exception e) {
            Log logger = Log.get();
            logger.publish(e.getMessage());
            
            throw new AuraHandledException(e.getMessage());
        }
    }
}