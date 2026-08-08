public class SecCheck {
    // A SecurityManager that unconditionally denies every permission -- stands in
    // for a real security policy that's supposed to block a specific operation.
    static class DenyingSecurityManager extends SecurityManager {
        @Override public void checkPermission(java.security.Permission perm) {
            throw new SecurityException("denied: " + perm);
        }
    }

    public static void main(String[] args) {
        // Defensive try/catch around installing the SM -- a common real-world
        // pattern for code that might run under a framework that already
        // installed one, or that tolerates the SM being unavailable. On JDK 8
        // this never throws. On JDK 25 it always does (see test 08) -- and this
        // pattern quietly swallows that.
        try {
            System.setSecurityManager(new DenyingSecurityManager());
        } catch (UnsupportedOperationException uoe) {
            System.out.println("could not install SecurityManager: " + uoe);
        }

        SecurityManager sm = System.getSecurityManager();
        System.out.println("getSecurityManager() = " + sm);

        boolean blocked = false;
        if (sm != null) {
            try {
                sm.checkPermission(new java.security.AllPermission());
            } catch (SecurityException se) {
                blocked = true;
                System.out.println("operation BLOCKED by SecurityException: " + se);
            }
        }
        if (!blocked) {
            System.out.println("operation PROCEEDED (no security check enforced)");
        }
    }
}
