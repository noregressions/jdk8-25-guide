import mypkg.IO; // explicit single-type import -- disambiguates, per the reference doc's correction

public class UseExplicit {
    public static void main(String[] args) {
        IO.hello(); // resolves cleanly: an explicit import always wins over java.lang
    }
}
