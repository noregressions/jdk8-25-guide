import java.util.Locale;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.FormatStyle;

// JDK 8's default locale-data provider is COMPAT (the old JRE-bundled data).
// JDK 9+ (JEP 252) defaults to CLDR. Both produce recognisable, "correct-looking"
// output for the same locale and date -- which is exactly the danger: nothing
// throws, nothing warns, the formatted string is just quietly different in length
// and content between JDK versions. No literal non-ASCII characters appear in
// this source file -- the Japanese text is generated at runtime by the JDK's own
// locale data, not typed here, so there's no encoding-transport risk in the
// source itself (see NOTES.md for why that distinction matters in this repo).
public class Locale17 {
    public static void main(String[] args) {
        Locale ja = Locale.JAPAN;
        NumberFormat nf = NumberFormat.getCurrencyInstance(ja);
        String currency = nf.format(1234);
        DateTimeFormatter f = DateTimeFormatter.ofLocalizedDate(FormatStyle.FULL).withLocale(ja);
        String fullDate = LocalDate.of(2019, 5, 2).format(f);
        System.out.println("currency ja_JP = " + currency);
        System.out.println("full date ja_JP = " + fullDate);
        System.out.println("full date length (chars) = " + fullDate.length());
    }
}
