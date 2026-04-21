import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

/// "나의 헌트 기록" 카드 — Build 115 에서 신규.
///
/// 프로필 화면 상단에 "이번 달 얼마나 벌었나?" 감각을 만드는 핵심 지표 4개.
/// 경쟁 앱(배민 쿠폰함 등) 이 이미 보여주는 "누적 사용량 가시화" 가 Letter Go
/// 에선 빠져 있던 리텐션 공백을 채운다. 금액 환산은 안 한다 — 브랜드마다
/// 실제 할인 금액이 달라 거짓 환산은 오해만 늘림. 대신 "픽업/사용" 숫자 자체
/// 에 집중.
class HuntWalletCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const HuntWalletCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final l10n = AppL10n.of(state.currentUser.languageCode);
        final monthPickups = state.pickupsThisMonth;
        final monthRedeemed = state.redemptionsThisMonth;
        final totalPickups = state.totalBrandPickups;
        final totalRedeemed = state.totalRedemptions;
        final isEmpty = totalPickups == 0 && totalRedeemed == 0;

        return Container(
          margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal.withValues(alpha: 0.14),
                AppColors.gold.withValues(alpha: 0.08),
                AppColors.bgCard,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.huntWalletTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isEmpty)
                Text(
                  l10n.huntWalletEmpty,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                )
              else ...[
                Row(
                  children: [
                    _statCell(
                      emoji: '📩',
                      value: '$monthPickups',
                      label: l10n.huntWalletPickupsMonth,
                      accent: AppColors.teal,
                    ),
                    _divider(),
                    _statCell(
                      emoji: '🎫',
                      value: '$monthRedeemed',
                      label: l10n.huntWalletRedeemedMonth,
                      accent: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStatCell(
                      value: '$totalPickups',
                      label: l10n.huntWalletTotalPickups,
                    ),
                    const SizedBox(width: 18),
                    _miniStatCell(
                      value: '$totalRedeemed',
                      label: l10n.huntWalletTotalRedemptions,
                    ),
                  ],
                ),
                // Build 120: 줍기 반경 진행바 — 현재 반경이 내 티어 최대의
                // 몇 % 인지 시각화. Free 는 하단에 "Premium 전환 시 5× 즉시
                // 확대" 골드 CTA 추가. 레벨 올릴수록 바가 차오름.
                const SizedBox(height: 16),
                _buildRadiusBar(l10n, state),
                // Build 116: 주간 퀘스트 진행 — Pokémon GO Field Research 류
                // 데일리/위클리 목표의 헌트 버전. 5통 목표 달성 시 체크 메시지.
                const SizedBox(height: 16),
                _buildWeeklyQuest(l10n, state),
                // Build 116: 팔로우 중인 브랜드 카운트 (0이면 숨김).
                if (state.followedBrandIds.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.huntWalletFollowing(state.followedBrandIds.length),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
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
    required Color accent,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build 120: 줍기 반경 진행 바. 현재 반경 / 내 티어의 Lv50 최대 반경.
  /// Free: 690m 기준 (200 + 49*10), Premium: 1490m (1000 + 49*10).
  /// 0→100% 를 teal/gold 그라디언트 로 시각화. Free 일 땐 하단에 "Premium
  /// 전환 시 5× 즉시 확대" 골드 CTA 삽입.
  Widget _buildRadiusBar(AppL10n l10n, AppState state) {
    final isBrand = state.currentUser.isBrand;
    final isPremium = state.currentUser.isPremium;
    final current = state.pickupRadiusMeters.round();
    // 티어별 최대 (Lv 50 도달 시)
    final tierMax = isBrand ? 1000 : (isPremium ? 1490 : 690);
    final pct = (current / tierMax).clamp(0.0, 1.0);
    final accent = isBrand
        ? const Color(0xFFFF8A5C)
        : (isPremium ? AppColors.gold : AppColors.teal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.huntWalletRadiusTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.huntWalletRadiusValue(current, tierMax),
              style: TextStyle(
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        // Free 계정만 업그레이드 CTA 노출 — Premium·Brand 은 불필요.
        if (!isPremium && !isBrand) ...[
          const SizedBox(height: 6),
          Text(
            l10n.huntWalletRadiusUpgradeCta,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyQuest(AppL10n l10n, AppState state) {
    final current = state.pickupsThisWeek;
    final goal = state.weeklyQuestGoal;
    final isDone = current >= goal;
    final pct = isDone ? 1.0 : current / goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDone
              ? l10n.huntWalletWeeklyGoalDone
              : l10n.huntWalletWeeklyGoal(current, goal),
          style: TextStyle(
            color: isDone ? AppColors.gold : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? AppColors.gold : AppColors.teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStatCell({required String value, required String label}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 46,
        color: AppColors.textMuted.withValues(alpha: 0.2),
      );
}
