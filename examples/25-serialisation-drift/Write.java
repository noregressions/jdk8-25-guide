import java.io.*;
public class Write {
    public static void main(String[] args) throws Exception {
        try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("obj.ser"))) {
            oos.writeObject(new Payload.Nested());
        }
        System.out.println("wrote obj.ser");
    }
}
