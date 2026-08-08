import java.rmi.activation.ActivationSystem;

// java.rmi.activation -- long-unmaintained corner of RMI, removed in JDK 17 (JEP 407).
public class RmiAct {
    public static void main(String[] args) {
        System.out.println(ActivationSystem.class.getName());
    }
}
