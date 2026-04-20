import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../state/app_state.dart';
import '../features/map/screens/world_map_screen.dart';
import '../features/compose/screens/compose_screen.dart';
import '../features/inbox/screens/inbox_screen.dart';
import '../features/tower/screens/tower_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/streak/streak_badge.dart';
import '../features/progression/level_up_banner.dart';
import 'offline_banner.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex = widget.initialIndex;

  late final List<Widget> _pages = [
    WorldMapScreen(onGoToInbox: () => setState(() => _currentIndex = 1)),
    const InboxScreen(),
    const TowerScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 스트릭·레벨업 축하 스낵바 — 첫 프레임 이후 1회 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      StreakCelebrationBar.showIfIncreased(context);
      // 레벨업은 스트릭보다 우선 (더 큰 이벤트) — 살짝 딜레이로 연달아 표시
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) LevelUpBanner.showIfLevelUp(context);
      });
      // 🎁 브랜드 할인 편지 안내 팝업 — 7일 간격으로 재노출 (Free/Premium 전용)
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showBrandPromoIfDue(context);
      });
    });
  }

  /// 🎁 "브랜드 할인 편지" 안내 팝업.
  /// 표시 조건:
  ///   - 유저가 Free 또는 Premium (Brand 는 이미 알고 있어 제외)
  ///   - SharedPreferences 의 `brandPromoPopupLastShown` 이 null 이거나
  ///     현재 시각보다 7일 이상 전
  /// CTA:
  ///   - 알겠어요 (dismiss) → lastShown 갱신
  ///   - 관리자 문의 (mailto) → lastShown 갱신 + support 이메일 열기
  Future<void> _showBrandPromoIfDue(BuildContext ctx) async {
    final state = ctx.read<AppState>();
    if (state.currentUser.isBrand) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt('brandPromoPopupLastShown');
    final now = DateTime.now().millisecondsSinceEpoch;
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
    if (lastMs != null && now - lastMs < sevenDaysMs) return;

    if (!ctx.mounted) return;
    final l = AppL10n.of(state.currentUser.languageCode);

    Future<void> markShown() async {
      await prefs.setInt('brandPromoPopupLastShown', now);
    }

    await showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.brandPromoTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.brandPromoBody,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💼', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.brandPromoContactHint,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await markShown();
              if (dCtx.mounted) Navigator.of(dCtx).pop();
            },
            child: Text(
              l.brandPromoDismiss,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bgDeep,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await markShown();
              final uri = Uri(
                scheme: 'mailto',
                path: 'support@airony.xyz',
                queryParameters: {
                  'subject': '[Letter Go] Brand Campaign Inquiry / 브랜드 캠페인 문의',
                  'body':
                      'Hello / 안녕하세요,\n\nI\'m interested in running brand coupon campaigns on Letter Go.\n브랜드 쿠폰 캠페인을 운영하고 싶습니다.\n\nID / 아이디: ${state.currentUser.username}\nEmail / 이메일: ${state.currentUser.email ?? "N/A"}\n\n---\n',
                },
              );
              try {
                await launchUrl(uri);
              } catch (_) {}
              if (dCtx.mounted) Navigator.of(dCtx).pop();
            },
            child: Text(
              l.brandPromoContactCta,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _openCompose(BuildContext ctx) async {
    // 탭 진입 피드백
    HapticFeedback.lightImpact();
    final result = await Navigator.push<bool>(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const ComposeScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    // 편지 발송 성공 시 → 지도 탭으로 전환 + 발송 편지 위치로 카메라 이동
    if (result == true && mounted) {
      setState(() => _currentIndex = 0);
      // 약간의 딜레이 후 카메라 이동 (탭 전환 렌더링 완료 대기)
      Future.delayed(const Duration(milliseconds: 300), () {
        WorldMapScreen.focusSentLetterNotifier.value = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DM 기능 제거로 unreadCount 만 구독 → 수집첩 뱃지 변경 시에만 rebuild
    final badgeCount = context.select<AppState, int>(
      (s) => s.unreadCount,
    );
    final langCode = context.select<AppState, String>(
      (s) => s.currentUser.languageCode,
    );
    final l = AppL10n.of(langCode);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTimeColors.of(context).backgroundGradient,
        ),
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, badgeCount, l),
    );
    // 기존 중앙 FAB 제거 — "보내기" 가 하단 네비 5번째 탭으로 승격되며
    // 수집(보물찾기) UX 에 발송 액션을 동등한 비중으로 둔다. 발송 자체는
    // 여전히 중요하지만 FAB 크기(56px 골드 펄스)만큼 시각 우선순위를 주진
    // 않는다.
  }

  Widget _buildBottomNav(BuildContext ctx, int badgeCount, AppL10n l) {
    return Container(
      decoration: BoxDecoration(
        color: AppTimeColors.of(ctx).bgDeep,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate((constraints.maxWidth / 8).floor(), (
                    index,
                  ) {
                    return Container(
                      width: 4,
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.3),
                    );
                  }),
                );
              },
            ),
          ),
          SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.explore_rounded,
                      label: l.navExplore,
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItemWithBadge(
                      icon: Icons.inventory_2_rounded,
                      label: l.navCollection,
                      isSelected: _currentIndex == 1,
                      badgeCount: badgeCount,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  Expanded(
                    // "보내기"는 탭이 아니라 컴포즈 모달 CTA. 항상 골드 톤으로
                    // 강조해서 다른 탭과 시각적으로 구분되도록 _ComposeNavItem
                    // 을 따로 둔다.
                    child: _ComposeNavItem(
                      label: l.navSend,
                      onTap: () => _openCompose(ctx),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.apartment_rounded,
                      label: l.navTower,
                      isSelected: _currentIndex == 2,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.person_rounded,
                      label: l.profile,
                      isSelected: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 컴포즈 CTA 탭 — 항상 골드, 둥근 테두리로 "탭이 아니라 작성 버튼" 표현 ──
class _ComposeNavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ComposeNavItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.gold,
                size: 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 내비 아이템 ───────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.gold : AppColors.textMuted,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: AppColors.bgDeep,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
