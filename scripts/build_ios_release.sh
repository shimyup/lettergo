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

# 베타 테스트 기간 동안 RevenueCat/App Store 연동 없이 Premium을 무료로
# 활성화합니다. 정식 출시 빌드에서는 .env.local 에서 BETA_FREE_PREMIUM 제거.
if [[ "${BETA_FREE_PREMIUM:-false}" == "true" ]]; then
  echo "[ios] BETA_FREE_PREMIUM=true — premium will be granted without purchase."
  DART_DEFINES+=("--dart-define=BETA_FREE_PREMIUM=true")
fi

# 베타 업그레이드 시뮬레이터 — 사용자가 업그레이드 버튼을 누르면 RevenueCat
# 에 실제 결제 요청 안 보내고 즉시 Premium/Brand 활성화. App Store Connect
# 상품 미등록 상태에서도 베타 테스터가 흐름을 끝까지 체험 가능.
# Default true (베타 기간) — 정식 출시 시 .env.local 에서 명시적으로
# `BETA_UPGRADE_SIMULATOR=false` 로 끄거나 키 자체 제거.
if [[ "${BETA_UPGRADE_SIMULATOR:-true}" == "true" ]]; then
  echo "[ios] BETA_UPGRADE_SIMULATOR=true — upgrade will be granted without purchase."
  DART_DEFINES+=("--dart-define=BETA_UPGRADE_SIMULATOR=true")
fi

# 베타 테스트 관리자 이메일 — 릴리스 빌드에서도 이 이메일만 관리자 패널/브랜드
# 권한 활성. 정식 출시 시 .env.local 에서 BETA_ADMIN_EMAIL 제거하면 자동 잠김.
if [[ -n "${BETA_ADMIN_EMAIL:-}" ]]; then
  echo "[ios] BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}"
  DART_DEFINES+=("--dart-define=BETA_ADMIN_EMAIL=${BETA_ADMIN_EMAIL}")
fi

# Resend 이메일 프로바이더 (OTP 실제 발송).
# 설정되면 EmailService.isConfigured=true → auth_screen 의 on-screen OTP
# fallback 이 자동으로 숨겨지고 실제 이메일이 발송됨.
if [[ -n "${RESEND_API_KEY:-}" && -n "${RESEND_FROM_EMAIL:-}" ]]; then
  echo "[ios] RESEND configured: ${RESEND_FROM_EMAIL}"
  DART_DEFINES+=("--dart-define=RESEND_API_KEY=${RESEND_API_KEY}")
  DART_DEFINES+=("--dart-define=RESEND_FROM_EMAIL=${RESEND_FROM_EMAIL}")
fi

# SendGrid 이메일 프로바이더 (폴백).
if [[ -n "${SENDGRID_API_KEY:-}" && -n "${SENDGRID_FROM_EMAIL:-}" ]]; then
  echo "[ios] SENDGRID configured: ${SENDGRID_FROM_EMAIL}"
  DART_DEFINES+=("--dart-define=SENDGRID_API_KEY=${SENDGRID_API_KEY}")
  DART_DEFINES+=("--dart-define=SENDGRID_FROM_EMAIL=${SENDGRID_FROM_EMAIL}")
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
