// Directly calls the Lombok-generated getters/setters -- if annotation
// processing never ran, javac fails to even COMPILE this at javac time
// ("cannot find symbol"), because the call is resolved at compile time.
// See MainReflective.java for the scenario where the failure only shows up
// at runtime instead.
public class MainDirect {
    public static void main(String[] args) {
        Person p = new Person();
        p.setName("Ada");
        p.setAge(30);
        System.out.println(p.getName() + " " + p.getAge());
    }
}
