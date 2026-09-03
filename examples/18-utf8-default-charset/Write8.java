import java.io.*;

// Simulates the historical Windows JDK 8 default charset (windows-1252) via an
// explicit -Dfile.encoding override, so this test is deterministic regardless of
// what locale the machine actually running it happens to have. Run under JDK 8
// with: java -Dfile.encoding=windows-1252 Write8
public class Write8 {
    public static void main(String[] args) throws Exception {
        System.out.println("writer file.encoding = " + System.getProperty("file.encoding"));
        String text = "Price " + (char) 0x00A3 + "100";   // 0x00A3 is the GBP pound sign
        try (Writer w = new FileWriter("out.txt")) {       // <-- no explicit charset: the bug pattern
            w.write(text);
        }
        byte[] bytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get("out.txt"));
        StringBuilder hex = new StringBuilder();
        for (byte b : bytes) hex.append(String.format("%02X ", b));
        System.out.println("bytes written (" + bytes.length + "): " + hex.toString().trim());
    }
}
