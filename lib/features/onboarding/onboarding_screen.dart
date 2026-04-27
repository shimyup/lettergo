import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Selected country from page 0
  String _selectedCountry = '대한민국';
  String _selectedFlag = '🇰🇷';
  String _langCode = 'ko';

  // Location permission state
  bool _locationGranted = false;
  bool _locationChecking = false;

  AppL10n get _l => AppL10n.of(_langCode);

  static const int _totalPages =
      7; // page 0 = country, 1 = location, 2-5 = intro, 6 = coming soon

  static const List<Map<String, String>> _popularCountries = [
    {'name': '대한민국', 'flag': '🇰🇷', 'lang': 'ko'},
    {'name': '日本', 'flag': '🇯🇵', 'lang': 'ja'},
    {'name': 'United States', 'flag': '🇺🇸', 'lang': 'en'},
    {'name': 'United Kingdom', 'flag': '🇬🇧', 'lang': 'en'},
    {'name': 'France', 'flag': '🇫🇷', 'lang': 'fr'},
    {'name': 'Deutschland', 'flag': '🇩🇪', 'lang': 'de'},
    {'name': 'Italia', 'flag': '🇮🇹', 'lang': 'it'},
    {'name': 'España', 'flag': '🇪🇸', 'lang': 'es'},
    {'name': 'Brasil', 'flag': '🇧🇷', 'lang': 'pt'},
    {'name': 'India', 'flag': '🇮🇳', 'lang': 'hi'},
    {'name': '中国', 'flag': '🇨🇳', 'lang': 'zh'},
    {'name': 'Australia', 'flag': '🇦🇺', 'lang': 'en'},
    {'name': 'Canada', 'flag': '🇨🇦', 'lang': 'en'},
    {'name': 'México', 'flag': '🇲🇽', 'lang': 'es'},
    {'name': 'Россия', 'flag': '🇷🇺', 'lang': 'ru'},
    {'name': 'Türkiye', 'flag': '🇹🇷', 'lang': 'tr'},
    {'name': 'مصر', 'flag': '🇪🇬', 'lang': 'ar'},
    {'name': 'South Africa', 'flag': '🇿🇦', 'lang': 'en'},
    {'name': 'ประเทศไทย', 'flag': '🇹🇭', 'lang': 'th'},
    {'name': 'Argentina', 'flag': '🇦🇷', 'lang': 'es'},
    {'name': 'Netherlands', 'flag': '🇳🇱', 'lang': 'en'},
    {'name': 'Sverige', 'flag': '🇸🇪', 'lang': 'en'},
    {'name': 'Norge', 'flag': '🇳🇴', 'lang': 'en'},
    {'name': 'Portugal', 'flag': '🇵🇹', 'lang': 'pt'},
    {'name': 'Indonesia', 'flag': '🇮🇩', 'lang': 'en'},
    {'name': 'Malaysia', 'flag': '🇲🇾', 'lang': 'en'},
    {'name': 'Singapore', 'flag': '🇸🇬', 'lang': 'en'},
    {'name': 'New Zealand', 'flag': '🇳🇿', 'lang': 'en'},
    {'name': 'Philippines', 'flag': '🇵🇭', 'lang': 'en'},
    {'name': 'Vietnam', 'flag': '🇻🇳', 'lang': 'en'},
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      if (mounted) setState(() => _locationGranted = true);
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _locationChecking = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (mounted) {
        setState(() {
          _locationGranted =
              permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
          _locationChecking = false;
        });
        if (_locationGranted) {
          // 자동으로 다음 페이지
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) _nextPage();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _locationChecking = false);
    }
  }

  Future<void> _finish() async {
    // Map the displayed country name back to Korean for AppState compatibility
    final koreanName = _getKoreanName(_selectedCountry);
    await AuthService.saveOnboardingCountry(
      country: koreanName,
      countryFlag: _selectedFlag,
    );
    await AuthService.setOnboardingComplete();

    // 알림 권한 요청 (선택적 — 거부해도 진행 가능)
    try {
      await NotificationService.requestPermissions();
    } catch (_) {}

    if (mounted) {
      // 이미 로그인 상태면 홈으로, 아니면 인증 화면으로
      final loggedIn = await AuthService.isLoggedIn();
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed(loggedIn ? '/home' : '/auth');
      }
    }
  }

  String _getKoreanName(String displayName) {
    // Map display names back to Korean names used in app
    const displayToKorean = {
      '대한민국': '대한민국',
      '日本': '일본',
      'United States': '미국',
      'United Kingdom': '영국',
      'France': '프랑스',
      'Deutschland': '독일',
      'Italia': '이탈리아',
      'España': '스페인',
      'Brasil': '브라질',
      'India': '인도',
      '中国': '중국',
      'Australia': '호주',
      'Canada': '캐나다',
      'México': '멕시코',
      'Россия': '러시아',
      'Türkiye': '터키',
      'مصر': '이집트',
      'South Africa': '남아프리카',
      'ประเทศไทย': '태국',
      'Argentina': '아르헨티나',
    };
    return displayToKorean[displayName] ?? displayName;
  }

  void _nextPage() {
    // 페이지 1(위치 허용): 권한 미허가 시 먼저 요청, 이미 거부됐으면 건너뛰기 허용
    if (_currentPage == 1 && !_locationGranted) {
      _requestLocationPermission();
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  /// 위치 권한 없이 다음으로 건너뜀 (앱스토어 가이드라인 준수)
  void _skipLocationPermission() {
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Page 0: Country selection
              _CountrySelectionPage(
                selectedCountry: _selectedCountry,
                selectedFlag: _selectedFlag,
                countries: _popularCountries,
                l: _l,
                onCountrySelected: (name, flag, lang) {
                  setState(() {
                    _selectedCountry = name;
                    _selectedFlag = flag;
                    _langCode = lang;
                  });
                },
              ),
              // Page 1: Location permission (필수)
              _LocationPermissionPage(
                isGranted: _locationGranted,
                isChecking: _locationChecking,
                onRequest: _requestLocationPermission,
                langCode: _langCode,
              ),
              // Pages 2-5: Intro slides
              _IntroPage(
                emoji: '✈️',
                title: _l.onboarding2Title,
                body: _l.onboarding2Body,
                gradient: const [Color(0xFF0A1628), Color(0xFF0D2040)],
              ),
              _IntroPage(
                emoji: '📬',
                title: _l.onboarding3Title,
                body: _l.onboarding3Body,
                gradient: const [Color(0xFF0F1A30), Color(0xFF1A2A50)],
              ),
              _IntroPage(
                emoji: '🌗',
                title: _l.onboarding4Title,
                body: _l.onboarding4Body,
                gradient: const [Color(0xFF15102A), Color(0xFF2A1A50)],
              ),
              _IntroPage(
                emoji: '🚀',
                title: _l.onboarding5Title,
                body: _l.onboarding5Body,
                gradient: const [Color(0xFF0A1628), Color(0xFF162040)],
              ),
              // Page 6: Premium 소개
              _PremiumPage(l: _l),
            ],
          ),
          // Top skip button (only show after page 0)
          if (_currentPage > 0)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _currentPage < _totalPages - 1
                      ? TextButton(
                          onPressed: _finish,
                          child: Text(
                            _l.skip,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          // Bottom nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // v5 progress bar — 가는 막대
                    Row(
                      children: List.generate(_totalPages, (i) {
                        final isActive = i <= _currentPage;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.only(
                              right: i < _totalPages - 1 ? 4 : 0,
                            ),
                            height: 3,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.textPrimary
                                  : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // v5 CTA — 흰색 pill
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _currentPage == 1 && !_locationGranted
                              ? (_locationChecking
                                    ? _l.checking
                                    : _l.locationAllow)
                              : _currentPage < _totalPages - 1
                              ? _l.next
                              : _l.getStarted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.bgDeep,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    // 위치 권한 페이지: "나중에" 스킵 버튼 (앱스토어 가이드라인)
                    if (_currentPage == 1 && !_locationGranted && !_locationChecking)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: TextButton(
                          onPressed: _skipLocationPermission,
                          child: Text(
                            _l.skip,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySelectionPage extends StatefulWidget {
  final String selectedCountry;
  final String selectedFlag;
  final List<Map<String, String>> countries;
  final AppL10n l;
  final void Function(String name, String flag, String lang) onCountrySelected;

  const _CountrySelectionPage({
    required this.selectedCountry,
    required this.selectedFlag,
    required this.countries,
    required this.l,
    required this.onCountrySelected,
  });

  @override
  State<_CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<_CountrySelectionPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.countries
        .where((c) => c['name']!.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.l.onboardingCountryTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.l.onboardingCountrySubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 20),
              // Search field — clean v5
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.l.onboardingSearchCountry,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isSelected = widget.selectedFlag == c['flag'];
                    return GestureDetector(
                      onTap: () => widget.onCountrySelected(
                        c['name']!,
                        c['flag']!,
                        c['lang']!,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              c['flag']!,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                c['name']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.bgDeep
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Text(
                              LanguageConfig.languageNames[c['lang']] ?? c['lang']!,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.bgDeep.withValues(alpha: 0.55)
                                    : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 위치 허용 페이지 ──────────────────────────────────────────────────────────
class _LocationPermissionPage extends StatelessWidget {
  final bool isGranted;
  final bool isChecking;
  final VoidCallback onRequest;
  final String langCode;

  const _LocationPermissionPage({
    required this.isGranted,
    required this.isChecking,
    required this.onRequest,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(langCode);
    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // v5: 큰 라인 아이콘 (이모지 폐기)
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isGranted ? AppColors.letter : AppColors.bgCard,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted
                      ? Icons.check_rounded
                      : Icons.location_on_outlined,
                  size: 32,
                  color: isGranted
                      ? const Color(0xFF0A1A00)
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                isGranted ? l.locationGranted : l.locationRequired,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isGranted ? l.locationGrantedBody : l.locationRequiredBody,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.15,
                ),
              ),
              if (isChecking)
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Premium 소개 페이지 ──────────────────────────────────────────────────────
class _PremiumPage extends StatelessWidget {
  final AppL10n l;
  const _PremiumPage({required this.l});

  @override
  Widget build(BuildContext context) {
    // 무료 기능
    final freeFeatures = [
      l.onboardingFreeFeat1,
      l.onboardingFreeFeat2,
      l.onboardingFreeFeat3,
      l.onboardingFreeFeat4,
    ];

    // 프리미엄 전용 기능 (실제 한도와 동일하게 유지)
    final premiumFeatures = [
      {
        'emoji': '✉️',
        'text': l.onboardingPremiumFeat1,
        'color': const Color(0xFFFF6B9D),
      },
      {'emoji': '📸', 'text': l.onboardingPremiumFeat2, 'color': AppColors.teal},
      {'emoji': '⚡', 'text': l.onboardingPremiumFeat3, 'color': AppColors.gold},
      {'emoji': '🗼', 'text': l.onboardingPremiumFeat4, 'color': AppColors.coupon},
    ];
    final dayTimeline = [
      {
        'emoji': '🌅',
        'time': l.onboardingTimelineMorning,
        'free': l.onboardingTimelineMorningFree,
        'premium': l.onboardingTimelineMorningPremium,
      },
      {
        'emoji': '🌊',
        'time': l.onboardingTimelineAfternoon,
        'free': l.onboardingTimelineAfternoonFree,
        'premium': l.onboardingTimelineAfternoonPremium,
      },
      {
        'emoji': '🌙',
        'time': l.onboardingTimelineEvening,
        'free': l.onboardingTimelineEveningFree,
        'premium': l.onboardingTimelineEveningBrand,
      },
    ];
    final socialProofReviews = [
      l.onboardingReview1,
      l.onboardingReview2,
    ];

    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── v5 헤더: 좌측정렬, 작은 yellow chip + 큰 헤드라인 ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.labelLetterGoPremium.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.66,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.onboardingPremiumTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.onboardingPremiumSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 28),

              // ── 플랜 비교 카드 ──
              Row(
                children: [
                  // 무료 플랜
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.tierFree,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '₩0',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...freeFeatures.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 프리미엄 플랜
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.15),
                            AppColors.gold.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l.tierPremium,
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.tierBest,
                                  style: TextStyle(
                                    color: AppColors.bgDeep,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: '₩4,900',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: l.onboardingPerMonth,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...premiumFeatures.map((f) {
                            final color = f['color'] as Color;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    f['emoji'] as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f['text'] as String,
                                      style: TextStyle(
                                        color: color.withValues(alpha: 0.9),
                                        fontSize: 11,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 하루 타임라인: 무료 vs 프리미엄/브랜드 ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ ${l.onboardingTimelineTitle}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dayTimeline.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['emoji']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['time']!,
                                  style: TextStyle(
                                    color: AppColors.gold.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['free']!,
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.textMuted.withValues(alpha: 0.4),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '→ ${item['premium']!}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(color: AppColors.textMuted, height: 16, thickness: 0.3),
                    ...socialProofReviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $review',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 안내 문구 ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.onboardingFreeStartHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final List<Color> gradient;

  const _IntroPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // 큰 emoji 단독 (원형 폐기, 정렬 좌측)
              Text(
                emoji,
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.15,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
