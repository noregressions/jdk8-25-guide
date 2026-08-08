import java.io.*;

// Reads the file Write8.java produced, with JDK 25's own unforced default charset
// (which is unconditionally UTF-8 per JEP 400, regardless of host locale). No
// -Dfile.encoding override needed or wanted here -- the point is JDK 25's real
// default, not a simulated one.
public class Read25 {
    public static void main(String[] args) throws Exception {
        System.out.println("reader file.encoding = " + System.getProperty("file.encoding"));
        String original = "Price " + (char) 0x00A3 + "100";   // what Write8 intended to write
        try (Reader r = new FileReader("out.txt")) {           // <-- no explicit charset: the bug pattern
            char[] buf = new char[64];
            int n = r.read(buf);
            String readBack = new String(buf, 0, n);
            System.out.println("read back: matches original = " + readBack.equals(original));
            System.out.println("read back char[6] = U+" + String.format("%04X", (int) readBack.charAt(6)));
        }
    }
}
