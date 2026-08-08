import javax.xml.bind.annotation.XmlRootElement;

// javax.xml.bind (JAXB) was one of the Java EE packages bundled into the JDK 8
// runtime. JDK 11 (JEP 320) removed all of them from the JDK entirely -- not
// renamed, not relocated, just gone. The class file compiled fine on JDK 8;
// running that SAME class file on JDK 25 fails at class-load time because the
// JDK no longer ships the class at all.
public class EE {
    public static void main(String[] args) {
        System.out.println(XmlRootElement.class.getName());
    }
}
