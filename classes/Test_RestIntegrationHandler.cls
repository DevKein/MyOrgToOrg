@isTest
public with sharing class Test_RestIntegrationHandler {
	@isTest static void asyncLogin() {
		TestUtil util = new TestUtil();
		Profile p = util.getSystemAdministratorProfile();
		User u = util.userCreate(p.id, 'mock@test.com.migration', 'mock@test.com', 'tester', 'my', 'Avandel Inc');
		Settings__c setting = util.createSetting();
		insert setting;
		RelationEnum a = RelationEnum.PARENT;
		RelationEnum c = RelationEnum.CHILD;
		Map<String, String> header = new Map<String, String>();
		header.put('Accept', 'application/json' );
		header.put('Content-Type', 'application/json; charset=UTF-8');
		header.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
		String accQuery = 'SELECT Name FROM Account LIMIT 1';
		ApexPages.StandardSetController accSST = new ApexPages.StandardSetController(Database.getQueryLocator(accQuery));
		String listViewId = accSST.getListViewOptions()[0].getValue().left(15);
		Migration_Job__c job = new Migration_Job__c();
		job.Name = 'Test Job';
		job.Org_Credential__c = setting.id;
		job.Base_Object_Migration_Rule__c = null;
		job.Send_Notification_Email_On_Complete__c = true;
		job.Notification_Email_Address__c = 'mock@testclass.com';
		job.List_View_Id__c = listViewId;
		insert job;
		Test.startTest();
		RunMigrationJob runner = new RunMigrationJob(job);
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', mockBody , header));
		ClientResource client = new ClientResource(setting.Destination_Org_Username__c, setting.Destination_Org_Password__c, setting.Destination_Org_Security_Token__c);
		runner.login(setting, client);
		Test.stopTest();
	}
	@isTest static void successfulCreate() {
		TestUtil util = new TestUtil();
		Profile p = util.getSystemAdministratorProfile();
		User u = util.userCreate(p.id, 'mock@test.com.migration', 'mock@test.com', 'tester', 'my', 'Avandel Inc');
		Settings__c setting = util.createSetting();
		insert setting;
		Account acc = util.createAccount();
		insert acc;
		System.debug(loggingLevel.Error, '*** acc: ' + JSON.serialize(acc));
		Contact con = util.createContact(acc.id, 'mock@test.com');
		insert con;
		System.debug(loggingLevel.Error, '*** con: ' + JSON.serialize(con));
		List<Migration_Rule__c> rules = new List<Migration_Rule__c>();
		Migration_Rule__c account = new Migration_Rule__c();
		account.Description__c = 'Test migration rule for account';
		account.Is_self_related__c = true;
		account.Source_Object__c = 'Account';
		account.Target_Object__c = 'Account';
		account.Target_Record_Type__c = null;
		account.Callout_Chunk_Size__c = 10;
		rules.add(account);
		Migration_Rule__c contact = new Migration_Rule__c();
		contact.Description__c = 'Test migration rule for contact';
		contact.Is_self_related__c = true;
		contact.Source_Object__c = 'Contact';
		contact.Target_Object__c = 'Contact';
		contact.Target_Record_Type__c = null;
		contact.Callout_Chunk_Size__c = 10;
		rules.add(contact);
		insert rules;
		List<Migration_Rule_Mapping__c> maps = new List<Migration_Rule_Mapping__c>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (Migration_Rule__c mr : rules) {
			Schema.SObjectType ctype = gd.get(mr.Source_Object__c);
			Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
			for (String f : fmap.keySet()) {
				if (f == 'Name') {
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Manuel Entry',
					    Manuel_Entry_Value__c = 'Test Map',
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					maps.add(mp);
				} else {
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Field From Source',
					    Source_Field__c = f,
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					if (fmap.get(f).getDescribe().isExternalID()) {
						mp.Is_ID_Field__c = true;
					}
					if (mp.Is_ID_Field__c == FALSE && f == 'Id') {
						mp.Is_ID_Field__c = TRUE;
					}
					maps.add(mp);
				}
			}
		}
		insert maps;
		Migration_Rule_Relation__c mrr = new Migration_Rule_Relation__c();
		mrr.Master_Migration_Rule__c = account.id;
		mrr.Detail_Migration_Rule__c = contact.id;
		mrr.Description__c = 'Test Account Contact rule relation';
		mrr.Source_Relationship_Name__c = 'Contacts';
		insert mrr;
		String accQuery = 'SELECT Name FROM Account LIMIT 1';
		ApexPages.StandardSetController accSST = new ApexPages.StandardSetController(Database.getQueryLocator(accQuery));
		String listViewId = accSST.getListViewOptions()[0].getValue().left(15);
		Migration_Job__c job = new Migration_Job__c();
		job.Name = 'Test Job';
		job.Org_Credential__c = setting.id;
		job.Base_Object_Migration_Rule__c = account.id;
		job.Send_Notification_Email_On_Complete__c = true;
		job.Notification_Email_Address__c = 'mock@testclass.com';
		job.List_View_Id__c = listViewId;
		insert job;
		List<Migration_Job_Rule_Hierarchy__c> hierarchies = new List<Migration_Job_Rule_Hierarchy__c>();
		Migration_Job_Rule_Hierarchy__c accountH = new Migration_Job_Rule_Hierarchy__c(
		    Migration_Rule__c = account.Id,
		    Migration_Job__c = job.Id,
		    Sort_Order__c = 1
		);
		hierarchies.add(accountH);
		Migration_Job_Rule_Hierarchy__c contactH = new Migration_Job_Rule_Hierarchy__c(
		    Migration_Rule__c = contact.Id,
		    Migration_Job__c = job.Id,
		    Sort_Order__c = 2
		);
		hierarchies.add(contactH);
		insert hierarchies;
		Test.startTest();
		RelationEnum a = RelationEnum.PARENT;
		RelationEnum c = RelationEnum.CHILD;
		Map<String, String> header = new Map<String, String>();
		header.put('Accept', 'application/json' );
		header.put('Content-Type', 'application/json; charset=UTF-8');
		header.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
		RunMigrationJob runner = new RunMigrationJob(job);
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', mockBody , header));
		runner.Run(job, UserInfo.getSessionId());
		ApexPages.StandardController sc = new ApexPages.StandardController(job);
		ResultTrackingController cont = new ResultTrackingController(sc);
		PageReference pageRef = Page.ResultTracking;
		Test.setCurrentPage(pageRef);
		cont.track();
		List<sObject>  sobjectData = runner.getBaseData(accQuery, listViewId);
		runner.isRunningInSandbox(null);
		runner.operationSetup(new Map<Id, Migration_Rule__c> {account.Id => account, contact.Id => contact});
		Test.stopTest();
	}
	@isTest static void successfulCreateStdControl() {
		TestUtil util = new TestUtil();
		Profile p = util.getSystemAdministratorProfile();
		User u = util.userCreate(p.id, 'mock@test.com.migration', 'mock@test.com', 'tester', 'my', 'Avandel Inc');
		Settings__c setting = util.createSetting();
		insert setting;
		Account acc = util.createAccount();
		insert acc;
		System.debug(loggingLevel.Error, '*** acc: ' + JSON.serialize(acc));
		Contact con = util.createContact(acc.id, 'mock@test.com');
		insert con;
		System.debug(loggingLevel.Error, '*** con: ' + JSON.serialize(con));
		List<Migration_Rule__c> rules = new List<Migration_Rule__c>();
		Migration_Rule__c account = new Migration_Rule__c();
		account.Description__c = 'Test migration rule for account';
		account.Is_self_related__c = true;
		account.Source_Object__c = 'Account';
		account.Target_Object__c = 'Account';
		account.Target_Record_Type__c = null;
		account.Callout_Chunk_Size__c = 10;
		rules.add(account);
		Migration_Rule__c contact = new Migration_Rule__c();
		contact.Description__c = 'Test migration rule for contact';
		contact.Is_self_related__c = true;
		contact.Source_Object__c = 'Contact';
		contact.Target_Object__c = 'Contact';
		contact.Target_Record_Type__c = null;
		contact.Callout_Chunk_Size__c = 10;
		rules.add(contact);
		insert rules;
		List<Migration_Rule_Mapping__c> maps = new List<Migration_Rule_Mapping__c>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (Migration_Rule__c mr : rules) {
			Schema.SObjectType ctype = gd.get(mr.Source_Object__c);
			Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
			for (String f : fmap.keySet()) {
				if (f == 'Name') {
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Manuel Entry',
					    Manuel_Entry_Value__c = 'Test Map',
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					maps.add(mp);
				} else {
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Field From Source',
					    Source_Field__c = f,
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					if (fmap.get(f).getDescribe().isExternalID()) {
						mp.Is_ID_Field__c = true;
					}
					if (mp.Is_ID_Field__c == FALSE && f == 'Id') {
						mp.Is_ID_Field__c = TRUE;
					}
					maps.add(mp);
				}
			}
		}
		insert maps;
		Migration_Rule_Relation__c mrr = new Migration_Rule_Relation__c();
		mrr.Master_Migration_Rule__c = account.id;
		mrr.Detail_Migration_Rule__c = contact.id;
		mrr.Description__c = 'Test Account Contact rule relation';
		mrr.Source_Relationship_Name__c = 'Contacts';
		insert mrr;
		String accQuery = 'SELECT Name FROM Account LIMIT 1';
		ApexPages.StandardSetController accSST = new ApexPages.StandardSetController(Database.getQueryLocator(accQuery));
		String listViewId = accSST.getListViewOptions()[0].getValue().left(15);
		Migration_Job__c job = new Migration_Job__c();
		job.Name = 'Test Job';
		job.Org_Credential__c = setting.id;
		job.Base_Object_Migration_Rule__c = account.id;
		job.Send_Notification_Email_On_Complete__c = true;
		job.Notification_Email_Address__c = 'mock@testclass.com';
		job.List_View_Id__c = listViewId;
		insert job;
		List<Migration_Job_Rule_Hierarchy__c> hierarchies = new List<Migration_Job_Rule_Hierarchy__c>();
		Migration_Job_Rule_Hierarchy__c accountH = new Migration_Job_Rule_Hierarchy__c(
		    Migration_Rule__c = account.Id,
		    Migration_Job__c = job.Id,
		    Sort_Order__c = 1
		);
		hierarchies.add(accountH);
		Migration_Job_Rule_Hierarchy__c contactH = new Migration_Job_Rule_Hierarchy__c(
		    Migration_Rule__c = contact.Id,
		    Migration_Job__c = job.Id,
		    Sort_Order__c = 2
		);
		hierarchies.add(contactH);
		insert hierarchies;
		Test.startTest();
		RelationEnum a = RelationEnum.PARENT;
		RelationEnum c = RelationEnum.CHILD;
		Map<String, String> header = new Map<String, String>();
		header.put('Accept', 'application/json' );
		header.put('Content-Type', 'application/json; charset=UTF-8');
		header.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
		ApexPages.StandardController sc = new ApexPages.StandardController(job);
		RunMigrationJob runner = new RunMigrationJob(sc);
		PageReference pageRef = Page.ResultTracking;
		Test.setCurrentPage(pageRef);
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', mockBody , header));
		runner.recordTypeSetup();
		List<sObject>  sobjectData = runner.getBaseData(accQuery, listViewId);
		runner.isRunningInSandbox(null);
		runner.operationSetup(new Map<Id, Migration_Rule__c> {account.Id => account, contact.Id => contact});
		runner.runNow();
		Test.stopTest();
	}
	@isTest static void RecordTypesTest() {
		RecordTypes.recordTypeMap(new Set<String> {'Account', 'Contact'}, new Set<String>());
		RecordTypes.getAllRecordTypes('Account');
		RecordTypes.recordTypeMap('Account');
		RecordTypes.getRtByName('NoType',new Map<Id,RecordType>());
	}
	@isTest static void asyncSuccessfulCreate() {
		TestUtil util = new TestUtil();
		Profile p = util.getSystemAdministratorProfile();
		User u = util.userCreate(p.id, 'mock@test.com.migration', 'mock@test.com', 'tester', 'my', 'Avandel Inc');
		Settings__c setting = util.createSetting();
		insert setting;
		Account acc = util.createAccount();
		insert acc;
		System.debug(loggingLevel.Error, '*** acc: ' + JSON.serialize(acc));
		Contact con = util.createContact(acc.id, 'mock@test.com');
		insert con;
		System.debug(loggingLevel.Error, '*** con: ' + JSON.serialize(con));
		List<Migration_Rule__c> rules = new List<Migration_Rule__c>();
		Migration_Rule__c account = new Migration_Rule__c();
		account.Description__c = 'Test migration rule for account';
		account.Is_self_related__c = true;
		account.Source_Object__c = 'Account';
		account.Target_Object__c = 'Account';
		account.Target_Record_Type__c = null;
		account.Callout_Chunk_Size__c = 10;
		rules.add(account);
		Migration_Rule__c contact = new Migration_Rule__c();
		contact.Description__c = 'Test migration rule for contact';
		contact.Is_self_related__c = true;
		contact.Source_Object__c = 'Contact';
		contact.Target_Object__c = 'Contact';
		contact.Target_Record_Type__c = null;
		contact.Callout_Chunk_Size__c = 10;
		rules.add(contact);
		insert rules;
		List<Migration_Rule_Mapping__c> maps = new List<Migration_Rule_Mapping__c>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (Migration_Rule__c mr : rules) {
			Schema.SObjectType ctype = gd.get(mr.Source_Object__c);
			Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
			for (String f : fmap.keySet()) {
				if (f == 'Name') {
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Manuel Entry',
					    Manuel_Entry_Value__c = 'Test Map',
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					maps.add(mp);
				} else {
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Field From Source',
					    Source_Field__c = f,
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					if (fmap.get(f).getDescribe().isExternalID()) {
						mp.Is_ID_Field__c = true;
					}
					maps.add(mp);
				}
			}
		}
		insert maps;
		Migration_Rule_Relation__c mrr = new Migration_Rule_Relation__c();
		mrr.Master_Migration_Rule__c = account.id;
		mrr.Detail_Migration_Rule__c = contact.id;
		mrr.Description__c = 'Test Account Contact rule relation';
		mrr.Source_Relationship_Name__c = 'Contacts';
		insert mrr;
		String accQuery = 'SELECT Name FROM Account LIMIT 1';
		ApexPages.StandardSetController accSST = new ApexPages.StandardSetController(Database.getQueryLocator(accQuery));
		String listViewId = accSST.getListViewOptions()[0].getValue().left(15);
		Migration_Job__c job = new Migration_Job__c();
		job.Name = 'Test Job';
		job.Org_Credential__c = setting.id;
		job.Base_Object_Migration_Rule__c = account.id;
		job.Send_Notification_Email_On_Complete__c = true;
		job.Notification_Email_Address__c = 'mock@testclass.com';
		job.List_View_Id__c = listViewId;
		insert job;
		List<Migration_Job_Rule_Hierarchy__c> hierarchies = new List<Migration_Job_Rule_Hierarchy__c>();
		Migration_Job_Rule_Hierarchy__c accountH = new Migration_Job_Rule_Hierarchy__c(
		    Migration_Rule__c = account.Id,
		    Migration_Job__c = job.Id,
		    Sort_Order__c = 1
		);
		hierarchies.add(accountH);
		Migration_Job_Rule_Hierarchy__c contactH = new Migration_Job_Rule_Hierarchy__c(
		    Migration_Rule__c = contact.Id,
		    Migration_Job__c = job.Id,
		    Sort_Order__c = 2
		);
		hierarchies.add(contactH);
		insert hierarchies;
		Test.startTest();
		RelationEnum a = RelationEnum.PARENT;
		RelationEnum c = RelationEnum.CHILD;
		Map<String, String> header = new Map<String, String>();
		header.put('Accept', 'application/json' );
		header.put('Content-Type', 'application/json; charset=UTF-8');
		header.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"orderNo":1,"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', mockBody , header));
		ListviewOperations.getListViewQuery('Account', listViewId);
		RunWebService.run(job.id);
		Test.stopTest();
	}
	@isTest static void successful() {
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"orderNo":1,"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		RestResponse res = new RestResponse();
		RestRequest req = new RestRequest();
		req.requestURI = '/services/apexrest/transportdata';
		req.addHeader('Content-Type', 'JSON');
		req.requestBody = Blob.valueOf(mockBody);
		req.httpMethod = 'POST';
		RestContext.request = req;
		System.assertEquals(req.httpMethod, 'POST');
		RestContext.response = res;
		RestIntegrationHandler.create();
		String mockBody2 = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"orderNo":2,"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		RestResponse res2 = new RestResponse();
		RestRequest req2 = new RestRequest();
		req2.requestURI = '/services/apexrest/transportdata';
		req2.addHeader('Content-Type', 'JSON');
		req2.requestBody = Blob.valueOf(mockBody2);
		req2.httpMethod = 'POST';
		RestContext.request = req2;
		System.assertEquals(req2.httpMethod, 'POST');
		RestContext.response = res2;
		RestIntegrationHandler.create();
	}
	@isTest static void directRequest() {
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":"Name"},"Contact":{"FirstName":"FirstName","LastName":"LastName","AccountId":"AccountId","Email":"Email"}},"orderNo":1,"selfRelation":{"Contact":false,"Account":true},"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		Map<String, String> header = new Map<String, String>();
		header.put('Accept', 'application/json' );
		header.put('Content-Type', 'application/json; charset=UTF-8');
		header.put('Authorization', 'OAuth ' + UserInfo.getSessionId());
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', mockBody , header));
		String accQuery = 'SELECT Name FROM Account LIMIT 1';
		ApexPages.StandardSetController accSST = new ApexPages.StandardSetController(Database.getQueryLocator(accQuery));
		String listViewId = accSST.getListViewOptions()[0].getValue().left(15);
		Migration_Job__c job = new Migration_Job__c();
		job.Name = 'Test Job';
		job.Org_Credential__c = null;
		job.Base_Object_Migration_Rule__c = null;
		job.Send_Notification_Email_On_Complete__c = true;
		job.Notification_Email_Address__c = 'mock@testclass.com';
		job.List_View_Id__c = listViewId;
		insert job;
		test.startTest();
		RunMigrationJob runner = new RunMigrationJob(job);
		runner.IntegrationRequest('TestAccessToken', mockBody, String.valueOf(System.URL.getSalesforceBaseUrl()));
		test.stopTest();
	}
	@isTest static void failure() {
		String mockBody = '{"sourceToTarget":{"Account":"Account","Contact":"Contact"},"sourceFields":{"Account":{"Name":""},"Contact":{"FirstName":"FirstName","LastName":"LastName","Email":"Email"}},"selfRelation":{"Contact":false,"Account":true},"orderNo":1,"priorityMap":{"1":"Account","2":"Contact"},"externalMappings":{"Account":{"Id":"Id"},"Contact":{"Id":"Id"}},"dataSet":{"Account":[{"attributes":{"type":"Account","url":"/services/data/v39.0/sobjects/Account/0010Y00000PYegQQAT"},"Name":"Test Account","Id":"0010Y00000PYegQQAT"}],"Contact":[{"attributes":{"type":"Contact","url":"/services/data/v39.0/sobjects/Contact/0030Y00000LqWyoQAF"},"FirstName":"Test","LastName":"Contact","AccountId":"0010Y00000PYegQQAT","Email":"mock@test.com","Id":"0030Y00000LqWyoQAF"}]}}';
		RestResponse res = new RestResponse();
		RestRequest req = new RestRequest();
		req.requestURI = '/services/apexrest/transportdata';
		req.addHeader('Content-Type', 'JSON');
		req.requestBody = Blob.valueOf(mockBody);
		req.httpMethod = 'POST';
		RestContext.request = req;
		System.assertEquals(req.httpMethod, 'POST');
		RestContext.response = res;
		RestIntegrationHandler.create();
	}
	@isTest static void typeConversion() {
		TestUtil util = new TestUtil();
		Account acc = util.createAccount();
		insert acc;
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType ctype = gd.get('Account');
		Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
		ConvertTypes sct = new ConvertTypes(fmap.get('NumberOfEmployees'));
		sct.putTo(acc, String.valueOf('35'));
		Contact con = util.createContact(acc.id, 'mock@test.com');
		insert con;
		Schema.SObjectType contype = gd.get('Contact');
		fmap = contype.getDescribe().fields.getMap();
		sct = new ConvertTypes(fmap.get('Birthdate'));
		sct.putTo(con, String.valueOf(system.today()));
		sct = new ConvertTypes(fmap.get('HasOptedOutOfEmail'));
		sct.putTo(con, String.valueOf('false'));
		sct = new ConvertTypes(fmap.get('CreatedDate'));
		DoubleConverter dc = new DoubleConverter();
		dc.getValue('3.2');
		DatetimeConverter dtc = new DatetimeConverter();
		dtc.getValue(String.valueOf(Datetime.now()));
	}
	@isTest static void failedTypeConversion() {
		DoubleConverter dc = new DoubleConverter();
		dc.getValue('Fail');
		DatetimeConverter dtc = new DatetimeConverter();
		dtc.getValue('Fail');
		DateConverter dcf = new DateConverter();
		dcf.getValue('Fail');
		IntegerConverter ic = new IntegerConverter();
		ic.getValue('Fail');
		BooleanConverter bc = new BooleanConverter();
		bc.getValue('NotBoolean');
	}

	@isTest static void mockCallout() {
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setBody('Hello world');
		req.setMethod('POST');
		req.setEndpoint('login.salesforce.com/services/oauth2/token');
		Test_MockLoginCallout call = new Test_MockLoginCallout(200, 'OK', '', new Map<String, String>());
		call.respond(req);
	}
	@isTest static void testJsonOperations() {
		String emptyJSON = JSONOperations.generateExternalJSON(new Map<String, List<sObject>>(), new Map<Integer, String>(), new Map<String, Boolean>(), new Map<String, Map<String, String>>(), new Map<String, Map<String, String>>(), new Map<String, String>(), 1, new Map<String, Map<Id, String>>());
	}
}