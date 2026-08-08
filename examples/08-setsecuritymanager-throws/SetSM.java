// Calling System.setSecurityManager() from application code. On JDK 8 this is
// completely unremarkable. From JDK 18 onward it's disallowed by default (opt-out
// via -Djava.security.manager=allow through JDK 23); unconditional from JDK 24.
public class SetSM {
    public static void main(String[] args) throws Exception {
        System.setSecurityManager(new SecurityManager());
        System.out.println("set ok");
    }
}
