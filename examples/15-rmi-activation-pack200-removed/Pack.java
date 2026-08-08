import java.util.jar.Pack200;

// Pack200 -- a JAR compression format/tool, removed in JDK 14 (JEP 367).
public class Pack {
    public static void main(String[] args) {
        System.out.println(Pack200.newPacker());
    }
}
