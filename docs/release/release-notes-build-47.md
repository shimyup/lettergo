# Release Notes — Build 47 (1.0.0+47)

Date: 2026-04-11

---

## Korean (한국어)

**새로운 기능**

- 회원가입 시 핸드폰 번호가 필수 입력으로 변경되었습니다
- 국가코드 선택기가 추가되어 거주 국가에 맞는 번호가 자동 설정됩니다
- SMS 인증이 실제 문자 발송으로 작동합니다 (Twilio 연동)
- 이메일 또는 SMS 중 원하는 인증 방식을 선택할 수 있습니다

**개선 사항**

- 인증 화면에서 SMS 선택 시 전화번호와 SMS 전용 안내가 표시됩니다
- 전화번호 형식이 국제 표준(E.164)으로 자동 변환됩니다

---

## English

**New Features**

- Phone number is now required at signup
- Country code picker added — automatically matches your residence country
- SMS verification now sends real text messages via Twilio
- Choose between email or SMS for your verification method

**Improvements**

- OTP screen adapts to show phone-specific guidance when SMS is selected
- Phone numbers are automatically normalized to international E.164 format

---

## Japanese (日本語)

**新機能**

- 会員登録時に電話番号が必須になりました
- 国番号選択機能が追加され、居住国に合わせて自動設定されます
- SMS認証が実際のメッセージ送信に対応しました（Twilio連携）
- メールまたはSMSから認証方法を選択できます

**改善点**

- SMS選択時、認証画面に電話番号と専用ガイドが表示されます
- 電話番号が国際標準（E.164）形式に自動変換されます

---

## Chinese (中文)

**新功能**

- 注册时手机号码改为必填项
- 新增国家代码选择器，自动匹配居住国家
- 短信验证现已支持实际短信发送（Twilio集成）
- 可在邮箱和短信验证之间自由选择

**改进**

- 选择短信验证时，验证页面显示手机号码和专属提示
- 手机号码自动转换为国际标准（E.164）格式

---

## Technical Notes

- New file: `lib/core/services/sms_service.dart` — Twilio REST API SMS delivery
- Twilio credentials via dart-define: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`
- Dev fallback: OTP displayed on screen when Twilio is not configured
- Phone OTP shares rate limiting with email OTP (5 req/10min, 60s cooldown)
- SHA-256 hashed OTP storage for both email and phone
- 14-language localization for all new UI strings
