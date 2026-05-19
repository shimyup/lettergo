# Breach Response Runbook

Build 302 (Privacy audit) — GDPR Art.33 / KISA 정보통신망법 통지 의무 대응.

## 통지 의무 요약

| 법규 | 통지 대상 | 시한 |
|---|---|---|
| GDPR Art.33 | 감독기관 (해당 회원국 DPA) | **72시간 이내** |
| GDPR Art.34 | 영향받은 정보주체 (high risk) | 지체 없이 (실현 가능한 한 빠르게) |
| KISA 정보통신망법 §27-3 | 방통위·이용자 | **24시간 이내** (KR 사용자 1만명 이상 영향 시) |

## Severity 분류

- **P0 (즉시)**: 비밀번호 해시 / OTP secret / API key / 결제 정보 노출. Firestore rules write 우회 발견.
- **P1 (24h)**: 평문 이메일/전화번호 노출. Letter body 대량 leak. 다른 사용자 doc 변조 가능 (anonymous Firebase Auth).
- **P2 (72h)**: 부분 logger leak. session 정보 한 사용자 단위 노출. Coarse-grained location leak.

## 즉시 절차 (0–4 시간)

1. **감지** — Crashlytics / Sentry 알람, RC 비정상 트래픽, Firebase Auth 비정상 로그인, 사용자 제보.
2. **격리** — 영향받은 API key revoke (Firebase / RC / Resend / SendGrid / Twilio / Stadia). 
   - Firebase Console → Project Settings → SDK setup → regenerate
   - RC dashboard → API keys → revoke
3. **로그 보존** — Firestore audit log, Crashlytics events, ASC sandbox/prod logs. tamper-proof copy (S3 + glacier).
4. **사용자 영향 추정** — `users/` collection 의 영향받은 doc id 범위. 가능 시 sentCount/receivedCount 등 카운터로 활동성 추정.

## 통지 절차 (4–72 시간)

### GDPR Art.33 (EU 감독기관)
- 한국 회사이지만 EU 사용자 대상 처리 시 GDPR 적용 → 사용자가 거주하는 회원국 또는 lead supervisory authority 에 통지.
- 통지 내용: 사고 성격, 영향받은 카테고리/수, 추정 영향, 완화 조치, DPO 연락처.
- 양식: 각 회원국 DPA 웹사이트 (예: CNIL France, BfDI Germany).

### KISA 방통위 통지
- 24시간 이내 KISA 신고: https://privacy.kisa.or.kr/
- 동시에 이메일 알림: 영향받은 사용자에게 개별 통보 (ceo@airony.xyz 발송, Resend 사용).

### 사용자 통보
- 영향 사용자에게 in-app 모달 + 이메일.
- 메시지 템플릿 (KR/EN): `docs/security/breach-user-notice-template.md` (별도 작성 필요)

## 사후 (1–4 주)

1. **포렌식** — 침해 경로 재현, 코드 패치, regression test.
2. **rules 재검토** — Firestore/Storage rules audit (3rd-party).
3. **사용자 신뢰 회복** — public post-mortem (영향 범위, 원인, 대응, 후속 조치). marketingSite/blog.
4. **법규 후속** — 감독기관 follow-up, 사용자 보상 (필요시).

## 연락처

- **개인정보 담당자**: ceo@airony.xyz
- **법무 자문**: (별도 위임 변호사 — Airony 결정)
- **호스팅 / 인프라**: Firebase Console, RevenueCat dashboard, Cloudflare/Vercel (정적 호스팅)
- **외부 처리자 비상연락**: Resend / SendGrid / Twilio / Stadia Maps 의 incident SLA 응답 채널

## 출시 전 준비

- [ ] 모든 비상 API key 회전 (rotation) 절차 문서화
- [ ] 사용자 통보 템플릿 KR/EN 작성
- [ ] 침해 시뮬레이션 (tabletop) 1회 — Build 290 이후 미실시
- [ ] 감독기관 통지 양식 사전 다운로드
