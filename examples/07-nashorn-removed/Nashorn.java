import javax.script.*;

// javax.script (JSR 223) itself is still in the JDK. What's gone is the
// "nashorn" engine registration -- getEngineByName("nashorn") now returns null
// instead of throwing, so the failure shows up one line later as an NPE on
// e.eval(), not as an obvious "engine not found" error.
public class Nashorn {
    public static void main(String[] args) throws Exception {
        ScriptEngineManager m = new ScriptEngineManager();

        // All three names resolved to the bundled engine on JDK 8. Checking each
        // matters because a codebase may use any of them, and looking up only
        // "nashorn" would leave a reader thinking the others might still work.
        for (String name : new String[] { "nashorn", "js", "javascript" }) {
            System.out.println("byName(" + name + ") = " + m.getEngineByName(name));
        }

        ScriptEngine e = m.getEngineByName("nashorn");
        System.out.println("engine = " + e);
        Object result = e.eval("1+1"); // NPE here, not a clean "not found" error
        System.out.println("result = " + result);
    }
}
