#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env.local}"
PRECHECK_SCRIPT="$ROOT_DIR/scripts/release_preflight.sh"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "[env] missing required variable: $name" >&2
    echo "[env] copy .env.example to .env.local and fill values." >&2
    exit 1
  fi
}

require_var FIREBASE_PROJECT_ID
require_var FIREBASE_API_KEY
require_var FIREBASE_STORAGE_BUCKET
require_var REVENUECAT_IOS_KEY
require_var REVENUECAT_ANDROID_KEY

require_ios_signing_ready() {
  local identity_count
  identity_count="$(security find-identity -v -p codesigning 2>/dev/null | awk '/valid identities found/ {print $1}' | tail -n1)"
  identity_count="${identity_count:-0}"
  if [[ "$identity_count" == "0" ]]; then
    echo "[ios] WARN: no code signing identity detected via security CLI." >&2
    echo "[ios] Xcode-managed signing may still work; continuing to build IPA." >&2
  fi

  local profiles_dir="${HOME}/Library/MobileDevice/Provisioning Profiles"
  if [[ ! -d "$profiles_dir" ]] || ! ls "$profiles_dir"/*.mobileprovision >/dev/null 2>&1; then
    echo "[ios] WARN: no provisioning profiles found in default directory." >&2
    echo "[ios] Xcode-managed signing may still resolve profiles during archive/export." >&2
  fi
}

if [[ -x "$PRECHECK_SCRIPT" ]]; then
  "$PRECHECK_SCRIPT"
else
  echo "[preflight] missing executable: $PRECHECK_SCRIPT" >&2
  exit 1
fi

DART_DEFINES=(
  "--dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
  "--dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY}"
  "--dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}"
  "--dart-define=REVENUECAT_IOS_KEY=${REVENUECAT_IOS_KEY}"
  "--dart-define=REVENUECAT_ANDROID_KEY=${REVENUECAT_ANDROID_KEY}"
)

if [[ -n "${STADIA_MAPS_API_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=STADIA_MAPS_API_KEY=${STADIA_MAPS_API_KEY}")
fi

cd "$ROOT_DIR"

IOS_BUILD_MODE="${IOS_BUILD_MODE:-app}"
IOS_EXPORT_OPTIONS_PLIST="${IOS_EXPORT_OPTIONS_PLIST:-}"

if [[ "$IOS_BUILD_MODE" == "ipa" ]]; then
  require_ios_signing_ready
  echo "[ios] building signed IPA for TestFlight..."
  if [[ -n "$IOS_EXPORT_OPTIONS_PLIST" ]]; then
    flutter build ipa --release \
      --export-options-plist "$IOS_EXPORT_OPTIONS_PLIST" \
      "${DART_DEFINES[@]}" "$@"
  else
    flutter build ipa --release "${DART_DEFINES[@]}" "$@"
  fi
  shopt -s nullglob
  ipa_files=("$ROOT_DIR"/build/ios/ipa/*.ipa)
  shopt -u nullglob
  if (( ${#ipa_files[@]} == 0 )); then
    echo "[ios] ERROR: IPA was not generated." >&2
    echo "[ios] Check Apple account sign-in, iOS Distribution certificate," >&2
    echo "[ios] and provisioning profile in Xcode (Signing & Capabilities)." >&2
    exit 1
  fi
  echo "[ios] artifacts:"
  ls -lh "${ipa_files[@]}"
else
  echo "[ios] building unsigned Runner.app for local QA..."
  flutter build ios --release --no-codesign "${DART_DEFINES[@]}" "$@"
  echo "[ios] artifacts:"
  ls -lh "$ROOT_DIR/build/ios/iphoneos/Runner.app"
fi
