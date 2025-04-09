/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {
    
    /**
     * Handles after insert events for News_Category__c
     * Uses Future method for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        // TODO: Implement insert handler
        // - Filter categories that need to be synced
        // - Call future method for callouts
        
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();
        List<String> categoryNames = new List<String>();
        Map<String, Id> categoryNameToIdMap = new Map<String, Id>();
        
        for(News_Category__c category : newRecords) {
            if(category.Sync__c) {
                categoryNameToIdMap.put(category.name, category.Id);
                //categoryNames.add(category.Name);
            } 
        }
        
            if(categoryNameToIdMap.keySet().size() > 0) {
                syncCategoriesWithFuture(categoryNameToIdMap);
        }
    }

    
    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        // TODO: Implement update handler
        // - Filter categories that need to be synced
        // - Call queueable method for callouts
        List<News_Category__c> categoriesToSyncUpdate = new List<News_Category__c>();
        
        for(News_Category__c category : newRecords) {
            News_Category__c oldCategory = oldMap.get(category.Id);
            if(category.Sync__c && !oldCategory.Sync__c) {
                categoriesToSyncUpdate.add(category);
            }   
        }

        if(categoriesToSyncUpdate.size() > 0) {
            syncCategoriesWithQueueable(categoriesToSyncUpdate);         
    }
}
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNames List of category names to sync
     */
    @future(callout=true)
    public static void syncCategoriesWithFuture(Map<String, Id> categoryNameToIdMap) {
        // TODO: Implement future method
        // - Get categories by name
        // - Make callouts to NewsAPI for each category
        // - Insert retrieved articles
        // - Update categories with last synced date
        if(Test.isRunningTest() && !TestUtils.bypassTestCheck){
            return;
        }
        List<Article__c> articlesToInsert = new List<Article__c>();
        List<News_Category__c> categoriesToUpdate = new List<News_Category__c>();
        
        for(String categoryName : categoryNameToIdMap.keySet()) {
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, null, null);
            if(response != null && response.articles != null) {
            List<Article__c> articles = response.toSObjects(categoryNameToIdMap.get(categoryName), categoryName);
            
            // if (articles != null && !articles.isEmpty()) {
            //     articlesToInsert.addAll(articles);
            // }
            if (articles != null && !articles.isEmpty()) {
                // Deduplicate using URL__c
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
            
                for (Article__c a : articles) {
                    if (!existingUrls.contains(a.URL__c)) {
                        articlesToInsert.add(a);
                    }
                }
            }
            
        }

            News_Category__c categoryToUpdate = new News_Category__c();
            categoryToUpdate.Id = categoryNameToIdMap.get(categoryName);
            categoryToUpdate.Name = categoryName;
            categoryToUpdate.Last_Synced__c = Datetime.now();
            categoryToUpdate.Sync__c = false;  // Set the current date/time
            categoriesToUpdate.add(categoryToUpdate);
        
    }
        if(!articlesToInsert.isEmpty()){
            insert articlesToInsert;
        }
        if(!categoriesToUpdate.isEmpty()){
        update categoriesToUpdate;
        System.debug('&&&: ' + categoriesToUpdate);
        System.debug('&&&: ' + categoriesToUpdate[0].Last_Synced__c);
        }
}



    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        // TODO: Implement queueable job enqueuing
        // - Determine pages to sync for each category
        // - Create and enqueue NewsCategoryQueueable job for each category
        Integer defaultPageSize = 20;
        Integer startingPage = 1;
        for(News_Category__c category : categoriesToSync) {
            if(String.isNotBlank(category.Name)){
                AsyncOptions options = new AsyncOptions();
                options.MaximumQueueableStackDepth = 5;
                System.enqueueJob(new NewsCategoryQueueable(category.Id, category.Name, defaultPageSize, startingPage), options);
            }
        }
    }
} 