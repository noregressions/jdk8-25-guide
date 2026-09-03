import org.objectweb.asm.ClassReader;

// Stands in for what a build-time tool (JaCoCo, Mockito, an old Gradle/plugin
// internal) does under the hood: parse a compiled class file with a specific
// ASM version. This is the SAME underlying mechanism as test 12 (old bytecode
// instrumentation), but exercised through the real ASM library instead of the
// bare JVM class loader -- ASM's own error message and exception type differ
// from the JVM's UnsupportedClassVersionError, which is worth knowing when
// triaging a build failure: this one comes from your build tool, not from java
// itself, so it can be easy to misdiagnose as "something wrong with my code."
public class ReadClass {
    public static void main(String[] args) throws Exception {
        byte[] bytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(args[0]));
        ClassReader cr = new ClassReader(bytes);
        System.out.println("parsed class: " + cr.getClassName());
    }
}
