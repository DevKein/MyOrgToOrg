@isTest
private class FieldMappingController_Test {
	
	@isTest static void test_method_one() {
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
		List<TargetFieldWrapper> wrapperList = new List<TargetFieldWrapper>();
		Map<String,SoapType> testTargetFields = new Map<String,SoapType>(); 
		for (Migration_Rule__c mr : rules) {
			Schema.SObjectType ctype = gd.get(mr.Source_Object__c);
			Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
			for (String f : fmap.keySet()) {
				testTargetFields.put(f,fmap.get(f).getDescribe().getSoapType());
				
				if (f == 'Name') {
					TargetFieldWrapper a = new TargetFieldWrapper(f, fmap.get(f).getDescribe().getSoapType());
					wrapperList.add(a);
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Manuel Entry',
					    Manuel_Entry_Value__c = 'Test Map',
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					maps.add(mp);
				} else {
					TargetFieldWrapper a = new TargetFieldWrapper(f, fmap.get(f).getDescribe().getSoapType(), fmap.get(f).getDescribe().isExternalID());
					wrapperList.add(a);
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
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
		FieldMappingController cont = new FieldMappingController(sc);
		PageReference pageRef = Page.FieldMapping;
		Test.setCurrentPage(pageRef);
		system.debug('mmmmmm=>'+JSON.serialize(wrapperList));
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', JSON.serialize(wrapperList), new Map<String,String>{'ObjectName' => 'Account'}));
		cont.selectedSetting = setting.id;
		cont.retrieveSourceFields();
		cont.retrieveTargetFields();
		cont.targetFields.putAll(testTargetFields);
		cont.targetFieldsState.putAll(testTargetFields);
		cont.sourceFields.putAll(testTargetFields);
		ApexPages.currentPage().getParameters().put('sourceField','Id');
        ApexPages.currentPage().getParameters().put('order','1');
		cont.remove();
		ApexPages.currentPage().getParameters().put('from','Name');
        ApexPages.currentPage().getParameters().put('to','Name');

		cont.autoMapping();
		cont.resetMapping();
		cont.autoMapping();
		cont.SaveState();
		cont.autoMapping();
		cont.remove();
		cont.setMapping();
		cont.setMapping();
		cont.closeModal();
		cont.clearAll();
		cont.autoMapping();
		cont.SaveState();
		ApexPages.currentPage().getParameters().put('sourceField','Id');
        ApexPages.currentPage().getParameters().put('order','1');
		cont.remove();
		ApexPages.currentPage().getParameters().put('manualField','Name');
        ApexPages.currentPage().getParameters().put('manualVal','Test');
        cont.saveManualValue();
        cont.SaveState();
		CheckTypeCompability.check('String','String');

		Test.stopTest();
	}
	@isTest static void test_method_two() {
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
		List<TargetFieldWrapper> wrapperList = new List<TargetFieldWrapper>();
		for (Migration_Rule__c mr : rules) {
			Schema.SObjectType ctype = gd.get(mr.Source_Object__c);
			Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
			for (String f : fmap.keySet()) {
				
				if (f == 'Name') {
					TargetFieldWrapper a = new TargetFieldWrapper(f, fmap.get(f).getDescribe().getSoapType());
					wrapperList.add(a);
					Migration_Rule_Mapping__c mp = new Migration_Rule_Mapping__c(
					    Migration_Rule__c = mr.id,
					    Migration_Type__c = 'Manuel Entry',
					    Manuel_Entry_Value__c = 'Test Map',
					    Target_Field__c = f,
					    Destination_Org__c = setting.id
					);
					maps.add(mp);
				} else {
					TargetFieldWrapper a = new TargetFieldWrapper(f, fmap.get(f).getDescribe().getSoapType(), fmap.get(f).getDescribe().isExternalID());
					wrapperList.add(a);
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
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
		FieldMappingController cont = new FieldMappingController(sc);
		PageReference pageRef = Page.FieldMapping;
		Test.setCurrentPage(pageRef);
		system.debug('mmmmmm=>'+JSON.serialize(wrapperList));
		Test.setMock(HttpCalloutMock.class, new Test_MockLoginCallout(200, 'OK', JSON.serialize(wrapperList), new Map<String,String>{'ObjectName' => 'Account','request' => 'true'}));
		cont.selectedSetting = setting.id;
		cont.retrieveSourceFields();
		cont.retrieveTargetFields();
		cont.retrieveTargetRecordTypes();
		ApexPages.currentPage().getParameters().put('from',job.id);
        ApexPages.currentPage().getParameters().put('to',job.id);
        cont.sourceRecordTypes.put(job.Id , null);
		cont.setRtMapping();
		cont.saveRecordTypeMapping();
		ApexPages.currentPage().getParameters().put('sourceField','Id');
        ApexPages.currentPage().getParameters().put('order','1');
		cont.removeRT();
		cont.setRTWrapperforTest('test', 'test', job.id, 'test', job.id);
		RecordTypeWrapper a = new RecordTypeWrapper(new Map<Id,RecordType>{job.Id => null});
		String mockBody = JSON.serialize(wrapperList);
		RestResponse res = new RestResponse();
		RestRequest req = new RestRequest();
		req.requestURI = '/services/apexrest/MigrateTHIS/transportdata';
		req.addHeader('Content-Type', 'JSON');
		req.addHeader('ObjectName', 'Account');
		req.addHeader('request', 'false');
		req.requestBody = Blob.valueOf(mockBody);
		req.httpMethod = 'GET';
		RestContext.request = req;
		System.assertEquals(req.httpMethod, 'GET');
		RestContext.response = res;
		RestIntegrationHandler.getFields();
		Test.stopTest();
	}
	@isTest static void restService(){

	}
}