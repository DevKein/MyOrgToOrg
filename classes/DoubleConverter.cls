public with sharing class DoubleConverter implements IConverter {
	public Object getValue(String input) {
		try {
			return Double.valueOf(input);
		} catch (Exception e) {
			return null;
		}
	}
}