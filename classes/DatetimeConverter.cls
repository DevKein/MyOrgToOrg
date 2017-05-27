public class DatetimeConverter implements IConverter {
	public Object getValue(String input) {
		try {
			return Datetime.valueOf(input);
		} catch (Exception e) {
			return null;
		}
	}
}