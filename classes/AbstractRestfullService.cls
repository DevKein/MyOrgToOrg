/**
 * @author Mert YALTI
 * @date 02/06/2017
 * @see IRestfullService
 * Abstract class for general integration steps like Login,Get,Post requests
 */
public abstract class AbstractRestfullService implements IRestfullService{
    private final String NS_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/'; // SOAP envelop url
    private final String NS_SF = 'urn:partner.soap.sforce.com'; // SOAP SFDC urn
    private String clientId;
    private String clientSecret;
    private String username;
    private String password;
    private String endPoint;
    private OAuthWrapper authResult;
    /**
     * Sends login request to destination org and retrieves access_token from the connected app.
     * @param  integrationSettings Pre-defined settings to be used
     * @param  client              Client credentials
     * @see ClientResource
     * @return                     String access token
     */
    public String login(Settings__c integrationSettings,ClientResource client) {
        clientId = integrationSettings.Connected_App_Client_Id__c;//'3MVG9A2kN3Bn17huuJlHc.XjLIxb2mXSAA6Rmt_2ndH5fZ7HxTLM9CXzfOiwBjV4kZN7uMIE3VpNx69Qo8GiE';
        clientSecret = integrationSettings.Connected_App_Client_Secret__c;//'5668655138706191715 ';
        endPoint = integrationSettings.Destination_Endpoint__c;
        username = client.userName;
        password = client.password+client.token;

        String reqbody = 'grant_type=password&client_id=' + clientId + '&client_secret=' + clientSecret + '&username=' + username + '&password=' + password;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqbody);
        req.setMethod('POST');
        if (!String.isBlank(integrationSettings.Destination_Endpoint__c)) {
            req.setEndpoint(endPoint + '/services/oauth2/token');
        } else if (!isRunningInSandbox(endPoint)) {
            req.setEndpoint('login.salesforce.com/services/oauth2/token');
        } else {
            req.setEndpoint('test.salesforce.com/services/oauth2/token');
        }
        System.debug(loggingLevel.Error, '*** req.getBody(): ' + req.getBody());
        HttpResponse res = h.send(req);
        System.debug(loggingLevel.Error, '*** res: ' + res);
        System.debug(loggingLevel.Error, '*** res.getbody(): ' + res.getbody());
        authResult = (OAuthWrapper)JSON.deserialize(res.getbody(), OAuthWrapper.class);
        return authResult.access_token;
    }
    
    /**
     * Sends integration request to destination org by using oAuth access token and the created json string
     * @param  access_token oAuth Access token
     * @param  requestBody  JSON request body
     * @param  ep           destination end point
     * @return              String status
     */
    public String IntegrationRequest(String access_token, String requestBody, String ep) {
        if (!String.isBlank(access_token)) {
            Http carrier = new Http();
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + access_token);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('accept', 'application/json');
            req.setBody(requestBody);
            req.setTimeout(120000);
            req.setMethod('POST');
            System.debug(loggingLevel.Error, '*** req: ' + req);
            if(!String.isBlank(endPoint)){
                req.setEndpoint(endPoint + '/services/apexrest/MigrateTHIS/transportdata');
            }
            else{
                req.setEndpoint(ep + '/services/apexrest/MigrateTHIS/transportdata');
            }
            
            HttpResponse res = carrier.send(req);
            System.debug(loggingLevel.Error, '*** res: ' + res);
            return res.getBody();
        }
        return 'Failed';
    }
    /**
     * Sends field list retrieval request to destination org.
     * @param  access_token     oAuth Access Token
     * @param  requestedObjects Object order to Object name map
     * @param  ep               Request end point
     * @return                  String response body.
     */
    public String FieldRequest(String access_token, String requestedObject, String ep, Boolean isRt) {
        if (!String.isBlank(access_token)) {
            Http carrier = new Http();
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + access_token);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('accept', 'application/json');            
            req.setHeader('ObjectName', requestedObject);
            req.setHeader('request', String.valueOf(isRt));
                  
            req.setMethod('GET');
            if(!String.isBlank(endPoint)){
                req.setEndpoint(endPoint + '/services/apexrest/MigrateTHIS/transportdata');
            }
            else{
                req.setEndpoint(ep + '/services/apexrest/MigrateTHIS/transportdata');
            }
            HttpResponse res = carrier.send(req);
            return res.getBody();
        }
        return '401 !!Unauthorized';
    }
    /**
     * Checks the enpoint end returns the org type (Sandbox or not)
     * @param  endPoint End point URL
     * @return          True if sandbox.
     */
    public Boolean isRunningInSandbox(string endPoint) {
        String s;
        if(String.isBlank(endPoint)){
            s  =  System.URL.getSalesforceBaseUrl().getHost();
        }
        else{
            s = endPoint;
        }
        return (Pattern.matches('(.*\\.)?cs[0-9]*(-api)?\\..*force.com', s));
    }
    /**
     * oAuth login request results wrapper.
     */
    public class OAuthWrapper{
        public String issued_at {get; set;}
        public String instance_url {get; set;}
        public String signature {get; set;}
        public String id {get; set;}
        public String access_token {get; set;}
    }
}