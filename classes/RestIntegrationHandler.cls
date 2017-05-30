/**
 * Rest request handler class
 * Gets Post request from the source org, prepares data to be inserted or updated and handles DML operations
 * @author Mert YALTI
 * @date 01/05/2017
 * @version 1.2
 */
@RestResource(urlMapping = '/transportdata')
global with sharing class RestIntegrationHandler {
	global static Map<String, List<sObject>> processedObject = new Map<String, List<sObject>>();
	global static Map<String, List<TransportResultWrapper>> results = new Map<String, List<TransportResultWrapper>>();
	global static Map<String, Boolean> selfRelation {get; set;}
	global static Set<String> existingIds {get; set;}
	global static Savepoint sp;
	/**
	 * Gets Post request from the source org, prepares data to be inserted or updated and handles DML operations
	 * @return void
	 * @see Http
	 * @see HttpPost
	 * @see RestRequest
	 * @see JSON
	 */
	@HttpPost
	global static void create() {
		existingIds = new Set<String>();
		sp = Database.setSavepoint();
		RestRequest req = RestContext.request;
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		JSONModel des = (JSONModel)JSON.deserialize(req.requestBody.toString(), JSONModel.class);
		Integer orderNo = des.orderNo;
		Map<String, List<sObject>> dataSet = des.dataSet;
		Map<String, Map<Id, String>> rtMappings = des.rtMappings;
		System.debug(loggingLevel.Error, '*** rtMappings: ' + rtMappings);
		Map<Integer, String> priorityMap = des.priorityMap;
		selfRelation = des.selfRelation;
		Map<String, Map<String, String>> externalMappings = des.externalMappings;
		System.debug(loggingLevel.Error, '*** externalMappings: ' + externalMappings);
		Map<String, Map<String, String>> sourceFields = des.sourceFields;
		Map<String, String> sourceToTarget = des.sourceToTarget;
		Integer size = priorityMap.keySet().size();
		//for (Integer i = 1; i <= size; i++) {
		String objectName = priorityMap.get(orderNo);
		Map<String, Id> recordTypeMap = RecordTypes.recordTypeMap(objectName);
		Boolean isSelf = selfRelation.get(objectName);
		String destinationObject = sourceToTarget.get(objectName);
		List<SObject> castRecords;
		List<SObject> clonedRecords;
		Map<String, String> externalMapping;
		Map<String, Schema.SobjectField> fmap;
		if (dataset.containsKey(objectName)) {
			Schema.SObjectType ctype = gd.get(destinationObject);
			fmap = ctype.getDescribe().fields.getMap();
			String listType = 'List<' + ctype + '>';
			castRecords = (List<SObject>)Type.forName(listType).newInstance();
			if (isSelf) clonedRecords = (List<SObject>)Type.forName(listType).newInstance();
			externalMapping = externalMappings.get(objectName);
			System.debug(loggingLevel.Error, '*** externalMapping: ' + externalMapping);
			Map<String, String> fieldMapping = sourceFields.get(objectName);
			for (sObject obj : dataSet.get(objectName)) {
				existingIds.add(String.valueOf(obj.get('Id')));
				sObject record = ctype.newSObject(null, true);
				sObject recordClone = ctype.newSObject(null, true);
				for (String fname : fieldMapping.keySet()) {
					String targetFname = fieldMapping.get(fname);
					if (fmap.containsKey(targetFname) ) {
						Schema.DescribeFieldResult fr = fmap.get(targetFname).getDescribe();
						List<Schema.SObjectType> relatedTo = fr.getReferenceTo();
						if ( fr.isAccessible() && fr.isCreateable()) {
							if (externalMapping.containsKey(fname)) {
								record.put(externalMapping.get(fname), obj.get(fname));
								if (isSelf) recordClone.put(externalMapping.get(fname), obj.get(fname));
							} else if (fr.getType() == DisplayType.REFERENCE && !relatedTo.isEmpty() && fname != 'RecordTypeId') {
								if (relatedTo[0].getDescribe().getName() == 'User') {
									record.put(targetFname, UserInfo.getUserId());
								} else if (isSelf && relatedTo[0].getDescribe().getName() == objectName && externalMappings.containsKey(relatedTo[0].getDescribe().getName())) {
									SObject reference = relatedTo[0].newSObject();
									for (String extS : externalMappings.get(relatedTo[0].getDescribe().getName()).keySet()) {
										reference.put(externalMappings.get(relatedTo[0].getDescribe().getName()).get(extS), obj.get(fname));
										recordClone.putSObject(fmap.get(targetFname).getDescribe().getRelationshipName(), reference);
									}
								} else {
									SObject reference = relatedTo[0].newSObject();
									System.debug(loggingLevel.Error, '*** reference: ' + reference);
									if (!relatedTo.isEmpty() && relatedTo != null && externalMappings.containsKey(relatedTo[0].getDescribe().getName())) {
										for (String extS : externalMappings.get(relatedTo[0].getDescribe().getName()).keySet()) {
											reference.put(externalMappings.get(relatedTo[0].getDescribe().getName()).get(extS), obj.get(fname));
											
											record.putSObject(fmap.get(targetFname).getDescribe().getRelationshipName(), reference);
											if (isSelf) recordClone.putSObject(fmap.get(targetFname).getDescribe().getRelationshipName(), reference);
										}
									}
								}
							} else if (fname == 'RecordTypeId') {
								System.debug(loggingLevel.Error, '*** recordTypeMappingScope: ');
								System.debug(loggingLevel.Error, '*** objectName: ' + objectName);
								System.debug(loggingLevel.Error, '*** recordTypeMap: ' + recordTypeMap);
								System.debug(loggingLevel.Error, '*** rtMappings: ' + rtMappings);
								System.debug(loggingLevel.Error, '*** obj.get(fname): ' + obj.get(fname));
								System.debug(loggingLevel.Error, '*** String.valueOf(recordTypeMap.get(rtMappings.get(objectName).get(String.valueOf(obj.get(fname))))): ' + String.valueOf(recordTypeMap.get(rtMappings.get(objectName).get(String.valueOf(obj.get(fname))))));
								if (rtMappings.containsKey(objectName) && rtMappings.get(objectName).containsKey(String.valueOf(obj.get(fname))) && recordTypeMap.containsKey(rtMappings.get(objectName).get(String.valueOf(obj.get(fname)))))
									record.put('RecordTypeId', String.valueOf(recordTypeMap.get(rtMappings.get(objectName).get(String.valueOf(obj.get(fname))))));
							} else if (!fr.isUnique()) {
								ConvertTypes ct = new ConvertTypes(fmap.get(targetFname));
								ct.putTo(record, String.valueOf(obj.get(fname)));
								if (isSelf) ct.putTo(recordClone, String.valueOf(obj.get(fname)));
							}
						}
					}
				}
				castRecords.add(record);
				if (isSelf) clonedRecords.add(recordClone);
			}
			if (!castRecords.isEmpty()) {
				//System.debug(loggingLevel.Error, '*** castRecords: ' + castRecords);
				RestIntegrationHandler.dmlOperations(castRecords, objectName, externalMapping, fmap);
			}
			if (isSelf && !clonedRecords.isEmpty()) {
				//System.debug(loggingLevel.Error, '*** castRecords: ' + castRecords);
				RestIntegrationHandler.dmlOperations(clonedRecords, objectName, externalMapping, fmap);
			}
		}
		//}
	}
	/**
	 * DML operations are being handled by this method
	 * Since database.upsert requires concerete sObject type this method checks the existance of the data to decide inserting or updating those data
	 * @param  castRecords     Dataset to be used in DML
	 * @param  objectName      Object name to be used in DML
	 * @param  externalMapping External Id mapping to be used in DML
	 * @param  fmap            sObject field map
	 * @return                 void
	 */
	global static void dmlOperations(List<SObject> castRecords, String objectName, Map<String, String> externalMapping, Map<String, Schema.SobjectField> fmap) {
		Set<String> queryField = new Set<String>();
		queryField.add('Id');
		queryField.add(fmap.get(externalMapping.values()[0]).getDescribe().getName());
		List<String> tempStr = new List<String>();
		tempStr.addAll(queryField);
		String fields = String.join(tempStr, ' ,');
		List<sObject> existingData = database.query('SELECT ' + fields + ' FROM ' + objectName + ' WHERE ' + fmap.get(externalMapping.values()[0]) + ' IN: existingIds');
		Set<String> existingExternalIds = new Set<String>();
		Map<String, String> existingMap = new Map<String, String>();
		for (sObject exsObj : existingData) {
			existingExternalIds.add(String.valueOf(exsObj.get(fmap.get(externalMapping.values()[0]))));
			existingMap.put(String.valueOf(exsObj.get(fmap.get(externalMapping.values()[0]))), String.valueOf(exsObj.get('Id')));
		}
		List<sObject> insertList = new List<sObject>();
		List<sObject> updateList = new List<sObject>();
		for (sObject cst : castRecords) {
			if (existingExternalIds.contains(String.valueOf(cst.get(fmap.get(externalMapping.values()[0]))))) {
				cst.put('Id', existingMap.get(String.valueOf(cst.get(fmap.get(externalMapping.values()[0])))));
				updateList.add(cst);
			} else {
				insertList.add(cst);
			}
		}
		List<Database.SaveResult> upsr = new List<Database.SaveResult>();
		try {
			/*if (!String.isBlank(externalMapping.values()[0])) {
				upsr = Database.upsert(castRecords, fmap.get(externalMapping.values()[0]),false);
			} else {
				upsr = Database.upsert(castRecords, false);
			}*/
			if (!insertList.isEmpty()) upsr.addAll(Database.insert(insertList, false));
			if (!updateList.isEmpty()) upsr.addAll(Database.update(updateList, false));
			//processedObject.put(castRecords.getSObjectType().getDescribe().getName(), castRecords);
		} catch (Exception ex) {
			TransportResultWrapper trw = new TransportResultWrapper(objectName, '', 'Fatal Error', 'Migration stopped due to following error: ' + ex.getMessage() + '  => Line No:' + ex.getLineNumber(), false);
			List<TransportResultWrapper> temp = new List<TransportResultWrapper>();
			temp.add(trw);
			results.put('Fatal', temp);
			Database.rollback( sp );
		}
		if (upsr != null) {
			for (Database.SaveResult du : upsr) {
				System.debug(loggingLevel.Error, '*** du.getId(): ' + du.getId());
				if (du.isSuccess()) {
					TransportResultWrapper trw = new TransportResultWrapper(objectName, String.valueOf(du.getId()), 'Success', '', false);
					if (results.containsKey('Success')) {
						List<TransportResultWrapper> temp = results.get('Success');
						temp.add(trw);
						results.put('Success', temp);
					} else {
						List<TransportResultWrapper> temp = new List<TransportResultWrapper>();
						temp.add(trw);
						results.put('Success', temp);
					}
				} else {
					List<String> messages = new List<String>();
					for (Database.Error e : du.getErrors()) {
						messages.add(e.getMessage());
					}
					TransportResultWrapper trw = new TransportResultWrapper(objectName, '', 'Error', String.join(messages, ' / '), false);
					if (results.containsKey('Error')) {
						List<TransportResultWrapper> temp = results.get('Error');
						temp.add(trw);
						results.put('Error', temp);
					} else {
						List<TransportResultWrapper> temp = new List<TransportResultWrapper>();
						temp.add(trw);
						results.put('Error', temp);
					}
				}
			}
		}
		TransportResults tr = new TransportResults();
		tr.JSONWrapper = results;
		RestContext.response.responseBody = Blob.valueOf(JSON.serialize(tr));
	}
	/**
	 * Retrieves accessible fields of requested objects
	 * @return void
	 */
	@HttpGet
	global static void getFields() {
		RestRequest req = RestContext.request;
		Map<String, String> params = req.headers;
		List<TargetFieldWrapper> fieldslist = new List<TargetFieldWrapper>();
		String requestedObject;
		Boolean recordTypeRequest = false;
		for (String k : params.keySet()) {
			if (k == 'ObjectName') {
				requestedObject = params.get(k);
				break;
			}
			if (k == 'request') {
				recordTypeRequest = Boolean.valueOf(params.get(k));
			}
		}
		if (!recordTypeRequest) {
			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
			Schema.SObjectType ctype = gd.get(requestedObject);
			Schema.DescribeSObjectResult sr = ctype.getDescribe();
			Map<String, Schema.SobjectField> fmap = sr.fields.getMap();
			String sobjectName = sr.getName();
			for (String fName : fmap.keySet()) {
				Schema.DescribeFieldResult fr = fmap.get(fName).getDescribe();
				if (fr.isAccessible() && fr.isCreateable()) {
					fieldslist.add(new TargetFieldWrapper(fr.getName(), fr.getSoapType(), fr.isExternalId()));
				}
			}
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(fieldslist));
		} else {
			Map<Id, RecordType> recordTypesMap = new Map<Id, RecordType>();
			recordTypesMap.putAll(RecordTypes.getAllRecordTypes(requestedObject));
			RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new RecordTypeWrapper(recordTypesMap)));
		}
	}
}