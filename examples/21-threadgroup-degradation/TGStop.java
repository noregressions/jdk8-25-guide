// Compiled and run under JDK 8. Deliberately NOT recompiled under JDK 25 in
// run.sh -- the point is what happens when an old, already-compiled class file
// calls ThreadGroup.stop() against the JDK 25 runtime.
public class TGStop {
    public static void main(String[] args) throws Exception {
        ThreadGroup tg = new ThreadGroup("test");
        Thread t = new Thread(tg, () -> {
            try { Thread.sleep(60000); } catch (InterruptedException ie) { /* expected */ }
        });
        t.start();
        Thread.sleep(50);
        try {
            tg.stop();
            System.out.println("tg.stop() returned normally");
        } catch (Throwable ex) {
            System.out.println("tg.stop() threw: " + ex);
        }
        t.interrupt();
        t.join(200);
    }
}
