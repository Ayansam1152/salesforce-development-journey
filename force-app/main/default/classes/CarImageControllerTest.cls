@isTest
private class CarImageControllerTest {
    @isTest
    static void createsAndRetrievesCarImages() {
        Car__c car = TestDataFactory.createCars(1)[0];
        ContentVersion fileVersion = new ContentVersion(
            Title = 'Car photo',
            PathOnClient = 'car-photo.jpg',
            VersionData = Blob.valueOf('image contents')
        );
        insert fileVersion;

        fileVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :fileVersion.Id];
        CarImageController.createFile(String.valueOf(fileVersion.ContentDocumentId), String.valueOf(car.Id), true);

        List<Car_Image__c> createdImages = [
            SELECT Car__c, Image_Url__c, Primary_Image__c
            FROM Car_Image__c
            WHERE Car__c = :car.Id
        ];
        System.assertEquals(1, createdImages.size());
        System.assertEquals(true, createdImages[0].Primary_Image__c);
        System.assert(createdImages[0].Image_Url__c.contains(String.valueOf(fileVersion.Id)));

        List<Car_Image__c> returnedImages = CarImageController.getCarImages(car.Id);
        System.assertEquals(1, returnedImages.size());
        System.assertEquals(car.Name, returnedImages[0].Car__r.Name);
    }

    @isTest
    static void createsNonPrimaryImage() {
        Car__c car = TestDataFactory.createCars(1)[0];
        ContentVersion fileVersion = new ContentVersion(
            Title = 'Secondary car photo',
            PathOnClient = 'secondary-car-photo.jpg',
            VersionData = Blob.valueOf('image contents')
        );
        insert fileVersion;
        fileVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :fileVersion.Id];

        CarImageController.createFile(String.valueOf(fileVersion.ContentDocumentId), String.valueOf(car.Id), false);

        Car_Image__c createdImage = [SELECT Primary_Image__c FROM Car_Image__c WHERE Car__c = :car.Id];
        System.assertEquals(false, createdImage.Primary_Image__c);
    }
}