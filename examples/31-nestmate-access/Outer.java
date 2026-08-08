// Outer's private field is read from a nested class. Pre-nestmates (before
// JDK 11, JEP 181), javac had to generate a synthetic bridge method
// (access$000) on Outer to let Inner reach that private field legally --
// private access across a class boundary wasn't something the JVM itself
// understood yet, only something javac worked around. Since JDK 11, the JVM
// understands "these classes are nestmates" directly (NestHost/NestMembers
// class file attributes), so the bridge method is no longer needed at all.
public class Outer {
    private int secret = 42;
    static class Inner {
        int readSecret(Outer o) { return o.secret; }
    }
    public static void main(String[] args) {
        Outer o = new Outer();
        Inner i = new Inner();
        System.out.println("secret via Inner = " + i.readSecret(o));
    }
}
