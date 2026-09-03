import java.lang.reflect.Method;
public class Refl {
    // Same restricted operation as Nat.viaFfm, but every type is resolved by NAME
    // at runtime, so nothing lands in this class's constant pool for a scanner to see.
    public static void main(String[] a) throws Throwable {
        Class<?> linkerC = Class.forName("java.lang.foreign.Linker");
        Object linker = linkerC.getMethod("nativeLinker").invoke(null);
        Method dh = linkerC.getMethod("downcallHandle",
            Class.forName("java.lang.foreign.MemorySegment"),
            Class.forName("java.lang.foreign.FunctionDescriptor"),
            Class.forName("[Ljava.lang.foreign.Linker$Option;"));
        System.out.println("resolved restricted method reflectively: " + dh.getName());
    }
}
