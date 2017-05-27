/**
 * @author Mert YALTI
 * @date 02/06/2017
 * Interface of RestIntegrationHandler 
 */
public interface IRestfullService {
    /**
     * @see  RestIntegrationHandler
     */
    String login(Settings__c integrationSettings,ClientResource client);
    /**
     * @see  RestIntegrationHandler
     */
    Boolean isRunningInSandbox(string endpoint);
    /**
     * @see  RestIntegrationHandler
     */
    String IntegrationRequest(String access_token, String requestBody, String endPoint);
    /**
     * @see  RestIntegrationHandler
     */
    //String externalFieldRequest(String access_token, Map<String,String> requestedObjects, String endPoint);
}