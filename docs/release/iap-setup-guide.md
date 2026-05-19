# IAP 등록 + RevenueCat 매핑 가이드

> 사용자가 "구독 상품정보 없음" 메시지를 보는 이유:
> **ASC 콘솔에 IAP 상품이 등록되지 않았거나 RevenueCat Dashboard 에서 매핑이 안 됨.**
> 코드는 정상 — 이 작업은 외부 콘솔 작업으로만 해결됩니다.

---

## 0. 전제 조건

- [ ] Apple Developer Program **유효** (Airony company inc.)
- [ ] **Paid Applications Agreement** 활성화
  - ASC → 계약/세금/은행 거래 → "Apple App에서의 유료 앱 판매 계약" 체크
  - 세금 정보 (W-8BEN 또는 한국 사업자번호) 입력
  - 은행 정보 입력 → 검증 완료
  - ⚠️ 이 단계가 안 되면 IAP product 자체 등록 안 됨

---

## 1. ASC 에서 IAP Product 등록 (4개)

ASC → 앱 → **인앱 구매** 탭 → "관리" → 좌측 "+" → 유형 선택

### 1.1 Premium 월간 구독
- 유형: **자동 갱신 구독**
- 참조 이름: `Thiscount Premium Monthly`
- 제품 ID: **`thiscount_premium_monthly_ios`**
- 구독 그룹: `thiscount_subscriptions` (없으면 생성)
- 가격: ₩4,900 (한국) — Tier 4
- 현지화 (한국어): "프리미엄 월간" / "하루 30통 발송 + 사진 첨부 + 타워 커스텀"
- 현지화 (영어): "Premium Monthly" / "30 letters/day, photo, tower custom"
- 심사용 스크린샷 1장 + 검토용 메모: "Premium subscription unlocks 30 letters/day + photo attachments + tower customization."

### 1.2 Brand 월간 구독
- 유형: **자동 갱신 구독**
- 참조 이름: `Thiscount Brand Monthly`
- 제품 ID: **`thiscount_brand_monthly_ios`**
- 구독 그룹: `thiscount_subscriptions` (위와 동일)
- 가격: ₩99,000 — Tier 99
- 현지화 (한국어): "브랜드 월간" / "인증 배지 + 하루 200통 + 대량 발송 + Premium 포함"
- 현지화 (영어): "Brand Monthly" / "Verified badge, 200/day, bulk send, includes Premium"
- 스크린샷 + 메모

### 1.3 1개월 선물권
- 유형: **소모성**
- 참조 이름: `Thiscount Gift Card 1 Month`
- 제품 ID: **`thiscount_gift_1month_ios`**
- 가격: ₩3,900 — Tier 3
- 현지화 (한국어): "1개월 선물권" / "친구에게 Premium 1개월 선물"
- 영어: "1-month gift card" / "Gift a friend 1 month of Premium"
- 스크린샷 + 메모

### 1.4 Brand Extra 1000통
- 유형: **소모성**
- 참조 이름: `Brand Extra 1000 Letters`
- 제품 ID: **`thiscount_brand_extra_1000_ios`**
- 가격: ₩9,900 — Tier 9
- 현지화 (한국어): "브랜드 추가 1000통" / "Brand 월 한도에 1000통 추가"
- 영어: "Brand Extra 1000 letters" / "Add 1000 letters to Brand monthly quota"
- 스크린샷 + 메모

각 상품 등록 후 **"제출 준비 완료"** 상태 확인. "메타데이터 누락" 이면 미완성.

---

## 2. RevenueCat Dashboard 매핑

https://app.revenuecat.com → 프로젝트 (Thiscount) → 좌측 메뉴

### 2.1 Products
**Products** 탭 → "+ New" → ASC product 와 1:1 매핑:

| Display name | App Store product ID |
|---|---|
| Premium Monthly | thiscount_premium_monthly_ios |
| Brand Monthly | thiscount_brand_monthly_ios |
| Gift 1 Month | thiscount_gift_1month_ios |
| Brand Extra 1000 | thiscount_brand_extra_1000_ios |

### 2.2 Entitlements
**Entitlements** 탭 → 다음 2개 entitlement 존재 확인:

- `premium` — `thiscount_premium_monthly_ios` 와 `thiscount_brand_monthly_ios` 둘 다 attach (Brand 가 Premium 포함)
- `brand` — `thiscount_brand_monthly_ios` 만 attach

### 2.3 Offerings
**Offerings** 탭 → `default` offering → Packages 안에:

| Package ID | Product |
|---|---|
| `$rc_monthly` (Premium) | thiscount_premium_monthly_ios |
| `brand_monthly` | thiscount_brand_monthly_ios |
| `gift_1month` | thiscount_gift_1month_ios |
| `brand_extra_1000` | thiscount_brand_extra_1000_ios |

`default` offering 이 **"Current"** 상태인지 반드시 확인.

### 2.4 ASC In-App Purchase Key 연결
**Project Settings** → **Apple App Store** → "In-App Purchase Key" 업로드.
- ASC → 사용자 및 액세스 → 통합 → 인앱 구매 → API key (.p8) 발급 → RevenueCat 에 업로드.
- Key ID / Issuer ID 입력.

---

## 3. Sandbox 테스트 (실 결제 전 검증)

### 3.1 Sandbox 사용자 등록
ASC → 사용자 및 액세스 → 샌드박스 사용자 → "+" → 새 Apple ID 생성 (실 이메일 X — 가짜 이메일 가능).

### 3.2 iPhone 에서 Sandbox 로그인
설정 → App Store → 샌드박스 계정 → 위 sandbox Apple ID 로 로그인.

### 3.3 TestFlight 빌드 실행 → 구독 시도
- 구독 화면에서 "프리미엄 구독" → Apple 결제 sheet 떠야 함
- "이것은 샌드박스 결제입니다" 표시 확인
- 결제 완료 → RevenueCat 가 webhook 으로 entitlement 부여 → 앱이 Premium 상태로 전환

---

## 4. 진단 — "상품정보 없음" 이 계속 뜨는 경우

| 증상 | 가능 원인 | 해결 |
|---|---|---|
| 4개 product 모두 안 보임 | Paid Apps Agreement 미체결 | 0번 단계 |
| 일부만 안 보임 | 해당 product 가 "제출 준비 완료" 미달 | 1번 단계의 누락 필드 채우기 |
| ASC 에서는 보이는데 RC 가 못 받음 | RC Products / Offerings 매핑 누락 | 2번 단계 |
| sandbox 결제 안 뜸 | sandbox Apple ID 로그인 안 됨 | 3번 단계 |
| `RC offering null` 디버그 로그 | RC API key 누락 | `.env.local` 의 `REVENUECAT_IOS_KEY` / `REVENUECAT_ANDROID_KEY` 확인 |

---

## 5. 코드 의존 (정보용 — 변경 불필요)

- `lib/core/services/purchase_service.dart` 의 `_RcProductIds` (line 37-104) — ASC product ID 와 1:1 일치 필요
- `_RcEntitlements` (line 31-34) — RC entitlement 이름 (`premium`, `brand`) 과 일치
- `.env.local` — `REVENUECAT_IOS_KEY=appl_...` / `REVENUECAT_ANDROID_KEY=goog_...` 주입

---

**참고**: TestFlight Internal Testing 사용자는 ASC IAP 등록 전에도 베타 사용 가능 — 단 구독/결제 흐름은 제외. 베타 기능은 dart-define `BETA_FREE_PREMIUM=true` 로 무료 Premium 활성화 가능 (단 release 빌드에선 `BETA_DISABLE_IN_RELEASE=true` 로 차단됨).
