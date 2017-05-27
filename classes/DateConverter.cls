public class DateConverter implements IConverter {
	public Object getValue(String input) {
		try {
			return Date.valueOf(input);
		} catch (Exception e) {
			return null;
		}
	}
}