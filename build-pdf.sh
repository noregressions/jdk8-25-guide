#!/usr/bin/env bash
#
# build-pdf.sh -- build the JDK 8 -> JDK 25 migration guide to PDF with Paperband.
#
# Usage:
#   ./build-pdf.sh                              # -> dist/jdk8-to-jdk25-migration-guide.pdf, "classical" theme
#   ./build-pdf.sh --theme herodevs             # use a different bundled theme
#   ./build-pdf.sh --output out/draft.pdf       # custom output path
#   ./build-pdf.sh --watermark DRAFT            # anything else is passed straight through to `paperband build`
#
# Requires a checkout of the paperband tool itself, built at least once
# (`mvn -DskipTests package` inside it). By default this script looks for it
# as a sibling directory named "paperband" next to this guide's repo;
# override with PAPERBAND_HOME.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUIDE_DIR="$SCRIPT_DIR/guide"

THEME="classical"
OUTPUT="$SCRIPT_DIR/dist/jdk8-to-jdk25-migration-guide.pdf"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme)
      THEME="$2"
      shift 2
      ;;
    --output|-o)
      OUTPUT="$2"
      shift 2
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ! -d "$GUIDE_DIR" ]]; then
  echo "error: guide directory not found at $GUIDE_DIR" >&2
  exit 1
fi

if [[ ! -f "$GUIDE_DIR/paperband.yaml" ]]; then
  echo "error: $GUIDE_DIR/paperband.yaml is missing - this is the book root Paperband needs" >&2
  exit 1
fi

# Locate the paperband checkout.
PAPERBAND_HOME="${PAPERBAND_HOME:-$SCRIPT_DIR/../paperband}"

if [[ ! -d "$PAPERBAND_HOME" ]]; then
  echo "error: no paperband checkout found at $PAPERBAND_HOME" >&2
  echo "       set PAPERBAND_HOME to point at your paperband clone, e.g.:" >&2
  echo "       PAPERBAND_HOME=/path/to/paperband ./build-pdf.sh" >&2
  exit 1
fi

# The shaded CLI jar is currently produced by the "cli" module (no
# "paperband-" artifactId prefix yet) as "cli-<version>-all.jar"; matching on
# "*-all.jar" instead of a hardcoded artifactId keeps this working if that
# module is ever renamed.
JAR="$(find "$PAPERBAND_HOME" -maxdepth 3 -name '*-all.jar' 2>/dev/null | head -n1)"

if [[ -z "$JAR" ]]; then
  echo "paperband-cli shaded jar not found under $PAPERBAND_HOME - building it now (mvn -DskipTests package)..."
  ( cd "$PAPERBAND_HOME" && mvn -DskipTests package )
  JAR="$(find "$PAPERBAND_HOME" -maxdepth 3 -name '*-all.jar' 2>/dev/null | head -n1)"
fi

if [[ -z "$JAR" ]]; then
  echo "error: still couldn't find the paperband-cli shaded jar after building" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

echo "Building guide -> $OUTPUT  (theme: $THEME)"
# The ${arr[@]+"${arr[@]}"} idiom avoids "unbound variable" under `set -u`
# when EXTRA_ARGS is empty, on bash versions predating 4.4 (e.g. macOS's
# stock /bin/bash 3.2).
java -jar "$JAR" build "$GUIDE_DIR" "$OUTPUT" --theme "$THEME" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}

echo "Done: $OUTPUT"
