public with sharing class RecordTypeWrapper {
	public Map<Id,RecordType> recordTypeMap {get;set;}
	public RecordTypeWrapper(Map<Id,RecordType> recordTypeMap){
		this.recordTypeMap = recordTypeMap;
	}
}