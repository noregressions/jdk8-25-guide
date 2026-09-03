import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
public class Nat {
    // (a) a declared native method -- the JNI shape jnativescan reports
    private static native int declaredNative(int x);
    // (b) an FFM restricted call reached only at runtime -- no native declaration
    static long viaFfm(String sym) throws Throwable {
        SymbolLookup lk = Linker.nativeLinker().defaultLookup();
        MemorySegment seg = lk.findOrThrow(sym);
        MethodHandle mh = Linker.nativeLinker().downcallHandle(
            seg, FunctionDescriptor.of(ValueLayout.JAVA_LONG, ValueLayout.ADDRESS));
        try (Arena a = Arena.ofConfined()) {
            return (long) mh.invokeExact(a.allocateFrom("hello"));
        }
    }
    public static void main(String[] a) throws Throwable { System.out.println("strlen=" + viaFfm("strlen")); }
}
