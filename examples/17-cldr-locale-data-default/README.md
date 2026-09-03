# 17 — CLDR locale data becomes default

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

## Added check: the bridge flag no longer works

`-Djava.locale.providers=COMPAT,CLDR` is the stopgap most write-ups on JEP 252
recommend, and it is the first thing a team reaches for here. It was deprecated in
JDK 21 and **removed in JDK 23** — so through JDK 22 it still works and merely warns,
which is why it survives in configurations.

This leg is **reported, not asserted**: gating on a JDK 23 behaviour would make the
test fail on every release from 9 to 22 for a reason unrelated to JEP 252, which is
what it is actually measuring. The release matrix caught exactly that mistake in an
earlier version of this test.

```
JDK 25 WITH -Djava.locale.providers=COMPAT,CLDR:
  INFO: Invalid locale provider adapter "COMPAT" ignored.
  WARNING: COMPAT locale provider has been removed
  currency ja_JP = ¥1,234
  full date ja_JP = 2019年5月2日木曜日
  full date length (chars) = 12

JDK 8  full-date string length:  9
JDK 25 full-date string length:  12
JDK 25 + COMPAT,CLDR length:     12   (identical to plain JDK 25 -- the flag is inert)
```

The flag is accepted, warns, and changes nothing. That is the worst possible shape
for a compatibility flag: it does not fail loudly and it does not alter behaviour,
so a team that adds it, re-runs the suite and sees identical output can reasonably
conclude the locale question is handled. The warning goes to the logging framework's
default handler and is easily lost in startup noise.

The absence of a bridge is what makes this category unusual: the structural fix
(stop treating formatted strings as data) is not the *preferred* option here, it is
the only one.

<!-- matrix:begin -->

## Behaviour across JDK releases

Measured against every JDK release 8–26 by [`matrix/run-matrix.sh`](../matrix/README.md). `P` = the documented difference is present at that release; `.` = that release still behaves like JDK 8; `s` = skipped.

| 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| . | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P | P |

**What the JDK does, release by release:**

**8** JRE locale data is the default provider · **9–26** CLDR is the default and formats differ; the COMPAT bridge works until 22 and is gone from 23

**Shape:** **step** — arrives at one release and still holds at the newest tested · first differs at **9**

Boundary at 9 matches JEP 252. Reaching that required a fix: the COMPAT-bridge leg originally *asserted* a JDK 23 behaviour, which made the test fail on 9-22 for reasons unrelated to JEP 252 and destroyed its value as a boundary probe. That leg now reports instead of gating.

<!-- matrix:end -->
