/// 앱 내에서 사용하는 외부 링크 URL 모음
///
/// 약관/개인정보 HTML은 별도 repo `shimyup/thiscount-pages` 에 호스팅.
/// 본 repo `docs/` 의 HTML 을 수정한 후, 같은 내용을 `thiscount-pages` repo
/// 의 main 에 push 하면 GitHub Pages 가 자동 재배포.
abstract class AppLinks {
  // ── 개인정보 처리방침 ──────────────────────────────────────────────────────
  // ✅ GitHub Pages 배포 완료 — https://shimyup.github.io/thiscount-pages/privacy.html
  static const String privacyPolicy =
      'https://shimyup.github.io/thiscount-pages/privacy.html';

  /// 가입 나라에 맞는 개인정보 처리방침 URL 반환
  ///   대한민국 → ?lang=ko (한국어)
  ///   그 외 → ?lang=en (영어)
  static String privacyPolicyForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$privacyPolicy?lang=$lang';
  }

  // ── 이용약관 ─────────────────────────────────────────────────────────────
  static const String termsOfService =
      'https://shimyup.github.io/thiscount-pages/terms.html';

  /// 가입 나라에 맞는 이용약관 URL 반환
  static String termsForCountry(String country) {
    final lang = country == '대한민국' ? 'ko' : 'en';
    return '$termsOfService?lang=$lang';
  }

  // ── 고객 지원 ────────────────────────────────────────────────────────────
  static const String supportEmail = 'ceo@airony.xyz';
}
