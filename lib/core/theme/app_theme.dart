import 'package:flutter/material.dart';

// ── 시간대별 동적 색상 (ThemeExtension) ──────────────────────────────────────
// v5 마이그레이션: 시간대 변동 제거 → 모든 period 가 동일한 v5 dark 톤.
class AppTimeColors extends ThemeExtension<AppTimeColors> {
  final Color bgDeep;
  final Color bgCard;
  final Color bgSurface;
  final Color accent;
  final String periodEmoji;
  final String periodLabel;
  final Color gradientTop;
  final Color gradientMid;
  final Color gradientBottom;

  const AppTimeColors({
    required this.bgDeep,
    required this.bgCard,
    required this.bgSurface,
    required this.accent,
    required this.periodEmoji,
    required this.periodLabel,
    this.gradientTop = const Color(0xFF000000),
    this.gradientMid = const Color(0xFF050507),
    this.gradientBottom = const Color(0xFF0A0A0C),
  });

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.45, 1.0],
    colors: [gradientTop, gradientMid, gradientBottom],
  );

  static AppTimeColors of(BuildContext context) {
    return Theme.of(context).extension<AppTimeColors>() ??
        const AppTimeColors(
          bgDeep: Color(0xFF000000),
          bgCard: Color(0xFF141417),
          bgSurface: Color(0xFF1C1C1F),
          accent: Color(0xFFFFD60A),
          periodEmoji: '·',
          periodLabel: 'v5',
        );
  }

  @override
  AppTimeColors copyWith({
    Color? bgDeep,
    Color? bgCard,
    Color? bgSurface,
    Color? accent,
    String? periodEmoji,
    String? periodLabel,
    Color? gradientTop,
    Color? gradientMid,
    Color? gradientBottom,
  }) {
    return AppTimeColors(
      bgDeep: bgDeep ?? this.bgDeep,
      bgCard: bgCard ?? this.bgCard,
      bgSurface: bgSurface ?? this.bgSurface,
      accent: accent ?? this.accent,
      periodEmoji: periodEmoji ?? this.periodEmoji,
      periodLabel: periodLabel ?? this.periodLabel,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientMid: gradientMid ?? this.gradientMid,
      gradientBottom: gradientBottom ?? this.gradientBottom,
    );
  }

  @override
  AppTimeColors lerp(ThemeExtension<AppTimeColors>? other, double t) {
    if (other is! AppTimeColors) return this;
    return AppTimeColors(
      bgDeep: Color.lerp(bgDeep, other.bgDeep, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      periodEmoji: t < 0.5 ? periodEmoji : other.periodEmoji,
      periodLabel: t < 0.5 ? periodLabel : other.periodLabel,
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t)!,
      gradientMid: Color.lerp(gradientMid, other.gradientMid, t)!,
      gradientBottom: Color.lerp(gradientBottom, other.gradientBottom, t)!,
    );
  }
}

/// v5 Wallet 디자인 시스템 컬러.
///
/// 기존 이름(gold, teal, bgDeep…)을 유지해 전 화면 호환성 보장.
/// 시각 톤은 v5 (pure black + 카테고리 강색 5개)로 매핑됨.
class AppColors {
  // ── Background (모두 pure black 계열) ──
  static const Color bgDeep = Color(0xFF000000);
  static const Color bgCard = Color(0xFF141417);
  static const Color bgSurface = Color(0xFF1C1C1F);
  static const Color bgElevated = Color(0xFF2A2A2E);

  // ── 카테고리 강색 ──
  // 'gold' = Premium membership = #FFD60A (Air Mail Pass)
  static const Color gold = Color(0xFFFFD60A);
  static const Color goldLight = Color(0xFFFFE761);
  static const Color goldDark = Color(0xFFB89500);
  // 'teal' = Letter (개인 편지) = #B8FF5C
  static const Color teal = Color(0xFFB8FF5C);
  static const Color tealDark = Color(0xFF7BC93C);
  // 신규 카테고리 ─ 직접 참조 가능
  static const Color coupon = Color(0xFFFF4D6D);
  static const Color premium = Color(0xFFFFD60A);
  static const Color letter = Color(0xFFB8FF5C);
  static const Color map = Color(0xFF5BA4F6);
  static const Color streak = Color(0xFFC77DFF);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF5A5A5F);

  // ── Letter glow (카테고리 매핑) ──
  static const Color letterGlow = Color(0xFFFFD60A);
  static const Color letterGlowDelivering = Color(0xFFB8FF5C);
  static const Color letterGlowRead = Color(0xFF5A5A5F);

  // ── Status ──
  static const Color success = Color(0xFFB8FF5C);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF4D6D);

  // ── Map overlay ──
  static const Color mapOverlay = Color(0x99000000);
  static const Color nearbyRadius = Color(0x33FFD60A);
  static const Color nearbyBorder = Color(0x80FFD60A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.teal,
        surface: AppColors.bgCard,
        onPrimary: AppColors.bgDeep,
        onSecondary: AppColors.bgDeep,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: -0.15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: -0.1,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.bgDeep,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDeep,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 0.5,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      useMaterial3: true,
    );
  }
}
