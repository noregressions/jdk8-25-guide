public class Fin {
    static volatile boolean finalized = false;
    static class HasFinalizer {
        @Override protected void finalize() { finalized = true; }
    }
    public static void main(String[] args) throws Exception {
        HasFinalizer h = new HasFinalizer();
        h = null; // eligible for GC + finalization now
        for (int i = 0; i < 20 && !finalized; i++) {
            System.gc();
            Thread.sleep(100);
        }
        System.out.println("finalized = " + finalized);
    }
}
