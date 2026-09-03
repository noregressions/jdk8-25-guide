// Throws a controlled number of Exceptions and Errors, catching every one, so a
// JFR recording can be checked against a known-exact expected count.
//
// The migration-relevant Throwables -- NoClassDefFoundError, NoSuchMethodError,
// IllegalAccessError, UnsatisfiedLinkError -- are all Errors, not Exceptions.
// This test uses NoClassDefFoundError for that reason.
public class Throwers06 {
    public static void main(String[] args) throws Exception {
        int n = Integer.parseInt(args[0]);
        String kind = args[1];
        for (int i = 0; i < n; i++) {
            if (kind.equals("error")) {
                try { throw new NoClassDefFoundError("error-" + i); }
                catch (NoClassDefFoundError e) { /* swallowed, exactly like a framework fallback */ }
            } else {
                try { throw new IllegalStateException("exception-" + i); }
                catch (IllegalStateException e) { /* swallowed */ }
            }
        }
        Thread.sleep(300);   // let the recorder flush before dumponexit
        System.out.println("threw " + n + " " + kind + "(s), all caught");
    }
}
