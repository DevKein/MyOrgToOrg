public with sharing class TargetFieldWrapper {
	public String fieldName {get;set;}
	public SoapType fieldType {get;set;}
	public Boolean isExternal {get;set;}
	public TargetFieldWrapper(String fieldName, SoapType fieldType, Boolean isExternal){
		this.fieldName = fieldName;
		this.fieldType = fieldType;
		this.isExternal = isExternal;
	}
	public TargetFieldWrapper(String fieldName, SoapType fieldType){
		this.fieldName = fieldName;
		this.fieldType = fieldType;
		this.isExternal = false;
	}
}