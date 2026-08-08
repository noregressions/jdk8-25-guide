// A trivial class -- what matters is which JDK compiles it, not what it does.
// This stands in for any class in the build: the JaCoCo-instrumented test
// class, a Mockito-mocked interface, anything a build-time tool (coverage,
// mocking, bytecode weaving) has to parse.
public class Target {
    public static void main(String[] args) {
        System.out.println("hi");
    }
}
