// java.applet.Applet: deprecated for removal since JDK 17 (JEP 398). Still
// present and still compiles on JDK 25 -- this is a slow-motion deprecation,
// not yet a hard break -- but the [removal] lint warning is new since JDK 17
// and doesn't fire on JDK 8 at all.
public class Applet extends java.applet.Applet {
    public void paint(java.awt.Graphics g) { g.drawString("hi", 10, 10); }
}
