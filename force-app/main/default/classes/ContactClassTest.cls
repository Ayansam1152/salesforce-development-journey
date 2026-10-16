@isTest
private class ContactClassTest {
    @testSetup
    static void makeContacts() {
        insert new List<Contact>{
            new Contact(FirstName = 'Avery', LastName = 'Stone', Email = 'avery@example.com'),
            new Contact(FirstName = 'Jordan', LastName = 'Reed', Email = 'jordan@example.com')
        };
    }

    @isTest
    static void returnsContactsMatchingName() {
        List<Contact> matches = ContactClass.getContacts('Avery');

        System.assertEquals(1, matches.size());
        System.assertEquals('Avery Stone', matches[0].Name);
        System.assertEquals('avery@example.com', matches[0].Email);
    }

    @isTest
    static void returnsNoContactsForNonmatchingName() {
        System.assertEquals(0, ContactClass.getContacts('No Such Contact').size());
    }

    @isTest
    static void blankSearchReturnsContacts() {
        System.assertEquals(2, ContactClass.getContacts('').size());
    }
}