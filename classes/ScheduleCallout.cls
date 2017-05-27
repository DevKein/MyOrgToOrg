global class ScheduleCallout implements Schedulable {
	global Set<String> whereIds {get; set;}
	global Map<Integer, String> orderedMap {get; set;}
	global Map<Id, Migration_Rule__c> migrationRules {get; set;}
	global Map<String, Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>>> MRRelationsMap {get; set;}
	global Map<String, Map<String, String>> literalValues {get; set;}
	global String query {get; set;}
	global Map<Integer, String> dmlPriorityMap {get; set;}
	global Map<String, Map<String, String>> externalMappings {get; set;}
	global Map<String, Boolean> selfRelation {get; set;}
	global Map<String, Map<String, String>> sourceFields {get; set;}
	global Map<String, String> sourceToTarget {get; set;}
	global Migration_Job__c job {get; set;}
	global Integer orderNo {get; set;}
	global Boolean startIntegration {get; set;}
	public Map<String, List<sObject>> objectData {get; set;}
	public Map<String, Integer> chunckSizeMap {get; set;}
	public Map<String, Map<Id, String>> rtMappings {get;set;}
	public ScheduleCallout(Map<String, List<sObject>> objectData, Boolean startIntegration, Integer orderNo, Migration_Job__c job, String query, Set<String> whereIds, Map<Integer, String> orderedMap, Map<Id, Migration_Rule__c> migrationRules, Map<String, Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>>> MRRelationsMap, Map<String, Map<String, String>> literalValues, Map<Integer, String> dmlPriorityMap, Map<String, Boolean> selfRelation, Map<String, Map<String, String>> externalMappings, Map<String, Map<String, String>> sourceFields, Map<String, String> sourceToTarget, Map<String, Integer> chunckSizeMap,Map<String, Map<Id, String>> rtMappings) {
		this.query = query;
		this.whereIds = whereIds;
		this.orderedMap = orderedMap;
		this.migrationRules = migrationRules;
		this.MRRelationsMap = MRRelationsMap;
		this.selfRelation = selfRelation;
		this.literalValues = literalValues;
		this.dmlPriorityMap = dmlPriorityMap;
		this.sourceFields = sourceFields;
		this.externalMappings = externalMappings;
		this.sourceToTarget = sourceToTarget;
		this.job = job;
		this.orderNo = orderNo;
		this.startIntegration = startIntegration;
		this.objectData = objectData;
		this.chunckSizeMap = chunckSizeMap;
		this.rtMappings = rtMappings;
	}
	global void execute(SchedulableContext sc) {
		System.debug(loggingLevel.Error, '*** chunckSizeMap: ' + chunckSizeMap);
		if (!startIntegration) {
			BatchCallout b = new BatchCallout(objectData, startIntegration, orderNo, job, query, whereIds, orderedMap, migrationRules, MRRelationsMap, literalValues, dmlPriorityMap, selfRelation, externalMappings, sourceFields, sourceToTarget, chunckSizeMap,rtMappings);
			database.executebatch(b);
			System.abortJob(sc.getTriggerId());
		}else{
			String objectName = orderedMap.get(orderNo);
			System.debug(loggingLevel.Error, '*** objectName: ' + objectName);
			Integer chunckSize = chunckSizeMap.get(objectName);
			System.debug(loggingLevel.Error, '*** chunckSize: ' + chunckSize);
			BatchCallout b = new BatchCallout(objectData, startIntegration, orderNo, job, query, whereIds, orderedMap, migrationRules, MRRelationsMap, literalValues, dmlPriorityMap, selfRelation, externalMappings, sourceFields, sourceToTarget, chunckSizeMap,rtMappings);
			database.executebatch(b,chunckSize);
			System.abortJob(sc.getTriggerId());
		}
	}
}