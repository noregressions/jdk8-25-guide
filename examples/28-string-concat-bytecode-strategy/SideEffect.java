// The claim under test, which circulates widely in migration write-ups:
// "if a toString() argument has side effects, evaluation order can
// differ between the old StringBuilder-chain bytecode and the new invokedynamic
// bytecode -- only on recompiled code." This class concatenates three
// side-effecting objects and records the ORDER their toString() methods actually
// fire in, so that order can be compared across javac8 (StringBuilder chain) and
// javac25 (invokedynamic / JEP 280) compiles of the identical source.
public class SideEffect {
    static int calls = 0;
    static class Loud {
        final int id;
        Loud(int id) { this.id = id; }
        @Override public String toString() {
            calls++;
            System.out.println("toString() call #" + calls + " on Loud#" + id);
            return "L" + id;
        }
    }
    public static void main(String[] args) {
        Loud x = new Loud(1);
        Loud y = new Loud(2);
        Loud z = new Loud(3);
        String s = "[" + x + "," + y + "," + z + "]";
        System.out.println("result = " + s);
    }
}
