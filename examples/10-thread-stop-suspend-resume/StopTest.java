// Thread.stop() (and its siblings suspend()/resume()) have been deprecated since
// Java 1.2, but stayed silently functional for two decades. Since JDK 20 they
// throw UnsupportedOperationException outright -- no dedicated JEP, just an
// implementation change to long-deprecated methods.
public class StopTest {
    public static void main(String[] args) throws Exception {
        Thread t = new Thread(() -> {
            try { Thread.sleep(60000); } catch (InterruptedException ie) { /* expected on stop/interrupt */ }
        });
        t.start();
        Thread.sleep(50);
        t.stop();
        System.out.println("stop() returned normally");
        t.join(200);
    }
}
