public class BooleanConverter implements IConverter {
	public Object getValue(String input) {
		try {
			if (input == '0') return false;
			if (input == '1') return true;
			return Boolean.valueOf(input);
		} catch (Exception ex) {
			return null;
		}
	}
}