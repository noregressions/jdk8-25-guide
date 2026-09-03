import java.lang.foreign.*;

// The Foreign Function & Memory API (JEP 454, finalized JDK 22) is a JDK 22+
// concept -- there's no JDK 8 equivalent to compare against (JDK 8 native access
// meant hand-written JNI, a completely different mechanism). This test instead
// compares JDK 25 WITH and WITHOUT --enable-native-access, which is the actual
// migration-relevant checkpoint: code written for 22-24 that worked silently may
// start warning (and, on a future release, fail) as the restriction tightens.
public class Native {
    public static void main(String[] args) throws Throwable {
        Linker linker = Linker.nativeLinker();
        var strlen = linker.downcallHandle(
            linker.defaultLookup().find("strlen").get(),
            FunctionDescriptor.of(ValueLayout.JAVA_LONG, ValueLayout.ADDRESS));
        try (Arena arena = Arena.ofConfined()) {
            MemorySegment cstr = arena.allocateFrom("hello");
            long len = (long) strlen.invoke(cstr);
            System.out.println("strlen(hello) = " + len);
        }
    }
}
