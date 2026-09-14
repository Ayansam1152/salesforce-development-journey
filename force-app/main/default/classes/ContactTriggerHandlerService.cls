public with sharing class ContactTriggerHandlerService {
    
    public static void processContact(List<Contact> contacts)
    {
        Set<Id> contactIds = new Set<Id>();
        
        for(Contact con : contacts){
            contactIds.add(con.Id);
        }

        System.debug('I am from process contact part, now I am calling queueable');
        
        System.enqueueJob(new QueueableEmailValidation(contactIds));
    }
}