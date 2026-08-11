# 37 — Container memory ergonomics changed

**Full details:** [Chapter 3.37 — Container Memory Ergonomics](https://github.com/noregressions/jdk8-25-guide/blob/main/src/main/paperband/03.37-container-memory-ergonomics.md)

## What this test does — no Docker daemon needed, and an important negative result

This sandbox has the `docker` CLI but no reachable daemon (see `../NOTES.md`).
Rather than skip this item, the test creates a real **cgroup v1 memory limit**
directly (512MB) and runs each JDK inside it via `bash -c 'echo $$ >
cgroup.procs; exec java ...'` — the same kernel mechanism a container uses,
without needing an actual container runtime.

**Finding, and why this test's result is a confirmation, not a failure**: this
sandbox's JDK 8 build is **8u502** — a current patch, years past the 8u191
backport point the reference doc itself names. Both JDK 8 and JDK 25 correctly
compute `MaxHeapSize` from the cgroup limit rather than host RAM. That's the
*expected* result given the doc's own wording — the backport really did land —
but it means **this sandbox cannot reproduce the actual broken "before" state**
the doc's Symptom line describes. That would require a genuinely pre-2018 JDK 8
binary (older than 8u191), which isn't available through the current Adoptium
API used by `setup/download-jdks.sh` (it only serves recent patches of each
feature version). If you have an old JDK 8 archive lying around, pointing
`JDK8_HOME` at it and re-running this test would show the real contrast: an old
build reporting `MaxHeapSize` sized off the **host's** 7.8GB, not the 512MB
cgroup limit.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4, real cgroup v1 limit)

```
Host total memory:
  Mem:           7.8Gi        683Mi        5.9Gi         4.7Mi        1.5Gi        7.2Gi

JDK 8 MaxHeapSize, unconstrained:
      uintx MaxHeapSize                              := 2103443456                          {product}
JDK 8 MaxHeapSize, constrained to a 512MB cgroup:
      uintx MaxHeapSize                              := 134217728                           {product}

JDK 25 MaxHeapSize, unconstrained:
     size_t MaxHeapSize                              = 2103443456                                {product} {ergonomic}
JDK 25 MaxHeapSize, constrained to a 512MB cgroup:
     size_t MaxHeapSize                              = 134217728                                 {product} {ergonomic}
```

Both JDKs settle on 134217728 bytes (128MB, the default 25% of the 512MB
cgroup limit) once constrained — identical container-awareness, confirming the
8u191 backport claim, but not demonstrating the pre-backport failure mode.

## Bash gotcha worth recording

The first version of this script's `run_constrained` helper used a plain `( ...
)` subshell with `echo $$ > cgroup.procs`. That's a real bug, not a style
choice: bash defines `$$` inside a `()` subshell as the **parent shell's PID**
for backward compatibility, so that line silently moved this *entire script's*
own process into the memory cgroup — permanently, for the rest of the script —
rather than just the intended subshell. Every later "unconstrained" check in
that version was actually still running inside the 512MB limit, and the test's
apparent result was wrong. Fixed by using `bash -c '...'` instead, which gets a
genuinely distinct PID.
