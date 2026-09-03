// The default keystore type is one of the more concrete, version-pinned parts
// of the broader "TLS/crypto posture tightened" story: JKS -> PKCS12, JDK 9.
// Code or scripts that create a KeyStore with no explicit type
// (KeyStore.getInstance(KeyStore.getDefaultType())) silently get a different
// on-disk format across this boundary.
public class KeystoreType {
    public static void main(String[] args) {
        System.out.println("keystore.type = " + java.security.KeyStore.getDefaultType());
    }
}
