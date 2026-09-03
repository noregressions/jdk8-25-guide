import java.lang.reflect.Method;
public class MainReflective {
    public static void main(String[] a) throws Exception {
        Person p = new Person();
        Method setName = Person.class.getMethod("setName", String.class);
        setName.invoke(p, "Ada");
        Method getName = Person.class.getMethod("getName");
        System.out.println("name via reflection = " + getName.invoke(p));
    }
}
