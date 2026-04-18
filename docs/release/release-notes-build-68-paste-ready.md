# Build 68 — Paste-Ready Release Notes

Date: 2026-04-18
Version: 1.0.0 (68)

아래 내용을 Play Console "이 버전의 새로운 기능" 및 TestFlight "테스트할 내용"
필드에 그대로 복사해 사용하세요. 각 항목은 해당 스토어의 글자 수 제한을
넘지 않도록 작성되었습니다.

---

## 📱 Google Play Console (500자 제한 · 언어별)

### 한국어 (ko-KR)
```
✨ 새로워진 Letter Go

• "행운의 편지"가 "오늘의 편지"로 바뀌었어요
• 회원가입이 더 간단해졌어요 (전화번호 선택 입력)
• 설정에서 언어를 바꾸면 즉시 반영됩니다
• 아랍어 등 RTL(우→좌) 언어를 지원합니다
• 아이디 입력 중 중복 여부를 실시간으로 확인해요
• 받은 편지에서 바로 발송자를 차단할 수 있어요

더 편하고 글로벌한 편지 경험을 만나보세요!
```

### English (en-US)
```
✨ What's New in Letter Go

• "Lucky Letter" is now "Today's Letter"
• Simpler signup — phone number is now optional
• Language changes in Settings apply instantly
• Right-to-left language support (Arabic, Hebrew, etc.)
• Real-time username availability check
• Block senders directly from the letter detail view

A smoother, more global letter experience awaits!
```

### 日本語 (ja)
```
✨ Letter Goの新機能

• 「幸運の手紙」が「今日の手紙」に変わりました
• 会員登録がより簡単に（電話番号は任意入力）
• 設定で言語を変更すると即座に反映されます
• アラビア語などRTL言語に対応
• ユーザーIDの重複をリアルタイムでチェック
• 受信した手紙からすぐに送信者をブロック可能

より快適でグローバルな手紙体験をお楽しみください！
```

### 中文 (zh-CN)
```
✨ Letter Go 全新更新

• "幸运信"更名为"今日之信"
• 注册更简便（手机号码改为选填）
• 在设置中更改语言后立即生效
• 支持阿拉伯语等从右到左（RTL）语言
• 实时检查用户ID是否重复
• 可在收到的信件中直接屏蔽发送者

体验更便捷、更全球化的写信之旅！
```

---

## 🍎 App Store Connect — TestFlight "테스트할 내용"

### 한국어
```
Build 68 (1.0.0+68) — 테스트 가이드

이번 빌드에서 확인해주세요:

1. 오늘의 편지 (이전 "행운의 편지")
   • 작성 화면에서 "오늘의 편지로 보내기" 버튼 탭
   • 연속으로 여러 번 탭해서 글귀가 바뀌는지 확인
   • 글 앞뒤에 공백을 추가해도 "오늘의 편지 적용됨" 상태가 유지되는지 확인

2. 회원가입 개선
   • 전화번호를 비워둔 채로 회원가입이 진행되는지
   • 아이디 입력 중 이미 사용 중인 ID를 입력하면 실시간으로 안내가 뜨는지

3. 언어·RTL 지원
   • 설정에서 언어를 한국어 ↔ 영어 ↔ 아랍어로 바꿀 때마다 재시작 없이 즉시 반영되는지
   • 아랍어 선택 시 레이아웃이 우→좌로 뒤집혀 자연스럽게 보이는지

4. 차단 기능
   • 받은 편지 상세에서 🚫 차단 버튼을 눌러 "사용자 차단" 다이얼로그가 뜨는지
   • 차단 후 해당 발송자의 편지가 편지함에서 사라지는지

알려진 이슈: 없음
문의: shimyup@gmail.com
```

### English
```
Build 68 (1.0.0+68) — Testing Guide

Please verify the following in this build:

1. Today's Letter (renamed from "Lucky Letter")
   • Tap "Send as today's letter" in Compose screen
   • Tap multiple times — does a different quote appear?
   • Add trailing/leading whitespace — does the "applied" state persist?

2. Simplified Signup
   • Can you sign up without entering a phone number?
   • Does the username field show "taken" in real time when typed?

3. Language & RTL
   • Switch language in Settings (Korean ↔ English ↔ Arabic) — applies instantly, no restart?
   • In Arabic mode, does the layout flip right-to-left naturally?

4. Block Feature
   • Tap 🚫 on a received letter detail — does the block confirmation dialog appear?
   • After blocking, does the sender's letter disappear from your inbox?

Known Issues: None
Contact: shimyup@gmail.com
```

---

## 📊 요약 체크리스트 (내부)

| 항목 | 상태 |
|------|------|
| Korean (500자 이내) | ✅ 약 190자 |
| English (500자 이내) | ✅ 약 250자 |
| Japanese (500자 이내) | ✅ 약 170자 |
| Chinese (500자 이내) | ✅ 약 130자 |
| TestFlight KR (4000자 이내) | ✅ 약 450자 |
| TestFlight EN (4000자 이내) | ✅ 약 550자 |

---

## 🔗 관련 파일

- 상세 릴리즈 노트: `docs/release/release-notes-build-68.md`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab` (52MB)
- iOS IPA: `build/ios/ipa/Letter Go.ipa` (35MB)
