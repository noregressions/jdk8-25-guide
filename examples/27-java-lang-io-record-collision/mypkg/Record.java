package mypkg;

// Same story as IO.java, one JDK cycle earlier: this class name was completely
// safe to pick before JDK 16 added java.lang.Record (JEP 395).
public class Record {
    public static void hello() {
        System.out.println("mypkg.Record.hello()");
    }
}
