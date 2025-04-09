/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private Id categoryId;
    private String categoryName;
    private Integer pages;
    private Integer currentPage;
    
    
    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages) {
        // TODO: Initialize first page
        this.currentPage = 1;
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pages = pages;
    }
    
    /**
     * Constructor with current page
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     * @param currentPage Current page being processed
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pages, Integer currentPage) {
        // TODO: Initialize with specific page
        this.currentPage = currentPage;
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pages = pages;
        
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
        // TODO: Implement execute method
        // - Call NewsAPI for the current page
        // - Process and save articles
        // - Update category if last page
        // - Chain to next page if more pages exist
        

        NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, pages, currentPage);
        
        // Check if the API response is valid and contains articles
        if (response != null || !response.articles.isEmpty()) {
            List<Article__c> articles = response.toSObjects(categoryId, categoryName);

        //     System.debug('No articles found for category: ' + categoryName);
        //     insert articles; // Save articles to Salesforce
        //     System.debug('Inserted ' + articles.size() + ' articles.');
        //     // return; // Exit if no articles found
        // 
        
        if (articles != null && !articles.isEmpty()) {
            // Deduplicate based on URL__c
            Set<String> incomingUrls = new Set<String>();
            for (Article__c a : articles) {
                if (String.isNotBlank(a.URL__c)) {
                    incomingUrls.add(a.URL__c);
                }
            }
        
            Set<String> existingUrls = new Set<String>();
            if (!incomingUrls.isEmpty()) {
                for (Article__c existing : [
                    SELECT URL__c FROM Article__c WHERE URL__c IN :incomingUrls
                ]) {
                    existingUrls.add(existing.URL__c);
                }
            }
        
            List<Article__c> articlesToInsert = new List<Article__c>();
            for (Article__c a : articles) {
                if (!existingUrls.contains(a.URL__c)) {
                    articlesToInsert.add(a);
                }
            }
        
            if (!articlesToInsert.isEmpty()) {
                insert articlesToInsert;
                System.debug('Inserted ' + articlesToInsert.size() + ' articles.');
            } else {
                System.debug('No new articles to insert for category: ' + categoryName);
            }
        } else {
            System.debug('No articles found for category: ' + categoryName);
        }
    }
        Integer currentDepth = AsyncInfo.getCurrentQueueableStackDepth();
        Integer maxDepth = AsyncInfo.getMaximumQueueableStackDepth();
        
        // Step 3: Update category with last synced date if it's the last page
        if (currentPage < pages && !(System.AsyncInfo.hasMaxStackDepth() && currentDepth >= maxDepth)) {
            System.enqueueJob(new NewsCategoryQueueable(categoryId, categoryName, pages, currentPage + 1));
            System.debug('Enqueued next page: ' + (currentPage + 1));
         } else { // If we're on the last page
            try {
                // Retrieve the category and update the Last_Synced__c field
                News_Category__c categoryToUpdate = [
                    SELECT Id, Last_Synced__c FROM News_Category__c WHERE Id = :categoryId LIMIT 1
                ];
                categoryToUpdate.Last_Synced__c = System.now();
                categoryToUpdate.Sync__c = false;
                update categoryToUpdate; // Save the update
                System.debug('Updated Last_Synced__c for category ' + categoryName);
            } catch (Exception e) {
                System.debug('Failed to update category: ' + e.getMessage());
            }
        
            // Step 4: Chain to the next page if more pages exist           
            
            
            
        }
    }
} 