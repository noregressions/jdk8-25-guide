// Four deprecated-API usages spanning both deprecation tiers, so a single scan
// shows exactly what jdeprscan does and does not tell you about each one.
//
//   System.setSecurityManager  -- @Deprecated(forRemoval=true)
//   Thread.stop                -- @Deprecated(forRemoval=true), already throws on 20+
//   Object.finalize (override) -- @Deprecated(forRemoval=true)
//   Runtime.exec(String)       -- ordinary @Deprecated, NOT for removal
public class Deprecated02 {

    @SuppressWarnings("removal")
    void installSecurityManager() {
        System.setSecurityManager(null);
    }

    @SuppressWarnings("removal")
    void stopThread(Thread t) {
        t.stop();
    }

    void runCommand() throws Exception {
        Runtime.getRuntime().exec("ls");
    }

    @Override
    @SuppressWarnings("removal")
    protected void finalize() {
        // deliberately overriding a deprecated-for-removal method
    }
}
