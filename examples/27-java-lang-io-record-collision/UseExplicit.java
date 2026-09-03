import mypkg.IO; // explicit single-type import -- always wins over java.lang, so no ambiguity

public class UseExplicit {
    public static void main(String[] args) {
        IO.hello(); // resolves cleanly: an explicit import always wins over java.lang
    }
}
