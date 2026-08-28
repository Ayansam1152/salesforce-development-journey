public with sharing class BookSearchController {
    
    public static String IMAGE_BASE_URL = 'https://i.dr.com.tr';
    // 1. Define a clean, flat DTO for LWC
    public class BookDTO {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public String image { get; set; }
        @AuraEnabled public String oldprice { get; set; }
        @AuraEnabled public String price { get; set; }
        @AuraEnabled public String author { get; set; }
    }
    
    private class ApiResponse {
        public Boolean success { get; set; }
        public List<BookDTO> result { get; set; }
    }
    
    @AuraEnabled
    public static List<BookDTO> searchBooks(String bookName) {
        try {
            // 2. Make your external HTTP callout here
            HttpResponse response = makeHttpCallout(bookName);
            
            // 3. Parse the raw external API data
            Integer statusCode = response.getStatusCode();
            
            if(statusCode >=200 && statusCode <300){
                List<BookDTO> mappedBooks = parseExternalApiData(response.getBody());
                
                for(BookDTO book : mappedBooks)
                {
                    String imagePath = book.image.replaceFirst('^\\.{3}', '');
                    book.image = IMAGE_BASE_URL+imagePath;
                }
                
                return mappedBooks;
            }
            else {
                throw new AuraHandledException('Error while fetching books with status code ' + statusCode);
            }
            
            // 4. Return the clean list directly
            // return mappedBooks;
            
        } catch (Exception e) {
            // 5. Let Salesforce handle the error wrapper
            throw new AuraHandledException('Failed to fetch books: ' + e.getMessage());
        }
    }
    
    private static List<BookSearchController.BookDTO> parseExternalApiData(String rawJson)
    {
        ApiResponse response = (ApiResponse) JSON.deserialize(rawJson, ApiResponse.class);
        return response.result == null ? new List<BookDTO>() : response.result;
    }
    
    private static HttpResponse makeHttpCallout(String bookName){
        HttpRequest request = new HttpRequest();
        
        request.setMethod('GET');
        String endpoint = 'callout:Collect_API/book/search?query='+EncodingUtil.urlEncode(bookName, 'UTF-8');
        
        System.debug('actual url '+endpoint);
        
        request.setEndpoint(endpoint);
        
        // it just a temporary will add this in named cred
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        return response;
        
    }
}