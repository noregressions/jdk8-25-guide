import java.io.Serializable;

// Nested has a private field, read from the enclosing class below. Pre-nestmates
// (before JDK 11, JEP 181 -- see test 31), javac had to generate a synthetic
// bridge method (access$000) on Nested to let Payload reach that private field
// legally. That synthetic method's signature feeds into Nested's DEFAULT computed
// serialVersionUID (no explicit one is declared here -- see the Detect column).
// Once nestmates removes the synthetic bridge, the computed UID changes, even
// though nothing about Nested's own visible API changed at all.
public class Payload {
    static class Nested implements Serializable {
        private int secret = 42;
    }
    static int readSecret(Nested n) { return n.secret; } // forces the synthetic accessor on Nested
}
