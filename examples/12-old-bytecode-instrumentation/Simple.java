// Stands in for what an old ASM/ByteBuddy/CGLIB-based instrumentation library
// would try to parse or generate: a plain class file. The interesting number here
// is the class file's OWN major version, and what happens when an OLDER JVM (which
// is what an unpatched, ancient instrumentation library's internal parser
// effectively is) is asked to load a class file from a NEWER one.
public class Simple {
    public static void main(String[] args) {
        System.out.println("hi");
    }
}
