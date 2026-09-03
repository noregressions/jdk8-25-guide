import java.lang.reflect.*;
// How much of sun.misc.Unsafe is actually on the removal path?
//
// JEP 471 terminally deprecated "the 79 memory-access methods", and that figure gets
// quoted as though it were the whole story. It is not: the annotation has spread
// wider since, and the totals drift with each release, so this counts them on the
// JDK actually in front of us rather than trusting a number from a 2024 JEP.
public class UnsafeSurface {
  public static void main(String[] a) throws Exception {
    Class<?> c = Class.forName("sun.misc.Unsafe");
    int pub=0, dep=0, depForRemoval=0;
    for (Method m : c.getDeclaredMethods()) {
      if (!Modifier.isPublic(m.getModifiers())) continue;
      pub++;
      Deprecated d = m.getAnnotation(Deprecated.class);
      if (d != null) { dep++; if (d.forRemoval()) depForRemoval++; }
    }
    java.util.TreeSet<String> survivors = new java.util.TreeSet<>();
    for (Method m : c.getDeclaredMethods())
      if (Modifier.isPublic(m.getModifiers()) && m.getAnnotation(Deprecated.class) == null)
        survivors.add(m.getName());

    System.out.println("public=" + pub + " deprecated=" + dep
        + " forRemoval=" + depForRemoval + " surviving=" + (pub - dep));
    System.out.println("survivors=" + survivors);
  }
}
