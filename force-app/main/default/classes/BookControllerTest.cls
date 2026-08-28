@isTest
private class BookControllerTest {

    @isTest
    static void testSearchBooks_success()
    {
        //Arrange
        Test.setMock(HttpCalloutMock.class, new BookApiMock());

        // Act
        Test.startTest();
        String result = BookController.searchBooks('Atomic Habit');
        String result2 = BookSearchController.searchBooks('Atomic Habit');
        Test.stopTest();

        //Assert

        System.assertNotEquals(null, result, 'Response should not be null');
        System.assert(result.contains('"success":true'), 'Expected successful API response');
        System.assert(result.contains('Atomic Habit'), 'Expected book was not returned');

        System.assertNotEquals(null, result2, 'Response should not be null');
        System.assert(result2.contains('"success":true'), 'Expected successful API response');
        System.assert(result2.contains('Atomic Habit'), 'Expected book was not returned');
    }
}