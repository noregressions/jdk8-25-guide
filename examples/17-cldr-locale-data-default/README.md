# 17 — CLDR locale data becomes default

| | |
|---|---|
| **Category** | Runs But Wrong (silent behaviour change) |
| **Introduced** | JDK 9 (JEP 252) |
| **Symptom** | Formatted dates, currencies, numbers, and era names change silently — hits stored formatted output (report filenames, invoices, log timestamps) hardest |
| **Detect** | Run locale-sensitive tests on both JDKs, diff the output |
| **Fix** | Stop asserting on exact formatted strings; use structured date/time types and format only at the display boundary. `-Djava.locale.providers=COMPAT,CLDR` is the temporary bridge, not the fix. |

## What this test does — and how the pass/fail check avoids the transport bug

Formats `2019-05-02` as a FULL-style date for `Locale.JAPAN`, once under JDK 8
(default locale provider: COMPAT, the old JRE-bundled data) and once under JDK 25
(default: CLDR, per JEP 252). The `run.sh` pass/fail check only inspects a plain
ASCII number the Java program itself prints (`fullDate.length()`) — not the actual
Japanese text — specifically so this test's correctness doesn't depend on the
shell/terminal correctly displaying non-ASCII bytes (see `../NOTES.md`'s entries
on the £-character transport bug from test 18; same category of risk, avoided here
by construction rather than worked around after the fact).

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4, captured with explicit UTF-8 output encoding)

```
JDK 8 (COMPAT locale provider, the JDK 8 default):
  currency ja_JP = ¥1,234
  full date ja_JP = 2019-05-02, formatted as "year 4 kanji, month 1-2 digits +
    kanji, day 1-2 digits + kanji" -- 9 characters total, no day-of-week
  full date length (chars) = 9

JDK 25 (CLDR locale provider, the JDK 9+ default):
  currency ja_JP = ¥1,234
  full date ja_JP = same as above PLUS the day-of-week name appended
    ("Thursday" in Japanese) -- 12 characters total
  full date length (chars) = 12
```

Same input, same locale, same JDK API call, three extra characters of output that
weren't there before — and nothing in either run so much as logs a warning. The
currency format happened to come out identical in this particular locale/amount
combination; the date format is where JEP 252's provider switch actually shows up
for this locale, and it's the day-of-week name that CLDR adds and COMPAT omits.
