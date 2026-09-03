import mypkg.*;

// java.lang.Record has existed since JDK 16 (JEP 395) -- a JDK cycle before
// java.lang.IO. Identical collision pattern, identical fix (explicit import),
// so this is one recurring pattern that arrives with each new java.lang type,
// rather than two unrelated incidents.
public class UseWildcardRecord {
    public static void main(String[] args) {
        Record.hello();
    }
}
