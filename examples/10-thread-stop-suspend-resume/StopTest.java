// Thread.stop() (and its siblings suspend()/resume()) have been deprecated since
// Java 1.2, but stayed silently functional for two decades. Since JDK 20 they
// throw UnsupportedOperationException outright -- no dedicated JEP, just an
// implementation change to long-deprecated methods.
//
// The worker is a DAEMON thread deliberately. On JDK 25 the stop() call throws in
// main, so nothing after it runs -- including the join() that would otherwise tidy
// up. A non-daemon worker would then keep the JVM alive for the rest of its sleep,
// turning this test into a multi-second stall for no diagnostic gain. Daemon status
// affects neither what stop() does on JDK 8 nor what it throws on JDK 25.
public class StopTest {
    public static void main(String[] args) throws Exception {
        Thread t = new Thread(() -> {
            try { Thread.sleep(5000); } catch (InterruptedException ie) { /* expected on stop/interrupt */ }
        });
        t.setDaemon(true);
        t.start();
        Thread.sleep(50);
        t.stop();                                       // throws on JDK 20+
        System.out.println("stop() returned normally");  // JDK 8 only
        t.join(200);
    }
}
