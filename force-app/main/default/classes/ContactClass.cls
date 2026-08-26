public with sharing class ContactClass {
    
    @AuraEnabled(cacheable = true)
    public static List<Contact> getContacts(String contactName){
        try {
            contactName = '%'+contactName+'%';
            return [Select Id, Name, Email, Phone From Contact Where Name like :contactName];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}