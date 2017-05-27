/**
 * Dynamic input value conversion according to desired field soap type
 * @author Mert YALTI
 * @since 11/01/2016
 * @version 1.4
 * @see  SoapType
 * @see  SObject
 * @see  SobjectField
 * @see  SObjectType
 * @see  DisplayTypes
 */
public with sharing class ConvertTypes {

    final SObjectField field;
    final IConverter converter;
    /**
     * Constructer method to define SoapType and proper converter class
     * @param  field Sobjectfield which we will use for defining SoapType to convert input value
     * @return       N/A
     */
    public ConvertTypes(SObjectField field) {
        this.field = field;
        SoapType nsoapType = field.getDescribe().getSoapType();
        try {
            if (nsoapType == SoapType.DOUBLE && field.getDescribe().getScale() == 0) {
                this.converter = (IConverter)IntegerConverter.class.newInstance();
            }
            else{
                this.converter = (IConverter)converters.get(nsoapType).newInstance();
            }
            
        } catch (Exception ex) {
            system.debug(LoggingLevel.ERROR, 'Converter not found ==>' + ex.getMessage());
        }
    }
    /**
     * Populates given field with properly converted input value
     * @param  record The record we are populating its fields
     * @param  input  The value that we use for populated given field on given record
     * @return        Updated sObject
     */
    public SObject putTo(SObject record, String input) {
        record.put(field, converter.getValue(input));
        return record;
    }
    /**
     * Static map to collect SoapTypes (primitive types) with their converter classes
     */
    static final Map<SoapType, Type> converters = new Map<SoapType, Type> {
        SoapType.DOUBLE => DoubleConverter.class,
        SoapType.DATE => DateConverter.class,
        SoapType.DATETIME => DateTimeConverter.class,
        SoapType.BOOLEAN => BooleanConverter.class,
        SoapType.ID => StringConverter.class,
        SoapType.STRING => StringConverter.class,
        SoapType.INTEGER => IntegerConverter.class
    };
}