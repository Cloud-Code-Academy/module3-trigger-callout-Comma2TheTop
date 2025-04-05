/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    // TODO: Define API endpoint constants
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';
    //key = 'd97e81a3ebf54e448b168bc117b297a7'

    // TODO: Define default parameters
    private static final Integer DEFAULT_PAGE_SIZE = 20; 
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        // TODO: Implement method to fetch headlines by category
        // - Validate and set defaults for parameters
        // - Build the request URL
        // - Make the callout
        // - Parse and return the response
        
        //req.setEndpoint('callout:'+API_NAMED_CREDENTIAL+API_ENDPOINT+'?country=us&category='+category);
        String endpoint = API_NAMED_CREDENTIAL+API_ENDPOINT+'?country=us&category='+category+'&pageSize='+pageSize+'&page='+page;

        HttpResponse response = makeCallout(endpoint);
        return parseResponse(response.getBody());
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    public static HttpResponse makeCallout(String endpoint) {
        // TODO: Implement HTTP callout
        // - Create and configure HTTP request
        // - Make the callout
        // - Handle exceptions
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);

        
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res;
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {
        // TODO: Implement JSON parsing
        // - Deserialize JSON to NewsAPIResponse
        // - Handle exceptions
        if(String.isEmpty(jsonResponse)){
            throw new NewsAPIException('No response received');
        }
        try{
        NewsAPIResponse responseForWrapper = (NewsAPIResponse) System.JSON.deserialize(jsonResponse, NewsAPIResponse.class);
        if(responseForWrapper == null) {
            throw new NewsAPIException('No response received');
        }
        return responseForWrapper;
        } catch (Exception e) {
            System.debug('Exception caught while parsing JSON response: ' + e.getMessage());
            throw new NewsAPIException('Error parsing response');
        }
        //return null;
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 