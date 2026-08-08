// Demonstrates why the this-escape warning exists, not just that it exists:
// ThisEscape's constructor calls doSomething() before Sub's own fields are set
// up. Overriding doSomething() here to read a field lets a subclass observe
// partially-constructed state from its superclass's constructor.
public class Sub extends ThisEscape {
    private int x = 5;
    @Override public void doSomething() {
        System.out.println("x = " + x);
    }
    public static void main(String[] args) {
        new Sub();
    }
}
