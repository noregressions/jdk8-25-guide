package mypkg;

// A perfectly ordinary, pre-existing class named IO -- the kind of name that was
// completely safe to pick before JDK 25 added java.lang.IO (JEP 512).
public class IO {
    public static void hello() {
        System.out.println("mypkg.IO.hello()");
    }
}
