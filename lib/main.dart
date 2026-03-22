import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/time_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'state/app_state.dart';
import 'features/splash/splash_screen.dart'; // kept for route
import 'features/auth/screens/auth_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/main_scaffold.dart';

Future<Position?> _getLocation() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied ||
          req == LocationPermission.deniedForever) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    ).timeout(const Duration(seconds: 5));
  } catch (_) {
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1421),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await NotificationService.initialize();

  final loggedIn = await AuthService.isLoggedIn();
  final userData = loggedIn ? await AuthService.getCurrentUser() : null;
  final position = await _getLocation();

  runApp(
    GlobalDriftApp(
      initialLoggedIn: loggedIn,
      initialUserData: userData,
      initialLat: position?.latitude,
      initialLng: position?.longitude,
    ),
  );
}

class GlobalDriftApp extends StatefulWidget {
  final bool initialLoggedIn;
  final Map<String, String>? initialUserData;
  final double? initialLat;
  final double? initialLng;

  const GlobalDriftApp({
    super.key,
    required this.initialLoggedIn,
    this.initialUserData,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<GlobalDriftApp> createState() => _GlobalDriftAppState();
}

class _GlobalDriftAppState extends State<GlobalDriftApp> {
  late AppState _appState;
  Timer? _themeTimer;
  TimeOfDayPeriod? _lastPeriod;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    if (widget.initialLoggedIn && widget.initialUserData != null) {
      _appState.setUser(
        id: widget.initialUserData!['id'] ?? '',
        username: widget.initialUserData!['username'] ?? 'Traveler',
        country: widget.initialUserData!['country'] ?? '대한민국',
        countryFlag: widget.initialUserData!['countryFlag'] ?? '🇰🇷',
        socialLink: widget.initialUserData!['socialLink']?.isNotEmpty == true
            ? widget.initialUserData!['socialLink']
            : null,
        latitude: widget.initialLat,
        longitude: widget.initialLng,
      );
    }
    // 저장된 데이터 복원 (편지함, 보낸 편지, 활동 점수, 차단 목록)
    _appState.loadFromPrefs();
    // 시간대 변화 감지 타이머 (30초마다 체크, 시간대 변경 시 테마 갱신)
    _lastPeriod = _appState.activeTimePeriod;
    _themeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final period = _appState.activeTimePeriod;
      if (period != _lastPeriod) {
        _lastPeriod = period;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _themeTimer?.cancel();
    super.dispose();
  }

  ThemeData _buildTheme(AppState state) {
    final timeTheme = TimeTheme.forPeriod(state.activeTimePeriod);
    final base = AppTheme.darkTheme;
    return base.copyWith(
      scaffoldBackgroundColor: timeTheme.bgDeep,
      colorScheme: base.colorScheme.copyWith(
        surface: timeTheme.bgCard,
        primary: timeTheme.accent,
      ),
      cardTheme: base.cardTheme.copyWith(color: timeTheme.bgCard),
      extensions: [
        AppTimeColors(
          bgDeep: timeTheme.bgDeep,
          bgCard: timeTheme.bgCard,
          bgSurface: timeTheme.bgSurface,
          accent: timeTheme.accent,
          periodEmoji: timeTheme.emoji,
          periodLabel: timeTheme.label,
          gradientTop: timeTheme.gradientTop,
          gradientMid: timeTheme.gradientMid,
          gradientBottom: timeTheme.gradientBottom,
        ),
      ],
    );
  }

  String _getInitialRoute() {
    return '/splash';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'Message in a Bottle',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(state),
            initialRoute: _getInitialRoute(),
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              '/splash': (_) =>
                  SplashScreen(skipToAuth: !widget.initialLoggedIn),
              '/auth': (_) => const AuthScreen(),
              '/home': (_) => const MainScaffold(),
            },
          );
        },
      ),
    );
  }
}
