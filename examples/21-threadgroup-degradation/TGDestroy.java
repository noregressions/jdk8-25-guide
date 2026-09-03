// destroy() -- a no-op since JDK 16. Checked separately from stop() because the
// two methods degrade in DIFFERENT ways: destroy() stays callable and just silently does
// nothing, while stop() is gone from the class entirely on a recompile and throws
// NoSuchMethodError against old, unrecompiled bytecode.
public class TGDestroy {
    public static void main(String[] args) throws Exception {
        ThreadGroup tg = new ThreadGroup("test2");
        System.out.println("isDestroyed() before = " + tg.isDestroyed());
        tg.destroy();
        System.out.println("destroy() returned normally, isDestroyed() after = " + tg.isDestroyed());
    }
}
