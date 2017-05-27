public with sharing class JSONModel {
	public Map<String,List<sObject>> dataSet {get;set;}
	public Map<Integer,String> priorityMap {get;set;}
	public Map<String,Boolean> selfRelation {get;set;}
	public Map<String,Map<String,String>> externalMappings {get;set;}
	public Map<String,Map<String,String>> sourceFields {get;set;}
	public Map<String,String> sourceToTarget {get;set;}
	public Integer orderNo {get;set;}
	public Map<String, Map<Id, String>> rtMappings {get; set;}
}