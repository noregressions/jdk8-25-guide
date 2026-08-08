// A tight, uncontended synchronized loop -- the exact pattern biased locking was
// designed to speed up (StringBuffer-era code, legacy collection classes). This
// test does NOT try to assert on the actual throughput delta (see README.md for
// why a portable, deterministic timing assertion here would be unreliable); it
// just confirms the loop still runs correctly on both JDKs. The real finding from
// building this test was about the FLAG, not the timing -- see run.sh.
public class Bias {
    static int counter = 0;
    public static void main(String[] args) {
        Object lock = new Object();
        for (int i = 0; i < 2_000_000; i++) {
            synchronized (lock) {
                counter++;
            }
        }
        System.out.println("uncontended synchronized loop completed, counter=" + counter);
    }
}
