public class StringConverter implements IConverter
{
    public Object getValue(String input)
    {
        return String.valueOf(input);
    }
}