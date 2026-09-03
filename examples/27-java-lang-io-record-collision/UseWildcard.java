import mypkg.*; // wildcard import -- this is the pattern that collides

public class UseWildcard {
    public static void main(String[] args) {
        IO.hello(); // ambiguous on JDK 25: mypkg.IO vs the new java.lang.IO
    }
}
