import java.lang.reflect.Field;

// The pattern old Spring/Hibernate/Gson/Jackson used to reach a JDK-internal private
// field for dependency injection or high-performance serialisation.
public class Reflect {
    public static void main(String[] args) throws Exception {
        Field f = String.class.getDeclaredField("value");
        f.setAccessible(true);
        System.out.println("Access succeeded, field type: " + f.getType());
    }
}
