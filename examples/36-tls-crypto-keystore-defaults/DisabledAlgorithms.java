// jdk.tls.disabledAlgorithms is updated nearly every release. This test doesn't
// assert on the exact list content -- see NOTES/README for why that would be
// unreliable across patch levels -- just prints it for comparison.
public class DisabledAlgorithms {
    public static void main(String[] args) {
        System.out.println(java.security.Security.getProperty("jdk.tls.disabledAlgorithms"));
    }
}
