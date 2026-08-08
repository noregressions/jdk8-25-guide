import java.net.URLClassLoader;

// On JDK 8, the system classloader is a plain java.net.URLClassLoader, and casting
// to it (to add JARs at runtime, scan the classpath, etc.) was a routine hack. Since
// JDK 9 (JEP 261), the system classloader is jdk.internal.loader.ClassLoaders$AppClassLoader,
// which does NOT extend URLClassLoader -- the cast fails.
public class CL {
    public static void main(String[] args) {
        ClassLoader cl = ClassLoader.getSystemClassLoader();
        System.out.println("classloader = " + cl.getClass().getName());
        URLClassLoader ucl = (URLClassLoader) cl;
        System.out.println("cast ok: " + ucl);
    }
}
