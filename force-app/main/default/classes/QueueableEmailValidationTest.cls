@isTest
private class QueueableEmailValidationTest {
    private class EmailResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        EmailResponseMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }

    private class FailingEmailMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            throw new CalloutException('Mock email API failure');
        }
    }

    private static Contact createContact() {
        Contact contact = new Contact(LastName = 'Queueable Test', Email = 'queueable@example.com');
        insert contact;
        return contact;
    }

    private static void enqueueValidation(Id contactId) {
        Test.startTest();
        System.enqueueJob(new QueueableEmailValidation(new Set<Id>{ contactId }));
        Test.stopTest();
    }

    @isTest
    static void marksDeliverableEmailAsVerified() {
        Contact contact = createContact();
        Test.setMock(HttpCalloutMock.class, new EmailValidationHttpMock());

        enqueueValidation(contact.Id);

        Contact updatedContact = [SELECT Email_Verified__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(true, updatedContact.Email_Verified__c);
    }

    @isTest
    static void marksEmailAsUnverifiedForNonSuccessResponse() {
        Contact contact = createContact();
        Test.setMock(HttpCalloutMock.class, new EmailResponseMock(503, '{}'));

        enqueueValidation(contact.Id);

        Contact updatedContact = [SELECT Email_Verified__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(false, updatedContact.Email_Verified__c);
    }

    @isTest
    static void marksEmailAsUnverifiedWhenNotDeliverable() {
        Contact contact = createContact();
        Test.setMock(
            HttpCalloutMock.class,
            new EmailResponseMock(200, '{"email_deliverability":{"status":"undeliverable","status_detail":"invalid_email"}}')
        );

        enqueueValidation(contact.Id);

        Contact updatedContact = [SELECT Email_Verified__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(false, updatedContact.Email_Verified__c);
    }

    @isTest
    static void marksEmailAsUnverifiedWhenCalloutThrows() {
        Contact contact = createContact();
        Test.setMock(HttpCalloutMock.class, new FailingEmailMock());

        enqueueValidation(contact.Id);

        Contact updatedContact = [SELECT Email_Verified__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals(false, updatedContact.Email_Verified__c);
    }

    @isTest
    static void handlesEmptyContactSet() {
        Test.startTest();
        System.enqueueJob(new QueueableEmailValidation(new Set<Id>()));
        Test.stopTest();
    }
}