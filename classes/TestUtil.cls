/**
 * @author Mert YALTI
 * @date 02/07/2017
 * Unit test common utility class
 */
public class TestUtil{
    /**
     * Queries system admin profile
     * @return Profile
     */
    public Profile getSystemAdministratorProfile(){
        Profile profileAdmin = [select Id,Name From Profile Where Name = 'System Administrator' limit 1];
        return profileAdmin;     
    }
    /**
     * Creates instance of a user
     * @param  profileId   User's profileId
     * @param  userName    Username (should be in email format)
     * @param  email       Valid email address.
     * @param  nickName    Nickname
     * @param  alias       Username alias
     * @param  companyName User's employer (company) name
     * @return             User
     */
    public User userCreate (Id profileId, String userName, String email, String nickName, String alias, String companyName){
        User u=new User();
        u.Username= userName;
        u.LastName='UserT';
        u.FirstName='Test';
        u.City='SanFran';
        u.Email=email;
        u.Alias=alias;
        u.CommunityNickname=nickName;
        u.EmailEncodingKey='UTF-8';
        u.languagelocalekey='en_US';
        u.ProfileId=profileId;
        u.timezonesidkey='America/Los_Angeles';
        u.localesidkey='en_US';
        u.CompanyName=companyName;
        return u;   
    }
    /**
     * Creates instance of a Org To Org migration setting
     * @return Settings
     */
    public Settings__c createSetting(){
        Settings__c setting = new Settings__c();
        setting.Name = 'Test';
        setting.Connected_App_Client_Id__c ='testClientId';
        setting.Connected_App_Client_Secret__c = 'testClientSecret';
        setting.Destination_Endpoint__c = 'test.salesforce.com';
        return setting;
    }
    /**
     * Creates simple instance of an Account
     * @return Account
     */
    public Account createAccount(){
        return new Account(Name='Test Account');
    }
    /**
     * Creates simple instance of a Contact
     * @param  accountId Parent Account ID
     * @param  email     Email address
     * @return           Contact
     */
    public Contact createContact(String accountId,String email){
        return new Contact(FirstName='Test',LastName='Contact',AccountId = accountId,Email = email);
    }
}