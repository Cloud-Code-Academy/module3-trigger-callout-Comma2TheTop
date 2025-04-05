HttpResponse res = NewsAPIService.makeCallout('callout:NewsAPI/v2/top-headlines?country=us&category=technology&pageSize=10&page=1');
System.debug('Response Body: ' + res.getBody());

