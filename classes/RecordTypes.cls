public with sharing class RecordTypes {
	public static Map<String, List<RecordType>> rtMap {get; set;}
	public static Map<ID,RecordType> singleRtMap {get;set;}
	public static Map<String,RecordType> nameToRTMap {get;set;}

	public static Map<String, List<RecordType>> recordTypeMap(Set<String> sObjectnames,Set<String> rtNames) {
		rtMap = new Map<String, List<RecordType>>();
		for ( RecordType rt : [Select DeveloperName, Id, SObjectType,Name FROM RecordType WHERE sObjectType IN: sObjectnames AND (DeveloperName IN:rtNames OR Name IN:rtNames)] ) {
			if (sObjectnames.contains(rt.sObjectType)) {
				if (rtMap.containsKey(rt.sObjectType)) {
					List<RecordType> temp = rtMap.get(rt.sObjectType);
					temp.add(rt);
					rtMap.put(rt.sObjectType, temp);
				} else {
					List<RecordType> temp = new List<RecordType>();
					temp.add(rt);
					rtMap.put(rt.sObjectType, temp);
				}
			}
		}
		return rtMap;
	}
	public static Map<ID,RecordType> getAllRecordTypes(String sObjectname) {
		singleRtMap = new Map<Id,RecordType>([Select Id, DeveloperName, SObjectType, Name FROM RecordType WHERE sObjectType =: sObjectname]);
		
		return singleRtMap;
	}
	public static Map<String, Id> recordTypeMap(String sObjectName) {
		Map<String,Id> destinationRtMap = new Map<String,Id>();
		for ( RecordType rt : [Select DeveloperName, Id, SObjectType,Name FROM RecordType WHERE sObjectType =: sObjectName] ) {
			destinationRtMap.put(rt.DeveloperName,rt.Id);
		}
		return destinationRtMap;
	}
	public static RecordType getRtByName(String rtName,Map<ID,RecordType> allTypes){
		nameToRTMap = new Map<String,RecordType>();
		for ( RecordType rt : allTypes.values() ) {
			nameToRTMap.put(rt.DeveloperName,rt);
		}
		if(nameToRTMap.containsKey(rtName)){
			return nameToRTMap.get(rtName);
		}
		return null;
	}
}