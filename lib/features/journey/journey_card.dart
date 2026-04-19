import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'journey_stats.dart';

/// "나의 여정" 카드.
/// 프로필 화면에 배치되는 감성 스토리텔링 위젯.
/// Spotify Wrapped 의 상시 이용 가능한 버전 — 이용자가 자신의 발자취를
/// 언제든 확인할 수 있게 함으로써 "내가 쌓은 것" 감정 형성.
///
/// 신규 사용자 (모든 지표 0) 에게는 렌더링 생략.
class JourneyCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const JourneyCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final stats = JourneyStats.from(state);
        if (stats.isEmpty) return const SizedBox.shrink();
        final l10n = AppL10n.of(state.currentUser.languageCode);

        return Container(
          margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.12),
                AppColors.teal.withValues(alpha: 0.08),
                AppColors.bgCard,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  const Text('📬', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    l10n.journeyTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // 주요 지표 3개 (stat row)
              Row(
                children: [
                  _statCell(
                    emoji: '✉️',
                    value: '${stats.totalSent}',
                    label: l10n.journeyStatSent,
                  ),
                  _divider(),
                  _statCell(
                    emoji: '🌍',
                    value: '${stats.countriesFrom + stats.countriesTo}',
                    label: l10n.journeyStatCountries,
                  ),
                  _divider(),
                  _statCell(
                    emoji: '💬',
                    value: '${stats.totalReplies}',
                    label: l10n.journeyStatReplies,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 가장 먼 편지 (헤드라인 스토리)
              if (stats.longestDistanceKm > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('✈️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.journeyLongestDistance,
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.journeyLongestDistanceValue(
                                _formatKm(stats.longestDistanceKm),
                                stats.longestDistanceCountry,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // 최장 스트릭
              if (stats.longestStreak > 0)
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      l10n.journeyLongestStreak(stats.longestStreak),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCell({
    required String emoji,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.textMuted.withValues(alpha: 0.2),
      );

  static String _formatKm(int km) {
    final s = km.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
