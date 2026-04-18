# Release Notes — Build 78 (1.0.0+78)

Date: 2026-04-19

---

## Korean (한국어)

**인증 이메일 실제 발송 활성화 (Resend 연동)**

- Resend 이메일 서비스를 기본 프로바이더로 연동했습니다
- OTP 인증 코드가 실제 이메일로 발송되기 시작 (airony.xyz 도메인 검증
  완료 후 자동 작동)
- 기존 SendGrid 코드는 폴백으로 유지 — Resend 실패 시 자동 전환

**테스터 경험 변화**

- 발신 도메인(airony.xyz) 검증 완료 후: 가입 시 실제 메일함에
  `Letter Go 인증 코드` 메일 도착 → 오렌지 박스 자동 숨김
- 도메인 검증 진행 중: Build 77 과 동일하게 화면에 코드 직접 표시 (안전망)

---

## English

**Real OTP Email Delivery Enabled (Resend Integration)**

- Added Resend as the primary email provider
- OTP verification codes now sent via real email once the airony.xyz
  domain is verified in Resend
- Legacy SendGrid code retained as automatic fallback

**Tester Behavior**

- Once domain is verified: real inbox delivery of "Letter Go Verification
  Code" emails → on-screen OTP callout auto-hides
- Before domain verification: Build 77 behavior — code shown directly
  on the signup screen (safety net)

---

## Japanese (日本語)

**認証メール実送信有効化 (Resend 連携)**

- Resend メールサービスをメインプロバイダとして連携
- OTP 認証コードが実際のメールで送信開始 (airony.xyz ドメイン検証完了後)
- 従来の SendGrid コードはフォールバックとして維持

---

## Chinese (中文)

**认证邮件实际发送启用 (Resend 集成)**

- 将 Resend 邮件服务作为主要提供商集成
- OTP 验证码现在通过真实邮件发送 (airony.xyz 域名验证完成后)
- 原有 SendGrid 代码保留作为自动回退

---

## Changes in this Build

### Code
- `lib/core/config/firebase_config.dart`:
  - `resendApiKey` + `resendFromEmail` dart-define constants
  - `isResendEnabled` getter
  - `isEmailProviderEnabled` unified check (Resend OR SendGrid)
- `lib/core/services/email_service.dart`:
  - `EmailService.isConfigured` now checks `isEmailProviderEnabled`
  - `sendOtp()` tries Resend first (`_sendViaResend`), falls back to
    SendGrid (`_sendViaSendgrid`) if Resend fails and SendGrid is
    configured
  - Resend API: POST https://api.resend.com/emails with
    `{from: "Letter Go <ceo@airony.xyz>", to: [...], subject, html, text}`
  - Both provider paths emit debugPrint logs in debug builds

### Build pipeline
- `scripts/build_ios_release.sh` + `build_android_release.sh`:
  - Inject `RESEND_API_KEY` / `RESEND_FROM_EMAIL` when set
  - Inject `SENDGRID_API_KEY` / `SENDGRID_FROM_EMAIL` when set
  - Both log to build output for verification

### Config
- `.env.local` (gitignored): added `RESEND_API_KEY` +
  `RESEND_FROM_EMAIL=ceo@airony.xyz`

### Version
- `pubspec.yaml`: 1.0.0+77 → 1.0.0+78

---

## Artifacts

- iOS IPA (signed, 37.9MB): `build/ios/ipa/Letter Go.ipa`
- Android AAB (53MB): `build/app/outputs/bundle/release/app-release.aab`
- Android APK (68MB): `build/app/outputs/flutter-apk/app-release.apk`

## Verification

- `flutter analyze`: 0 issues
- `flutter test`: All tests passed
- Build logs confirm injections:
  ```
  [ios] RESEND configured: ceo@airony.xyz
  [ios] BETA_FREE_PREMIUM=true
  [ios] BETA_ADMIN_EMAIL=ceo@airony.xyz
  ```
  ```
  [android] RESEND configured: ceo@airony.xyz
  [android] BETA_FREE_PREMIUM=true
  [android] BETA_ADMIN_EMAIL=ceo@airony.xyz
  ```

## Post-deploy action — airony.xyz domain verification

Until Resend verifies the airony.xyz domain, the Resend API will reject
send attempts and the on-screen OTP fallback will continue to work
(safe degradation).

### Verify domain (one-time, 5-60 minutes)
1. https://resend.com/domains → airony.xyz must show `Verified`
2. If still pending, add these 4 DNS records at Gabia
   (https://my.gabia.com → Domain → airony.xyz → DNS 설정):
   - **TXT** `resend._domainkey` → `p=MIGfMA...QIDAQAB` (full value from Resend dashboard)
   - **MX** `send` → `feedback-smtp.us-east-1.amazonses.com` (priority 10)
   - **TXT** `send` → `v=spf1 include:amazonses.com ~all`
   - **TXT** `_dmarc` → `v=DMARC1; p=none;`
3. Wait 10-30 min for DNS propagation
4. Click "Verify DNS Records" in Resend dashboard

Once verified: Build 78 already has the credentials injected — no
rebuild required. Testers will start receiving real emails on their
next signup attempt.

## 배포 후 검증 체크리스트

1. Build 78 을 TestFlight / Play Console 내부 테스트에 업로드
2. airony.xyz DNS 레코드 4개 가비아에 추가
3. Resend 대시보드에서 Verified 상태 확인
4. 새 이메일(테스트용)로 앱에서 회원가입 시도
5. 오렌지 박스가 사라지고 메일함에 OTP 이메일 도착하는지 확인
6. 만약 안 되면 → Build 78 이 자동으로 on-screen OTP 로 폴백하므로
   테스터는 계속 가입 가능 (Build 77 동작 유지)
