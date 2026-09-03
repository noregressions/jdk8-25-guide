import sun.misc.Unsafe;
import java.lang.reflect.Field;

// How coarse is the JDK 25 Unsafe warning?
//
// Chapter 1.7 described --sun-misc-unsafe-memory-access=warn as "Warning on first
// use per call site". If that were true, the three distinct putInt call sites
// below would produce three warnings. They do not: the warning is issued once per
// CALLING CLASS. Two classes here, three call sites, and the count that comes back
// tells you which model is real.
//
// This matters during a migration because the warning count is the thing people
// use to judge how much Unsafe usage they have left. Per-class granularity means
// a class with fifty Unsafe call sites warns exactly once.
public class UnsafeGranularity {

    static Unsafe unsafe() throws Exception {
        Field f = Unsafe.class.getDeclaredField("theUnsafe");
        f.setAccessible(true);
        return (Unsafe) f.get(null);
    }

    static class Holder { int x; }

    static class SiteA {
        static void first(Unsafe u, long off, Holder h) { u.putInt(h, off, 1); }   // call site 1
        static void second(Unsafe u, long off, Holder h) { u.putInt(h, off, 2); }  // call site 2
    }

    static class SiteB {
        static void only(Unsafe u, long off, Holder h) { u.putInt(h, off, 3); }    // call site 3
    }

    public static void main(String[] args) throws Exception {
        Unsafe u = unsafe();
        long off = u.objectFieldOffset(Holder.class.getDeclaredField("x"));
        Holder h = new Holder();
        SiteA.first(u, off, h);
        SiteA.second(u, off, h);
        SiteB.only(u, off, h);
        System.out.println("3 distinct putInt call sites across 2 classes, final h.x = " + h.x);
    }
}
