#!/usr/bin/env bash
# Locates a working, locally-installed JDK of a given major version.
#
#   ./setup/find-jdk.sh 8     -> prints a JDK home on stdout, exits 0
#                             -> prints nothing, exits 1 if none found
#
# Only stdout carries the path; diagnostics go to stderr, so this is safe to use as
# JDK8_HOME="$(./setup/find-jdk.sh 8)".
#
# Exists because downloading JDKs is the worse option on most developer machines:
# the right builds are usually already installed, and Adoptium has no JDK 8 build
# for macOS aarch64 at all (only mac/x64, which needs Rosetta). A locally installed
# native JDK 8 -- Zulu, Corretto, Liberica -- avoids that entirely.
set -uo pipefail

want="${1:?usage: find-jdk.sh <major-version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Major version as reported by the JVM itself: "1.8.0_482" -> 8, "25.0.1" -> 25.
major_of() {
  local out ver
  out="$("$1/bin/java" -version 2>&1)" || return 1
  ver="$(printf '%s\n' "$out" | sed -n 's/.*version "\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || return 1
  ver="${ver#1.}"                                     # 1.8.0_482 -> 8.0_482
  printf '%s\n' "$ver" | sed 's/[^0-9].*//'           # -> 8
}

# A candidate qualifies only if it actually runs AND reports the version we asked for.
usable() {
  [ -n "${1:-}" ] || return 1
  [ -x "$1/bin/java" ] || return 1
  [ -x "$1/bin/javac" ] || return 1      # tests compile, so a JRE is not enough
  [ "$(major_of "$1" 2>/dev/null)" = "$want" ]
}

try() { if usable "$1"; then printf '%s\n' "$1"; exit 0; fi; }

# 1. Explicit override.
eval "explicit=\${JDK${want}_HOME:-}"
try "${explicit:-}"

# 2. Previously downloaded by setup/download-jdks.sh.
try "$ROOT/.jdks/jdk$want"

# 3. sdkman.
for d in "$HOME"/.sdkman/candidates/java/*/; do
  [ "$(basename "$d")" = "current" ] && continue
  try "${d%/}"
done

# 4. macOS java_home.
if [ "$(uname -s)" = "Darwin" ] && [ -x /usr/libexec/java_home ]; then
  spec="$want"; [ "$want" = "8" ] && spec="1.8"
  try "$(/usr/libexec/java_home -v "$spec" 2>/dev/null)"
fi

# 5. Homebrew.
for d in "/opt/homebrew/opt/openjdk@$want/libexec/openjdk.jdk/Contents/Home" \
         "/usr/local/opt/openjdk@$want/libexec/openjdk.jdk/Contents/Home"; do
  try "$d"
done

# 6. Linux distro locations.
for d in /usr/lib/jvm/*/ /opt/java/*/; do
  try "${d%/}"
done

echo "find-jdk.sh: no working JDK $want found locally." >&2
exit 1
