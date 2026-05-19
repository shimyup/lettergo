#!/usr/bin/env bash
# 한 줄로 TestFlight 까지 자동화:
#   ./scripts/release_to_testflight.sh
#
# 단계:
#   1. .env.local BETA 플래그 release 모드로 임시 변경 (자동 backup)
#   2. ExportOptions plist 준비 (signingStyle=manual, profile "Thiscount App Store")
#   3. build_ios_release.sh — archive + IPA export
#   4. xcrun altool upload — ASC delivery
#   5. asc_assign_to_internal.py — Internal Testing 그룹 자동 추가
#   6. .env.local 원복
#
# 환경변수 override (선택):
#   ASC_API_KEY_ID, ASC_API_ISSUER_ID, ASC_API_KEY_PATH (build script 와 동일)
#   SKIP_GROUP_ASSIGN=1 → 그룹 자동 추가 스킵 (build + upload 만)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.local"
PUBSPEC="$ROOT_DIR/pubspec.yaml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ $ENV_FILE 없음 — release 빌드 불가." >&2
  exit 1
fi

# pubspec 의 build 번호 추출 (e.g. "version: 1.0.0+310" → "310")
BUILD_NUM=$(grep -E "^version:" "$PUBSPEC" | sed -E 's/.*\+([0-9]+).*/\1/')
if [[ -z "$BUILD_NUM" ]]; then
  echo "❌ pubspec build number 파싱 실패." >&2
  exit 1
fi
echo "==[ Build $BUILD_NUM 출시 파이프라인 시작 ]=="

# 1) .env.local backup + release 모드 플립
BACKUP="/tmp/env.local.bak.$BUILD_NUM"
cp "$ENV_FILE" "$BACKUP"
echo "[env] backup → $BACKUP"

python3 - <<PY
with open("$ENV_FILE", "r") as f: c = f.read()
c = c.replace("BETA_DISABLE_IN_RELEASE=false", "BETA_DISABLE_IN_RELEASE=true")
c = c.replace("BETA_FREE_PREMIUM=true", "BETA_FREE_PREMIUM=false")
import re
c = re.sub(r"BETA_ADMIN_EMAIL=.+", "BETA_ADMIN_EMAIL=", c)
with open("$ENV_FILE", "w") as f: f.write(c)
PY
echo "[env] release 모드 적용:"
grep "^BETA_" "$ENV_FILE" | sed 's/^/  /'

# 빌드/업로드 실패 시 .env.local 원복 보장
trap 'cp "$BACKUP" "$ENV_FILE"; echo "[env] 원복 (trap)"' EXIT

# 2) ExportOptions plist 준비
EXPORT_PLIST="/tmp/ExportOptions-${BUILD_NUM}.plist"
if [[ ! -f "$EXPORT_PLIST" ]]; then
  TEMPLATE="/tmp/ExportOptions-303.plist"
  if [[ ! -f "$TEMPLATE" ]]; then
    TEMPLATE="$ROOT_DIR/ios/ExportOptions-AppStore.plist"
  fi
  if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$EXPORT_PLIST"
    echo "[plist] $EXPORT_PLIST (template: $TEMPLATE)"
  else
    echo "❌ ExportOptions template 없음. /tmp/ExportOptions-303.plist 또는 ios/ExportOptions-AppStore.plist 필요" >&2
    exit 1
  fi
fi

# 3) Build + archive + IPA export
echo ""
echo "==[ 1/3 IPA 빌드 ]=="
IOS_BUILD_MODE=ipa IOS_EXPORT_OPTIONS_PLIST="$EXPORT_PLIST" \
  "$ROOT_DIR/scripts/build_ios_release.sh"

IPA_PATH="$ROOT_DIR/build/ios/ipa/Thiscount.ipa"
if [[ ! -f "$IPA_PATH" ]]; then
  echo "❌ IPA not found: $IPA_PATH" >&2
  exit 1
fi

# 4) altool upload
echo ""
echo "==[ 2/3 TestFlight 업로드 ]=="
ASC_KEY_ID="${ASC_API_KEY_ID:-PPC3B3JS5V}"
ASC_ISSUER_ID="${ASC_API_ISSUER_ID:-1cfdd647-e5d9-4f98-bcd6-fff8299f80ec}"
xcrun altool --upload-app -f "$IPA_PATH" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

# 5) Internal Testing 그룹 자동 추가
if [[ "${SKIP_GROUP_ASSIGN:-0}" == "1" ]]; then
  echo "[asc-assign] SKIP_GROUP_ASSIGN=1 — 자동 그룹 추가 스킵"
else
  echo ""
  echo "==[ 3/3 Internal 그룹 자동 추가 ]=="
  python3 "$ROOT_DIR/scripts/asc_assign_to_internal.py" "$BUILD_NUM" || \
    echo "⚠️  asc_assign 실패 (빌드/업로드는 성공). 콘솔에서 수동 추가 가능."
fi

# 6) .env.local 원복 (trap 도 안전망)
cp "$BACKUP" "$ENV_FILE"
trap - EXIT
echo ""
echo "==[ ✅ 완료 ]=="
echo "[env] $ENV_FILE 원복"
echo "Build $BUILD_NUM → TestFlight Internal Testing 자동 분배 진행 중."
