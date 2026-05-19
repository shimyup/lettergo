#!/usr/bin/env python3
"""
방금 업로드한 빌드 (또는 인자로 지정한 버전) 를 TestFlight Internal
Testing 그룹에 자동 추가.

호출:
  python3 scripts/asc_assign_to_internal.py            # pubspec 의 build 번호 사용
  python3 scripts/asc_assign_to_internal.py 310        # 명시적 버전

Apple ASC API 의 `hasAccessToAllBuilds` 토글은 UI 전용 (PATCH 거부).
그래서 매 빌드마다 명시적 POST 로 그룹 relationships 추가하는 패턴.

전제:
  - pip install pyjwt cryptography (이미 설치되어 있어야 함)
  - ASC API Key (.p8) 가 $HOME/private_keys/AuthKey_{KEY_ID}.p8
  - ASC_KEY_ID / ASC_ISSUER_ID / BUNDLE_ID 는 env var 로 override 가능

build_ios_release.sh 마지막에 호출 — altool upload 가 끝나면 ASC 가
빌드 등록까지 30초~ 수분 걸리므로 retry 루프 내장.
"""
import json
import os
import re
import sys
import time
import urllib.request
import urllib.error

try:
    import jwt  # pyjwt
except ImportError:
    print("❌ pyjwt 누락. `pip3 install pyjwt cryptography` 후 재시도.")
    sys.exit(0)  # 빌드 자체는 성공으로 둠

ASC_KEY_ID = os.environ.get("ASC_API_KEY_ID", "PPC3B3JS5V")
ASC_ISSUER_ID = os.environ.get(
    "ASC_API_ISSUER_ID", "1cfdd647-e5d9-4f98-bcd6-fff8299f80ec"
)
BUNDLE_ID = os.environ.get("ASC_BUNDLE_ID", "io.thiscount")
KEY_PATH = os.environ.get(
    "ASC_API_KEY_PATH",
    os.path.expanduser(f"~/private_keys/AuthKey_{ASC_KEY_ID}.p8"),
)

# 업로드 후 ASC 가 빌드를 인덱스하기까지 retry — 최대 ~10분.
MAX_RETRIES = 20
RETRY_DELAY_SEC = 30


def detect_build_version():
    """pubspec.yaml 의 build number 추출."""
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(root, "pubspec.yaml"), "r") as f:
        for line in f:
            m = re.match(r"^version:\s*\S+\+(\d+)", line.strip())
            if m:
                return m.group(1)
    return None


target = sys.argv[1] if len(sys.argv) > 1 else detect_build_version()
if not target:
    print("❌ build version 찾을 수 없음. 인자로 명시: `... 310`")
    sys.exit(0)

if not os.path.exists(KEY_PATH):
    print(f"⚠️  ASC API key 없음: {KEY_PATH} — 자동 그룹 추가 스킵")
    sys.exit(0)

with open(KEY_PATH, "r") as f:
    private_key = f.read()

token = jwt.encode(
    {
        "iss": ASC_ISSUER_ID,
        "iat": int(time.time()),
        "exp": int(time.time()) + 600,
        "aud": "appstoreconnect-v1",
    },
    private_key,
    algorithm="ES256",
    headers={"kid": ASC_KEY_ID, "typ": "JWT"},
)


def http(method, url, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            text = r.read().decode()
            return r.status, (json.loads(text) if text else {})
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode(errors="ignore") or "{}")


# 1) App ID
_, apps = http(
    "GET",
    f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={BUNDLE_ID}",
)
data = apps.get("data") or []
if not data:
    print(f"⚠️  app {BUNDLE_ID} 없음 — 자동 그룹 추가 스킵")
    sys.exit(0)
app_id = data[0]["id"]

# 2) Internal 그룹 list
_, groups = http(
    "GET",
    f"https://api.appstoreconnect.apple.com/v1/betaGroups"
    f"?filter[app]={app_id}&limit=20",
)
internal = [
    g for g in groups.get("data", [])
    if g["attributes"].get("isInternalGroup")
]
if not internal:
    print("⚠️  Internal Testing 그룹 없음 — 콘솔에서 생성 필요. 스킵.")
    sys.exit(0)

# 3) 빌드 retry (upload 직후엔 ASC 인덱스 지연 가능)
build_id = None
for attempt in range(MAX_RETRIES):
    _, builds = http(
        "GET",
        f"https://api.appstoreconnect.apple.com/v1/builds"
        f"?filter[app]={app_id}&filter[version]={target}&limit=1",
    )
    if builds.get("data"):
        build_id = builds["data"][0]["id"]
        state = builds["data"][0]["attributes"].get("processingState")
        print(
            f"✓ Build {target} 발견  id={build_id}  state={state} "
            f"({attempt+1}/{MAX_RETRIES} 시도)"
        )
        break
    print(f"  Build {target} 아직 ASC 에 없음. {RETRY_DELAY_SEC}s 후 재시도...")
    time.sleep(RETRY_DELAY_SEC)

if not build_id:
    print(f"⚠️  Build {target} 가 {MAX_RETRIES} 회 재시도 후에도 ASC 에 없음 — 스킵")
    sys.exit(0)

# 4) 각 internal 그룹에 build 추가
ok_any = False
for g in internal:
    gid = g["id"]
    gname = g["attributes"]["name"]
    status, resp = http(
        "POST",
        f"https://api.appstoreconnect.apple.com/v1/betaGroups/{gid}/relationships/builds",
        body={"data": [{"type": "builds", "id": build_id}]},
    )
    if status in (200, 201, 204):
        print(f"✓ Build {target} → '{gname}' 그룹 추가")
        ok_any = True
    elif status == 409 or (
        resp.get("errors") and any(
            "already" in (e.get("detail", "") or "").lower()
            for e in resp.get("errors", [])
        )
    ):
        print(f"ℹ Build {target} 이미 '{gname}' 에 있음")
        ok_any = True
    else:
        print(f"❌ '{gname}' 추가 실패 ({status}): {json.dumps(resp)[:300]}")

if not ok_any:
    print("⚠️  어떤 그룹에도 추가 안 됨.")
    sys.exit(0)
