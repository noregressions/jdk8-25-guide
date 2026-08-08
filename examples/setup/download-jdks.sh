#!/usr/bin/env bash
# Downloads Temurin JDK 8 and JDK 25 (Linux x64) into ../.jdks/ for the discovery-tests harness.
# Safe to re-run — skips download if the JDK is already extracted.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JDKS="$ROOT/.jdks"
mkdir -p "$JDKS"

fetch() {
  local major="$1"
  local dir="$JDKS/jdk$major"
  if [ -x "$dir/bin/java" ]; then
    echo "jdk$major already present: $("$dir/bin/java" -version 2>&1 | head -1)"
    return
  fi
  echo "Fetching JDK $major from Adoptium..."
  local url="https://api.adoptium.net/v3/binary/latest/$major/ga/linux/x64/jdk/hotspot/normal/eclipse"
  curl -fsSL "$url" -o "$JDKS/jdk$major.tar.gz"
  mkdir -p "$dir.tmp"
  tar -xzf "$JDKS/jdk$major.tar.gz" -C "$dir.tmp" --strip-components=1
  mv "$dir.tmp" "$dir"
  rm -f "$JDKS/jdk$major.tar.gz"
  echo "jdk$major ready: $("$dir/bin/java" -version 2>&1 | head -1)"
}

fetch 8
fetch 25

echo ""
echo "JDK8_HOME=$JDKS/jdk8"
echo "JDK25_HOME=$JDKS/jdk25"
