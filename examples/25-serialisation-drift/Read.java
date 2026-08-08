import java.io.*;
public class Read {
    public static void main(String[] args) throws Exception {
        try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream("obj.ser"))) {
            Object o = ois.readObject();
            System.out.println("read back: " + o);
        }
    }
}
