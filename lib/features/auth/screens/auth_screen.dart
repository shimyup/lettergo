import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/localization/language_config.dart';
import '../../../core/config/app_links.dart';
import '../../../state/app_state.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // 배경 별빛
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _AuthBgPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // 앱 로고
                _buildLogo(),
                const SizedBox(height: 32),
                // 탭 바
                _buildTabBar(),
                const SizedBox(height: 8),
                // 탭 뷰
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _LoginTab(onLoginSuccess: _onAuthSuccess),
                      _SignupTab(onSignupSuccess: _onAuthSuccess),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        const Text('🍾', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
          ).createShader(b),
          child: const Text(
            'Message in a Bottle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '세상 어딘가의 당신에게',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.8),
            fontSize: 13,
            letterSpacing: 2.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D44)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: '🔑  로그인'),
          Tab(text: '✨  회원가입'),
        ],
      ),
    );
  }

  Future<void> _onAuthSuccess(Map<String, String> userData) async {
    final state = context.read<AppState>();
    state.setUser(
      id: userData['id'] ?? '',
      username: userData['username'] ?? '',
      country: userData['country'] ?? '대한민국',
      countryFlag: userData['countryFlag'] ?? '🇰🇷',
      socialLink: userData['socialLink'],
    );
    final onboardingDone = await AuthService.isOnboardingComplete();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacementNamed(onboardingDone ? '/home' : '/onboarding');
  }
}

// ── 로그인 탭 ─────────────────────────────────────────────────────────────────
class _LoginTab extends StatefulWidget {
  final Future<void> Function(Map<String, String>) onLoginSuccess;
  const _LoginTab({required this.onLoginSuccess});

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final err = await AuthService.login(
      username: _usernameCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _isLoading = false;
        _error = err;
      });
      return;
    }

    final user = await AuthService.getCurrentUser();
    if (user != null) await widget.onLoginSuccess(user);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          _InputField(
            controller: _usernameCtrl,
            label: '닉네임(아이디)',
            hint: 'Traveler_42',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _passCtrl,
            label: '비밀번호',
            hint: '6자 이상',
            icon: Icons.lock_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _AuthButton(
            label: '로그인',
            emoji: '🔑',
            isLoading: _isLoading,
            onTap: _login,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '비밀번호 찾기',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showResetPasswordDialog(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '처음이신가요? 회원가입 탭에서 계정을 만들어보세요.',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '닉네임과 가입 이메일을 입력하면 임시 비밀번호를 발급합니다.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '닉네임(아이디)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '가입 이메일 (필수)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1F2D44)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.teal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await AuthService.resetPassword(
                username: usernameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
              final bool ok = result['success'] == true;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    ok ? '임시 비밀번호 발급' : '찾기 실패',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    ok
                        ? '임시 비밀번호: ${result['tempPassword']}\n'
                              '${result['expiresInMinutes']}분 후 만료됩니다.\n'
                              '로그인 후 반드시 변경해주세요.'
                        : (result['error'] ?? '오류가 발생했습니다.'),
                    style: TextStyle(
                      color: ok ? AppColors.teal : AppColors.error,
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('발급', style: TextStyle(color: AppColors.bgDeep)),
          ),
        ],
      ),
    );
  }
}

// ── 회원가입 탭 ───────────────────────────────────────────────────────────────
class _SignupTab extends StatefulWidget {
  final Future<void> Function(Map<String, String>) onSignupSuccess;
  const _SignupTab({required this.onSignupSuccess});

  @override
  State<_SignupTab> createState() => _SignupTabState();
}

class _SignupTabState extends State<_SignupTab> {
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _socialCtrl   = TextEditingController();

  bool _obscurePass    = true;
  bool _isLoading      = false;
  String? _error;
  String _selectedCountry = '대한민국';
  String _selectedFlag    = '🇰🇷';

  // ── 검증 상태 ──
  String? _usernameError; // 실시간 아이디 에러
  String? _passwordError; // 실시간 비밀번호 에러
  bool _usernameTaken = false;

  // ── 동의 상태 ──
  bool _agreePrivacy   = false;
  bool _agreeLocation  = false; // 동의 체크
  bool _locationGranted = false; // 실제 OS 권한 허용 여부

  // 가입 버튼 활성화 조건
  bool get _canSignUp =>
      _agreePrivacy && _agreeLocation && _locationGranted && !_isLoading;

  @override
  void initState() {
    super.initState();
    _loadOnboardingCountry();
    // 실시간 검증 리스너
    _usernameCtrl.addListener(_validateUsername);
    _passCtrl.addListener(_validatePassword);
  }

  Future<void> _loadOnboardingCountry() async {
    final data = await AuthService.getOnboardingCountry();
    if (mounted) {
      setState(() {
        _selectedCountry = data['country'] ?? '대한민국';
        _selectedFlag    = data['countryFlag'] ?? '🇰🇷';
      });
    }
  }

  void _validateUsername() {
    final err = AuthService.validateUsername(_usernameCtrl.text);
    if (_usernameError != err) setState(() => _usernameError = err);
  }

  void _validatePassword() {
    final err = AuthService.validatePassword(_passCtrl.text);
    if (_passwordError != err) setState(() => _passwordError = err);
  }

  static const _countries = [
    {'name': '대한민국', 'flag': '🇰🇷'},
    {'name': '일본', 'flag': '🇯🇵'},
    {'name': '미국', 'flag': '🇺🇸'},
    {'name': '프랑스', 'flag': '🇫🇷'},
    {'name': '영국', 'flag': '🇬🇧'},
    {'name': '독일', 'flag': '🇩🇪'},
    {'name': '이탈리아', 'flag': '🇮🇹'},
    {'name': '스페인', 'flag': '🇪🇸'},
    {'name': '브라질', 'flag': '🇧🇷'},
    {'name': '인도', 'flag': '🇮🇳'},
    {'name': '중국', 'flag': '🇨🇳'},
    {'name': '호주', 'flag': '🇦🇺'},
    {'name': '캐나다', 'flag': '🇨🇦'},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _socialCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_agreePrivacy) {
      setState(() => _error = '개인정보 처리방침에 동의해야 가입할 수 있습니다.');
      return;
    }
    if (!_locationGranted) {
      setState(() => _error = '위치 권한을 허용해야 편지를 보내고 받을 수 있습니다.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    final err = await AuthService.signUp(
      username:     _usernameCtrl.text,
      password:     _passCtrl.text,
      email:        _emailCtrl.text.trim(),
      country:      _selectedCountry,
      countryFlag:  _selectedFlag,
      socialLink:   _socialCtrl.text.isNotEmpty ? _socialCtrl.text : null,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() { _isLoading = false; _error = err; });
      return;
    }

    final user = await AuthService.getCurrentUser();
    if (user != null) await widget.onSignupSuccess(user);
  }

  /// 위치 동의 체크박스 탭 → OS 권한 요청
  Future<void> _onLocationConsentTap(bool? checked) async {
    if (checked != true) {
      setState(() { _agreeLocation = false; _locationGranted = false; });
      return;
    }
    // 동의 체크 시 즉시 OS 위치 권한 요청
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!mounted) return;
    setState(() {
      _agreeLocation   = granted || permission == LocationPermission.deniedForever;
      _locationGranted = granted;
    });
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '위치 권한이 거부되었습니다.\n설정 → 앱 → 위치에서 허용해주세요.',
          ),
          backgroundColor: AppColors.bgCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '설정 열기',
            textColor: AppColors.teal,
            onPressed: () => Geolocator.openAppSettings(),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),

          // ── 1. 이메일 ──────────────────────────────────────────────────────
          _InputField(
            controller: _emailCtrl,
            label: '이메일',
            hint: 'example@email.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // ── 2. 아이디 ──────────────────────────────────────────────────────
          _InputField(
            controller: _usernameCtrl,
            label: '아이디',
            hint: 'traveler42   (영문 시작, 영문·숫자·_ 2~20자)',
            icon: Icons.person_rounded,
          ),
          if (_usernameError != null)
            _FieldError(message: _usernameError!)
          else if (_usernameTaken)
            _FieldError(message: '이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요.'),
          const SizedBox(height: 12),

          // ── 3. 비밀번호 ────────────────────────────────────────────────────
          _InputField(
            controller: _passCtrl,
            label: '비밀번호',
            hint: 'Pass123   (영문+숫자 포함 6~12자)',
            icon: Icons.lock_rounded,
            obscureText: _obscurePass,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          if (_passwordError != null) _FieldError(message: _passwordError!),
          const SizedBox(height: 12),

          // ── 4. 국가 선택 ───────────────────────────────────────────────────
          GestureDetector(
            onTap: _pickCountry,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F2D44)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(_selectedFlag,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('거주 국가',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        Text(_selectedCountry,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 5. SNS 링크 ────────────────────────────────────────────────────
          _InputField(
            controller: _socialCtrl,
            label: 'SNS 링크 (선택)',
            hint: 'https://instagram.com/...',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),

          // ── 6. 개인정보 동의 ───────────────────────────────────────────────
          _ConsentCard(
            checked: _agreePrivacy,
            icon: Icons.shield_outlined,
            iconColor: AppColors.teal,
            title: '(필수) 개인정보 처리방침',
            linkLabel: '내용 보기',
            description: '수집 항목: 이메일·닉네임·국가·위치(도시 단위)\n목적: 서비스 제공, 계정 관리',
            onCheckChanged: (v) => setState(() => _agreePrivacy = v ?? false),
            onLinkTap: _openPrivacyPolicy,
          ),
          const SizedBox(height: 10),

          // ── 7. 위치 동의 ───────────────────────────────────────────────────
          _ConsentCard(
            checked: _agreeLocation,
            icon: _locationGranted
                ? Icons.location_on_rounded
                : Icons.location_off_rounded,
            iconColor: _locationGranted ? AppColors.teal : AppColors.textMuted,
            title: '(필수) 현재 위치 사용 동의',
            description: '편지 발송·수신·지도 기능은 현재 위치가 필요합니다.\n'
                '동의 시 위치 권한 허용 창이 나타납니다.',
            statusWidget: _locationGranted
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.teal, size: 14),
                    SizedBox(width: 4),
                    Text('허용됨',
                        style: TextStyle(color: AppColors.teal, fontSize: 11)),
                  ])
                : null,
            onCheckChanged: _onLocationConsentTap,
          ),
          const SizedBox(height: 24),

          // ── 가입하기 버튼 ─────────────────────────────────────────────────
          _AuthButton(
            label: '가입하기',
            emoji: '✨',
            isLoading: _isLoading,
            enabled: _canSignUp,
            onTap: _signUp,
          ),
        ],
      ),
    );
  }

  /// 개인정보 처리방침 페이지를 외부 브라우저로 열기
  /// [country]가 대한민국이면 한국어, 그 외는 영어 버전
  Future<void> _openPrivacyPolicy() async {
    final url = AppLinks.privacyPolicyForCountry(_selectedCountry);
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) _showPrivacyPolicy();
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '개인정보 처리방침',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. 수집 항목',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '이메일, 닉네임, 국가, SNS 링크(선택)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '2. 수집 목적',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '서비스 제공, 편지 발송 및 수신, 계정 관리',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '3. 보유 기간',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '회원 탈퇴 시까지 (탈퇴 즉시 모든 데이터 삭제)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '4. 제3자 제공',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '수집된 개인정보는 제3자에게 제공되지 않습니다.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() => _agreePrivacy = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text(
              '동의하기',
              style: TextStyle(color: AppColors.bgDeep),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '닫기',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _pickCountry() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '거주 국가 선택',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // 언어 안내 배너
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '선택한 나라의 언어로 앱이 표시됩니다',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: _countries.map((c) {
                    final langCode = LanguageConfig.getLanguageCode(c['name']!);
                    final langName = LanguageConfig.getLanguageName(langCode);
                    return ListTile(
                      leading: Text(
                        c['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        c['name']!,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        langName,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: _selectedCountry == c['name']
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.teal,
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCountry = c['name']!;
                          _selectedFlag = c['flag']!;
                        });
                        Navigator.pop(ctx);
                        // 언어 안내 스낵바
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🌐 언어가 $langName(으)로 설정됩니다'),
                            backgroundColor: AppColors.bgCard,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.gold, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2D44)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.emoji,
    required this.isLoading,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading;
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: active ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3),
          foregroundColor: AppColors.bgDeep,
          disabledBackgroundColor:
              AppColors.gold.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.bgDeep),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ],
              ),
      ),
    );
  }
}

// ── 필드 인라인 에러 ───────────────────────────────────────────────────────────
class _FieldError extends StatelessWidget {
  final String message;
  const _FieldError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 12, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ── 동의 카드 ─────────────────────────────────────────────────────────────────
class _ConsentCard extends StatelessWidget {
  final bool checked;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? linkLabel;
  final Widget? statusWidget;
  final ValueChanged<bool?>? onCheckChanged;
  final VoidCallback? onLinkTap;

  const _ConsentCard({
    required this.checked,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.linkLabel,
    this.statusWidget,
    this.onCheckChanged,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: checked
            ? AppColors.teal.withValues(alpha: 0.07)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked
              ? AppColors.teal.withValues(alpha: 0.4)
              : const Color(0xFF1F2D44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              if (statusWidget != null) statusWidget!,
            ],
          ),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: onCheckChanged,
                activeColor: AppColors.teal,
                side: const BorderSide(color: AppColors.textMuted),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text('동의합니다',
                    style: TextStyle(
                        color: checked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12)),
              ),
              if (linkLabel != null && onLinkTap != null)
                TextButton(
                  onPressed: onLinkTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(linkLabel!,
                      style: const TextStyle(
                          color: AppColors.teal, fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final rng = Random(99);
    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.5 + 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
