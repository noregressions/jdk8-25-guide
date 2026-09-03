// java.version went from "1.8.0_292"-style to plain "25" (JEP 223). Hand-rolled
// version-parsing logic that assumes the old "1.x" shape silently misdetects the
// platform on the new scheme -- no exception, just a wrong branch taken.
public class Ver {
    public static void main(String[] args) {
        String v = System.getProperty("java.version");
        System.out.println("java.version = " + v);
        boolean looksLike8ViaOldParse = v.startsWith("1.");
        System.out.println("naive check startsWith(\"1.\") = " + looksLike8ViaOldParse);
        String naiveMajor = v.contains(".") ? v.substring(0, v.indexOf('.')) : v;
        System.out.println("naive major-version extraction (split on first dot) = " + naiveMajor);
    }
}
