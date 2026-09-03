import java.awt.*;
import java.awt.image.BufferedImage;

// Renders a string into an off-screen image in headless mode -- the same code
// path a PDF/chart/report generator uses. Works fine wherever fontconfig and
// at least one font package are installed (this sandbox, most full-size base
// images). Throws on minimal Linux/Docker base images (alpine, distroless,
// slim variants without an explicit fontconfig + font package layer) --
// see README.md for why this sandbox can't demonstrate that failure directly.
public class FontTest {
    public static void main(String[] args) throws Exception {
        System.setProperty("java.awt.headless", "true");
        BufferedImage img = new BufferedImage(200, 50, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = img.createGraphics();
        g.setFont(new Font("SansSerif", Font.PLAIN, 12));
        g.drawString("hello", 10, 20);
        g.dispose();
        System.out.println("rendered fine, font = " + g.getFont());
    }
}
