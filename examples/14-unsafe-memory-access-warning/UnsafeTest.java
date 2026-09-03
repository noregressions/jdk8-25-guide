import sun.misc.Unsafe;
import java.lang.reflect.Field;

// sun.misc.Unsafe memory-access methods (objectFieldOffset/putInt/etc): silent
// and unremarkable on JDK 8. Deprecated for removal in JDK 23 (JEP 471); warnings
// began in JDK 24 (JEP 498), not 25 -- worth pinning, since the warning is the
// only signal you get before the eventual hard failure.
public class UnsafeTest {
    public static void main(String[] args) throws Exception {
        Field f = Unsafe.class.getDeclaredField("theUnsafe");
        f.setAccessible(true);
        Unsafe u = (Unsafe) f.get(null);
        long off = u.objectFieldOffset(Holder.class.getDeclaredField("x"));
        Holder h = new Holder();
        u.putInt(h, off, 42);
        System.out.println("h.x via Unsafe = " + h.x);
    }
    static class Holder { int x; }
}
