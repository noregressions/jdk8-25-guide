package mypkg;

// The third resolution path chapter 3.27 names, and the one no test covered: a
// same-package reference. mypkg's own types shadow java.lang, so this needs no
// import at all and resolves to mypkg.IO with no ambiguity -- on JDK 25, where
// java.lang.IO exists. Included because the chapter's whole point is that the
// collision is narrower than "any class named IO breaks", and that claim is only
// worth making if all three paths are actually checked.
public class SamePkg {
    public static void main(String[] args) {
        IO.hello();
    }
}
