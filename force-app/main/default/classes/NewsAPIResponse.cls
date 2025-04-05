/**
 * Wrapper class for parsing the NewsAPI response
 */
public class NewsAPIResponse {
    // TODO: Define fields to match the NewsAPI response structure
    public String status { get; set; }
    public Integer totalResults { get; set; }
    public List<Article> articles { get; set; }
    
    /**
     * Inner class representing a news article
     */
    public class Article {
        // TODO: Define article fields
        public Source source {get; set; }
        public String author {get; set; }
        public String title {get; set; }
        public String description {get; set; }
        public String url {get; set;}
        public String urlToImage {get; set; }
        public String publishedAt {get; set; }
        public String content {get; set; }
        
        /**
         * Converts the API article to a Salesforce Article__c record
         * @return Article__c The Salesforce record
         */
        public Article__c toSObject() {
            // TODO: Implement conversion from API article to Salesforce record
            // Consider:
            // - Handling date conversion
            // - Generating a unique record name
            // - Handling field length limits
            // String formattedDate = publishedAt.replace('T', '').replace('Z', '');
            // Datetime convertedDateTime = Datetime.valueOfGmt(formattedDate);
            Article__c newArticle = new Article__c();
                newArticle.Title__c = title;
                newArticle.Author__c = author;
                newArticle.Description__c = description;
                newArticle.URL__c = url != null && url.length() > 255 ? url.substring(0, 255) : url;
                newArticle.urlToImage__c = urlToImage;
                newArticle.Content__c = content;
                newArticle.Source__c = source.name;
                Datetime dt = Datetime.valueOf(publishedAt.replace('Z', ''));
                newArticle.Published_At__c = dt;

                return newArticle;

        }
    }
    
    /**
     * Inner class representing a news source
     */
    public class Source {
        // TODO: Define source fields
        public String id {get; set; }
        public String name {get; set; }
    }
    
    /**
     * Helper method to convert all articles in this response to Salesforce records
     * @return List<Article__c> List of Salesforce records
     */
    public List<Article__c> toSObjects() {
        // TODO: Implement conversion of all articles to Salesforce records
        List<Article__c> records = new List<Article__c>();
        if(articles != null) {
            for(Article currentArticle : articles){
                records.add(currentArticle.toSObject());
            }
        }
        return records;
    }
} 