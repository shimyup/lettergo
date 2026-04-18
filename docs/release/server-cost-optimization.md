# 서버 비용·성능 최적화 (Build 75)

Last updated: 2026-04-18

Build 74 까지의 30 초 단일 폴링 구조가 타겟 MAU 기준 월 ~$1,400 수준의
Firestore 읽기 비용을 발생시켜 Build 75 에서 적응형 + 분리형 구조로
재설계했습니다. 아래는 변경 내역과 예상 비용 감소 요약.

---

## 주요 최적화

### 1) 폴링 주기 분리 + 적응형
| 대상 | 기존 | 신규 |
|------|------|------|
| 편지 수신 (처음 5 분) | 30 초 | **30 초** (빠르게 체감) |
| 편지 수신 (5 분 이후) | 30 초 | **90 초** (약 3 배 축소) |
| 지도 타워 | 30 초 | **180 초** (약 6 배 축소) |

### 2) 백그라운드 일시정지
- `WidgetsBindingObserver.didChangeAppLifecycleState` 훅 연동
- 앱이 백그라운드·detached 로 전환 → `pauseServerSyncForBackground()` →
  Firestore 호출 완전 차단
- 포그라운드 복귀 → `resumeServerSyncFromBackground()` → 즉시 1 회 fetch
  후 정상 주기 재개
- 평균 사용자가 하루 2 시간만 포그라운드 → 실제 호출 수 약 92 % 감소

### 3) 페이지 크기 축소
- 수신 편지: 50 → **20** (새 편지는 주기 사이 거의 없음)
- 지도 사용자: 100 유지 (첫 페이지에서 주요 타워 다 담음)

### 4) 중복 체크 O(n) → O(1)
- `_seenLetterIds: Set<String>` 세션 캐시 도입
- 기존 `_inbox.any((l) => l.id == letter.id)` 를 `_seenLetterIds.contains(id)` 로
- 50 편지 × 3 리스트 = 150 비교/call → 1 비교/call 로 감소
- CPU · 배터리 · 성능 모두 개선

---

## 예상 비용 감소 (40K MAU · Firestore Seoul 기준)

| 구분 | Build 74 | Build 75 | 절감 |
|------|----------|----------|------|
| 편지 수신 리드 | ~720M/day | ~90M/day | **87 %** |
| 지도 타워 리드 | ~480M/day | ~80M/day | **83 %** |
| 총 Firestore 월 비용 | $1,400 | **$220~350** | **75~84 %** |
| MAU당 비용 | $0.035 | **$0.006~0.009** | 75 % 이하 |

### 단계별 예상 (월 비용)
| 단계 | MAU | Build 74 | **Build 75** |
|------|-----|----------|-------------|
| 베타 | 25 | $1 | **$1** |
| 소프트 런칭 | 3K | $70 | **$15** |
| 성장기 | 15K | $280 | **$60** |
| 타겟 | 40K | $1,400 | **$300** |
| 스케일 | 100K | $3,500 | **$750** |

---

## 추가 최적화 여지 (향후)

### Step 1 — FCM 푸시 (10K MAU 돌파 시 권장)
- 폴링 전체 제거 가능 → 월 비용 추가 90 % 절감 예상
- Cloud Functions 트리거로 편지 생성 시 수신자에게 푸시
- 구현 예상: 1~2 일 작업

### Step 2 — Firestore 리슨 (웹/데스크톱 포함)
- `snapshots()` 실시간 리스너 사용
- 모바일에서는 FCM 이 우월하므로 부차적

### Step 3 — 서버리스 배치 (50K MAU 돌파 시)
- 자주 쓰는 집계값(최근 편지 수, 월드 지표)을 Cloud Functions 로 사전
  계산해 읽기 수 대폭 감소

### Step 4 — 지역 기반 분산
- Firestore 멀티리전 세팅으로 글로벌 지연 감소

---

## 모니터링 대시보드 (월 1회 점검 권장)

Firebase Console → Usage and billing → Details & settings 에서:
- Firestore Reads / Writes / Storage
- Cloud Storage Bandwidth
- Cloud Messaging (FCM)
- Authentication 활성 사용자

월간 예산 알림 설정:
- Firebase Console → Usage and billing → Modify plan → 알림 임계 $100 / $500 / $1000

---

## Firestore Security Rules 배포

규칙이 아직 배포되지 않은 경우 관리자 기능이 작동하지 않습니다.

### CLI 방식 (권장)
```bash
# 1. 저장소 루트에서
cd /Users/shimyup/Documents/New\ project/Lettergo

# 2. Firebase 로그인 (세션 만료된 경우)
firebase login --reauth

# 3. firestore.rules 안의 'REPLACE_WITH_YOUR_UID_HERE' 를 본인 UID 로 교체

# 4. 규칙만 배포
firebase deploy --only firestore:rules

# 5. 인덱스 배포 (선택, 미리 만들어두면 쿼리 성능 향상)
firebase deploy --only firestore:indexes
```

### Web Console 방식
`docs/release/firestore-rules-setup.md` 참조.
