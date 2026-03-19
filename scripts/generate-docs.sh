#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd -- "${PACKAGE_DIR}/.." && pwd)"

SCHEME="Accelera"
OUTPUT_DIR="${REPO_DIR}/accelera-docs"
DERIVED_DATA="${PACKAGE_DIR}/.build/docc-derived"
HOSTING_BASE_PATH="accelera-ios-sdk-spm"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --scheme <name>               Xcode scheme to build. Default: ${SCHEME}
  --output <path>               Static docs output directory. Default: ${OUTPUT_DIR}
  --derived-data <path>         DerivedData directory for docbuild. Default: ${DERIVED_DATA}
  --hosting-base-path <path>    Base path for static hosting. Default: ${HOSTING_BASE_PATH}
  -h, --help                    Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scheme)
      SCHEME="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --derived-data)
      DERIVED_DATA="$2"
      shift 2
      ;;
    --hosting-base-path)
      HOSTING_BASE_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

command -v xcodebuild >/dev/null 2>&1 || {
  echo "xcodebuild is required but was not found." >&2
  exit 1
}

command -v xcrun >/dev/null 2>&1 || {
  echo "xcrun is required but was not found." >&2
  exit 1
}

command -v rsync >/dev/null 2>&1 || {
  echo "rsync is required but was not found." >&2
  exit 1
}

TMP_OUTPUT="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_OUTPUT}"
}
trap cleanup EXIT

mkdir -p "${DERIVED_DATA}"
mkdir -p "${OUTPUT_DIR}"

echo "Building DocC archive for scheme '${SCHEME}'..."
(
  cd "${PACKAGE_DIR}"
  xcodebuild docbuild \
    -scheme "${SCHEME}" \
    -derivedDataPath "${DERIVED_DATA}" \
    -destination 'generic/platform=iOS'
)

# DocC archive location varies between Xcode versions, so resolve it after the build.
ARCHIVE_PATH="$(
  find "${DERIVED_DATA}" -type d \( -name "${SCHEME}.doccarchive" -o -name '*.doccarchive' \) \
    | sort \
    | head -n 1
)"

if [[ -z "${ARCHIVE_PATH}" ]]; then
  echo "Failed to locate a generated .doccarchive under ${DERIVED_DATA}" >&2
  exit 1
fi

echo "Transforming archive for static hosting..."
xcrun docc process-archive transform-for-static-hosting \
  "${ARCHIVE_PATH}" \
  --output-path "${TMP_OUTPUT}" \
  --hosting-base-path "${HOSTING_BASE_PATH}"

touch "${TMP_OUTPUT}/.nojekyll"

# Current DocC output keeps the correct hosting base path in the rendered
# documentation entrypoint, but the root index may still point to "/".
# Reuse the rendered module entrypoint as the site root for GitHub Pages.
if [[ -f "${TMP_OUTPUT}/documentation/accelera/index.html" ]]; then
  cp "${TMP_OUTPUT}/documentation/accelera/index.html" "${TMP_OUTPUT}/index.html"
fi

echo "Syncing generated site into ${OUTPUT_DIR}..."
rsync -a --delete \
  --exclude '.git/' \
  --exclude '.idea/' \
  --exclude 'theme-settings.json' \
  "${TMP_OUTPUT}/" "${OUTPUT_DIR}/"

echo "Docs generated successfully."
echo "Archive: ${ARCHIVE_PATH}"
echo "Output:  ${OUTPUT_DIR}"
