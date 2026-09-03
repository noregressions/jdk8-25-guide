#!/usr/bin/env bash
# Makes JDK 8 and JDK 25 available to the discovery-tests harness.
#
# Prefers JDKs already installed on this machine and only downloads from Adoptium
# when it has to. Safe to re-run.
#
#   ./setup/download-jdks.sh          # find or fetch both
#   ./setup/download-jdks.sh --force  # ignore local installs, always download
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JDKS="$ROOT/.jdks"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# --- Platform detection -------------------------------------------------------
# The Adoptium API needs an explicit os/arch. Getting this wrong is silent: you
# receive a valid tarball for the wrong platform and only find out when a binary
# fails to execute.
case "$(uname -s)" in
  Darwin) OS=mac ;;
  Linux)  OS=linux ;;
  CYGWIN*|MINGW*|MSYS*) OS=windows ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) ARCH=x64 ;;
  arm64|aarch64) ARCH=aarch64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
echo "Platform: $OS/$ARCH"

major_of() {
  local out ver
  out="$("$1/bin/java" -version 2>&1)" || return 1
  ver="$(printf '%s\n' "$out" | sed -n 's/.*version "\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || return 1
  ver="${ver#1.}"
  printf '%s\n' "$ver" | sed 's/[^0-9].*//'
}

# A JDK counts as ready only if it RUNS and reports the version we wanted. The
# previous version of this script reported "ready" purely on the tarball having
# extracted, which meant a wrong-platform download looked like a success.
verify() {
  local dir="$1"
  local major="$2"
  local got
  [ -x "$dir/bin/java" ] || { echo "  no bin/java in $dir" >&2; return 1; }
  got="$(major_of "$dir" 2>/dev/null)" || { echo "  $dir/bin/java will not execute on $OS/$ARCH" >&2; return 1; }
  [ "$got" = "$major" ] || { echo "  $dir reports JDK $got, expected $major" >&2; return 1; }
  return 0
}

fetch_to() {  # fetch_to <major> <os> <arch> <dest>
  local major="$1"
  local os="$2"
  local arch="$3"
  local dest="$4"
  local url="https://api.adoptium.net/v3/binary/latest/$major/ga/$os/$arch/jdk/hotspot/normal/eclipse"
  local tgz="$JDKS/jdk$major.tar.gz"
  echo "  fetching Temurin $major for $os/$arch..."
  if ! curl -fsSL "$url" -o "$tgz"; then
    rm -f "$tgz"
    return 1
  fi
  rm -rf "$dest.tmp"; mkdir -p "$dest.tmp"
  # macOS bundles ship as Contents/Home; strip to the same shape as Linux tarballs.
  tar -xzf "$tgz" -C "$dest.tmp" --strip-components=1 || { rm -rf "$dest.tmp" "$tgz"; return 1; }
  rm -f "$tgz"
  if [ -d "$dest.tmp/Contents/Home" ]; then
    mv "$dest.tmp/Contents/Home" "$dest.tmp.home"
    rm -rf "$dest.tmp"; mv "$dest.tmp.home" "$dest.tmp"
  fi
  rm -rf "$dest"; mv "$dest.tmp" "$dest"
}

provide() {
  local major="$1"
  local dir="$JDKS/jdk$major"
  local found
  mkdir -p "$JDKS"
  echo "JDK $major:"

  if [ "$FORCE" = "0" ]; then
    if found="$("$ROOT/setup/find-jdk.sh" "$major" 2>/dev/null)"; then
      echo "  using local install: $found"
      echo "  $("$found/bin/java" -version 2>&1 | head -1)"
      printf '%s\n' "$found" > "$JDKS/jdk$major.path"
      return 0
    fi
    echo "  no local JDK $major found; downloading"
  fi

  if fetch_to "$major" "$OS" "$ARCH" "$dir" && verify "$dir" "$major"; then
    echo "  ready: $("$dir/bin/java" -version 2>&1 | head -1)"
    printf '%s\n' "$dir" > "$JDKS/jdk$major.path"
    return 0
  fi

  # Adoptium publishes no JDK 8 for macOS aarch64. Fall back to the x64 build,
  # which runs under Rosetta 2 -- but say so, rather than leaving a mystery.
  if [ "$OS" = "mac" ] && [ "$ARCH" = "aarch64" ]; then
    echo "  no Temurin $major build exists for mac/aarch64; trying mac/x64 under Rosetta"
    if fetch_to "$major" mac x64 "$dir" && verify "$dir" "$major"; then
      echo "  ready (x64 under Rosetta): $("$dir/bin/java" -version 2>&1 | head -1)"
      printf '%s\n' "$dir" > "$JDKS/jdk$major.path"
      return 0
    fi
    rm -rf "$dir"
    cat >&2 <<MSG

Could not provide JDK $major.

Temurin has no mac/aarch64 build for JDK $major, and the mac/x64 fallback did not
run here -- Rosetta 2 is probably not installed ("softwareupdate --install-rosetta").

The better fix on Apple Silicon is a native JDK $major from a vendor that builds one:

    sdk install java 8.0.482-zulu        # or: brew install --cask corretto8

Then re-run this script, or point the harness straight at it:

    JDK${major}_HOME=/path/to/jdk$major ./run-all.sh
MSG
    return 1
  fi

  rm -rf "$dir"
  echo "  FAILED to provide a working JDK $major for $OS/$ARCH" >&2
  return 1
}

rc=0
provide 8  || rc=1
provide 25 || rc=1
echo ""
if [ "$rc" = "0" ]; then
  echo "Both JDKs available. Run ./run-all.sh"
else
  echo "Setup incomplete -- see the messages above." >&2
fi
exit $rc
