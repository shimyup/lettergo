/// 지도 설정 & API 키 관리
///
/// ─────────────────────────────────────────────────────────────
/// 국가명·도시명을 사용자 언어로 표시하려면 Stadia Maps API 키 필요
///
/// 무료 키 발급 (200,000 타일/월 무료):
///   1. https://client.stadiamaps.com/signup/ 에서 회원가입
///   2. Dashboard → API Keys → Create API Key
///   3. 아래 stadiaApiKey 에 붙여넣기
///
/// API 키가 없으면: CartoDB Voyager 타일 사용 (각 국가 현지어 표시)
///   예) 한국→한글, 일본→일본어, 중국→중국어 ... 단, 사용자 언어로 통일 불가
///
/// API 키가 있으면: Stadia Maps alidade_smooth 사용 (사용자 설정 언어로 통일)
///   예) 한국어 설정 → 미국=미국, 일본=일본, 중국=중국 모두 한글로 표시
/// ─────────────────────────────────────────────────────────────
abstract class MapConfig {
  // ✏️  Stadia Maps API 키 — 아래에 직접 입력하세요
  // 비워두면 CartoDB Voyager 자동 폴백 (현지어 표시)
  static const String stadiaApiKey = '';

  // ── 내부 유효성 검사 ──────────────────────────────────────────────────────
  static bool get hasValidStadiaKey {
    final key = stadiaApiKey.trim();
    if (key.isEmpty) return false;
    if (key.contains('your_') || key.contains('placeholder')) return false;
    return key.length >= 20;
  }

  // ── Stadia Maps 지원 언어 코드 ────────────────────────────────────────────
  static const Set<String> stadiaLangs = {
    'ko', 'ja', 'zh', 'en', 'fr', 'de', 'es', 'pt',
    'it', 'ru', 'ar', 'hi', 'th', 'tr', 'nl', 'pl',
  };

  static String toMapLang(String langCode) =>
      stadiaLangs.contains(langCode) ? langCode : 'local';

  // ── 타일 URL 생성 ─────────────────────────────────────────────────────────
  /// 기반 타일 URL
  ///   Stadia: 언어 파라미터 지원
  ///   CartoDB 폴백: Voyager = 현지어 / dark_nolabels = 다크 베이스
  static String tileUrl(String langCode, {required bool darkMode}) {
    if (hasValidStadiaKey) {
      final lang = toMapLang(langCode);
      final style = darkMode ? 'alidade_smooth_dark' : 'alidade_smooth';
      return 'https://tiles.stadiamaps.com/tiles/$style/{z}/{x}/{y}.png'
          '?api_key=$stadiaApiKey&language=$lang';
    }
    return darkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  /// 야간 현지어 레이블 오버레이 URL (Stadia 미사용 시에만 필요)
  /// Voyager only_labels = 투명 배경 + 현지어 레이블 → dark 위에 오버레이 가능
  static String? labelOverlayUrl({required bool darkMode}) {
    if (hasValidStadiaKey) return null; // Stadia는 단일 레이어에 레이블 포함
    if (!darkMode) return null;         // Voyager 주간 타일은 이미 레이블 포함
    return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png';
  }

  /// TileLayer subdomains
  static List<String> get subdomains =>
      hasValidStadiaKey ? const [] : const ['a', 'b', 'c', 'd'];
}
