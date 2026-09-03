import java.lang.reflect.Field;

// Deep reflection that *writes* to a final field -- exactly what serialisation
// frameworks, dependency-injection containers and mocking libraries do when they
// reconstruct an object without calling its constructor.
//
// Silent and unremarkable from JDK 8 through 25. From JDK 26 (JEP 500) the JVM warns
// on the first such mutation and states that a future release will block it, putting
// this on the same warn-then-deny track as sun.misc.Unsafe (3.14) and native access
// (3.13).
public class FinalMutate {
    static final class Box {
        private final int value = 1;
        int read() { return value; }
    }

    public static void main(String[] args) throws Exception {
        Box b = new Box();
        Field f = Box.class.getDeclaredField("value");
        f.setAccessible(true);
        f.setInt(b, 99);
        // Reading through reflection rather than b.read(): javac constant-folds a
        // private final int initialised to a literal, so the field access would report
        // the old value regardless of the JDK and tell us nothing.
        System.out.println("final field now reads: " + f.getInt(b));
    }
}
