import mypkg.*;

// java.lang.Record has existed since JDK 16 (JEP 395) -- a JDK cycle before
// java.lang.IO. Identical collision pattern, identical fix (explicit import),
// and per the reference doc's correction, worth treating as one recurring
// pattern rather than two unrelated incidents.
public class UseWildcardRecord {
    public static void main(String[] args) {
        Record.hello();
    }
}
