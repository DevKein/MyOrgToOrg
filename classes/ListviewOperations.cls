public with sharing class ListviewOperations {

    public static HttpResponse restAPICall (String endPoint) {
        String SessionId = UserInfo.getSessionId();
        System.debug(loggingLevel.Error, '*** SessionId: ' + SessionId);
        if(SessionId != null){
            HttpRequest req = new HttpRequest();
            endpoint = System.URL.getSalesforceBaseUrl().toExternalForm() + endPoint;
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json' );
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('Authorization', 'OAuth ' + SessionId);
            Http http = new Http();
            HTTPResponse res = http.send(req);

            return res;
        }
        return null;
    }
    public static HttpResponse restAPICall (String endPoint, String SessionId) {
        System.debug(loggingLevel.Error, '*** SessionId: ' + SessionId);
        if(SessionId != null){
            HttpRequest req = new HttpRequest();
            endpoint = System.URL.getSalesforceBaseUrl().toExternalForm() + endPoint;
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json' );
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('Authorization', 'OAuth ' + SessionId);
            Http http = new Http();
            HTTPResponse res = http.send(req);

            return res;
        }
        return null;
    }
    public static HttpResponse restAPICall (String endPoint, String param1, String param2) {
        endPoint = endPoint.replace('[param1]', param1 == null ? '' : param1);
        endPoint = endPoint.replace('[param2]', param2 == null ? '' : param2);
        return restAPICall(endPoint);
    }
    public static HttpResponse restAPICall (String endPoint, String param1, String param2, String SessionId) {
        endPoint = endPoint.replace('[param1]', param1 == null ? '' : param1);
        endPoint = endPoint.replace('[param2]', param2 == null ? '' : param2);
        return restAPICall(endPoint,SessionId);
    }

    //returns SOQL queri of given object and listViewName
    public static String getListViewQuery (String obJectName, Id listViewId) {

        String lvQuery;
        if (listViewID != null) {
            HTTPResponse res = restAPICall('/services/data/v32.0/sobjects/[param1]/listviews/[param2]/describe', obJectName, listViewId);
            if(res != null){
                JSONParser parser = JSON.createParser(res.getBody());
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                lvQuery = string.valueOf(m.get('query'));
                system.debug('res:' + res);
            }
            else{
                return '';
            }
        }

        return lvQuery;
    }
    public static String getListViewQuery (String obJectName, Id listViewId, String SessionId) {

        String lvQuery;
        if (listViewID != null && SessionId != null) {
            HTTPResponse res = restAPICall('/services/data/v32.0/sobjects/[param1]/listviews/[param2]/describe', obJectName, listViewId, SessionId);
            if(res != null){
                JSONParser parser = JSON.createParser(res.getBody());
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                lvQuery = string.valueOf(m.get('query'));
                system.debug('res:' + res);
            }
            else{
                return '';
            }
        }

        return lvQuery;
    }
}