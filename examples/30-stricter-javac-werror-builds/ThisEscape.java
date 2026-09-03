// Calls an overridable instance method from the constructor -- 'this' escapes
// to code that could run (via a subclass override) before the object is fully
// initialized. This exact pattern compiled without a peep on JDK 8. The
// this-escape lint category (JDK 21+) flags it -- and note the warning fires on
// the SUPERCLASS's constructor even though the actual risk only materializes
// if something subclasses it and overrides the method (see Sub.java).
public class ThisEscape {
    public ThisEscape() {
        doSomething();
    }
    public void doSomething() {}
}
