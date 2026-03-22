import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/letter.dart';
import '../../../models/user_profile.dart';
import '../../../state/app_state.dart';
import '../../settings/settings_screen.dart';

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen>
    with TickerProviderStateMixin {
  late AnimationController _towerRiseController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late Animation<double> _towerRise;
  late Animation<double> _glow;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _towerRiseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _towerRise = CurvedAnimation(
      parent: _towerRiseController,
      curve: Curves.easeOutBack,
    );
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _float = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _towerRiseController.forward();
  }

  @override
  void dispose() {
    _towerRiseController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final user = state.currentUser;
        final score = user.activityScore;

        return Scaffold(
          backgroundColor: AppTimeColors.of(context).bgDeep,
          body: CustomScrollView(
            slivers: [
              // 앱바
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: AppTimeColors.of(context).bgDeep,
                title: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.gold],
                  ).createShader(b),
                  child: const Text(
                    '내 타워',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => _showMoreMenu(context, state),
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── 타워 시각화 ─────────────────────────────────────────
                    _buildTowerVisualization(score),
                    // ── 유저 정보 카드 ────────────────────────────────────────
                    _buildUserCard(context, user, score),
                    const SizedBox(height: 16),
                    // ── 활동 통계 ─────────────────────────────────────────────
                    _buildStatsGrid(context, score),
                    const SizedBox(height: 16),
                    // ── 타워 레벨 업 가이드 ──────────────────────────────────
                    _buildLevelUpGuide(context, score),
                    const SizedBox(height: 16),
                    // ── 성취 배지 ─────────────────────────────────────────────
                    _buildAchievements(context, score),
                    const SizedBox(height: 16),
                    _buildCommunityTowers(context, state),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 타워 시각화 섹션 ─────────────────────────────────────────────────────────
  Widget _buildTowerVisualization(ActivityScore score) {
    return Container(
      height: 320,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 도시 배경 스카이라인
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _SkylinePainter(),
            ),
          ),
          // 지면
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D1F3C).withOpacity(0.0),
                    const Color(0xFF0D1F3C),
                  ],
                ),
              ),
            ),
          ),
          // 글로우 효과
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(_glow.value * 0.3),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // 타워 본체
          AnimatedBuilder(
            animation: Listenable.merge([_towerRise, _floatController]),
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(0, _float.value),
                child: Transform.scale(
                  scale: _towerRise.value,
                  alignment: Alignment.bottomCenter,
                  child: CustomPaint(
                    size: Size(120, _calcTowerHeight(score)),
                    painter: _TowerPainter(
                      floors: score.towerFloors,
                      tier: score.tier,
                      glowIntensity: _glow.value,
                    ),
                  ),
                ),
              );
            },
          ),
          // 층수 뱃지
          Positioned(
            top: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.4 + _glow.value * 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(_glow.value * 0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.tier.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${score.towerFloors}F',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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

  double _calcTowerHeight(ActivityScore score) {
    final floors = score.towerFloors;
    return (60 + floors * 4.0).clamp(60.0, 240.0);
  }

  // ── 유저 정보 카드 ───────────────────────────────────────────────────────────
  Widget _buildUserCard(
    BuildContext ctx,
    UserProfile user,
    ActivityScore score,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 아바타
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    user.countryFlag,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          user.countryFlag,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.country,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 티어 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${score.tier.emoji}  ${score.tier.label}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.socialLink != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user.socialLink!,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 활동 통계 그리드 ─────────────────────────────────────────────────────────
  Widget _buildStatsGrid(BuildContext ctx, ActivityScore score) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활동 통계',
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: '📬',
                  value: '${score.receivedCount}',
                  label: '받은 편지',
                  contribution: score.receivedCount * 1.2,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  emoji: '💌',
                  value: '${score.replyCount}',
                  label: '답장',
                  contribution: score.replyCount * 2.0,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  emoji: '📤',
                  value: '${score.sentCount}',
                  label: '보낸 편지',
                  contribution: score.sentCount * 0.8,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 총 점수 바
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1F2D44)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '총 타워 점수',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      score.towerHeight.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score.towerHeight / 120).clamp(0.0, 1.0),
                    backgroundColor: AppColors.bgSurface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '공식: (받은 편지 × 1.2) + (답장 × 2.0) + (보낸 편지 × 0.8)',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 레벨업 가이드 ────────────────────────────────────────────────────────────
  Widget _buildLevelUpGuide(BuildContext ctx, ActivityScore score) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withOpacity(0.08),
              AppColors.teal.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다음 목표',
                    style: Theme.of(
                      ctx,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    score.tier.nextGoal,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 성취 배지 ────────────────────────────────────────────────────────────────
  Widget _buildAchievements(BuildContext ctx, ActivityScore score) {
    final achievements = [
      _Achievement(
        emoji: '🌱',
        title: '첫 발걸음',
        desc: '첫 편지 보내기',
        unlocked: score.sentCount >= 1,
      ),
      _Achievement(
        emoji: '📬',
        title: '편지 수집가',
        desc: '편지 5개 받기',
        unlocked: score.receivedCount >= 5,
      ),
      _Achievement(
        emoji: '💌',
        title: '소통의 달인',
        desc: '답장 3개 보내기',
        unlocked: score.replyCount >= 3,
      ),
      _Achievement(
        emoji: '🌍',
        title: '세계 여행자',
        desc: '편지 10개 보내기',
        unlocked: score.sentCount >= 10,
      ),
      _Achievement(
        emoji: '🏢',
        title: '빌딩 건축가',
        desc: '타워 10층 달성',
        unlocked: score.towerFloors >= 10,
      ),
      _Achievement(
        emoji: '🗼',
        title: '랜드마크',
        desc: '타워 50층 달성',
        unlocked: score.towerFloors >= 50,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '성취 배지',
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: achievements
                .map((a) => _AchievementBadge(achievement: a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTowers(BuildContext ctx, AppState state) {
    // Mock community members with usernames
    final members = [
      {
        'flag': '🇯🇵',
        'name': 'Kenji M.',
        'floors': 83,
        'tier': TowerTier.landmark,
        'label': '랜드마크',
      },
      {
        'flag': '🇧🇷',
        'name': 'Luis G.',
        'floors': 67,
        'tier': TowerTier.landmark,
        'label': '랜드마크',
      },
      {
        'flag': '🇨🇳',
        'name': 'Mei L.',
        'floors': 55,
        'tier': TowerTier.skyscraper,
        'label': '마천루',
      },
      {
        'flag': '🇺🇸',
        'name': 'Tom H.',
        'floors': 47,
        'tier': TowerTier.skyscraper,
        'label': '마천루',
      },
      {
        'flag': '🇫🇷',
        'name': 'Nina S.',
        'floors': 31,
        'tier': TowerTier.building,
        'label': '빌딩',
      },
      {
        'flag': '🇬🇧',
        'name': 'Emma W.',
        'floors': 22,
        'tier': TowerTier.building,
        'label': '빌딩',
      },
      {
        'flag': '🇩🇪',
        'name': 'Hana B.',
        'floors': 12,
        'tier': TowerTier.house,
        'label': '마을집',
      },
      {
        'flag': '🇰🇷',
        'name': '익명 유저',
        'floors': 5,
        'tier': TowerTier.cottage,
        'label': '오두막',
      },
    ];
    final myScore = state.currentUser.activityScore;
    final myFloors = myScore.towerFloors;
    final myRank =
        members.where((m) => (m['floors'] as int) > myFloors).length + 1;

    String rankLabel(int rank) {
      if (rank == 1) return '🥇';
      if (rank == 2) return '🥈';
      if (rank == 3) return '🥉';
      return '#$rank';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🌍 세계 랭킹',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                ),
                child: Text(
                  '내 순위 ${myRank}위',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...members.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final floors = m['floors'] as int;
            final tier = m['tier'] as TowerTier;
            final flag = m['flag'] as String;
            final name = m['name'] as String;
            final tierColor = _communityTierColor(tier);

            return GestureDetector(
              onTap: () => _showCommunityTowerDetail(ctx, idx + 1, m),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: idx == 0
                      ? AppColors.gold.withOpacity(0.08)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: idx == 0
                        ? AppColors.gold.withOpacity(0.3)
                        : const Color(0xFF1F2D44),
                  ),
                ),
                child: Row(
                  children: [
                    // 순위
                    SizedBox(
                      width: 32,
                      child: Text(
                        rankLabel(idx + 1),
                        style: TextStyle(
                          color: idx < 3 ? AppColors.gold : AppColors.textMuted,
                          fontSize: idx < 3 ? 18 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 국기
                    Text(flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    // 이름 + 티어
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                tier.emoji,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                  color: tierColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 층수 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tierColor.withOpacity(0.35)),
                      ),
                      child: Text(
                        '${floors}F',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    rankLabel(myRank),
                    style: TextStyle(
                      color: myRank <= 3 ? AppColors.gold : AppColors.textMuted,
                      fontSize: myRank <= 3 ? 18 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.currentUser.countryFlag,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentUser.username,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            myScore.tier.emoji,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            myScore.tier.label,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                  ),
                  child: Text(
                    '${myScore.towerFloors}F',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _communityTierColor(TowerTier tier) {
    switch (tier) {
      case TowerTier.cottage:
        return const Color(0xFFCD7F32);
      case TowerTier.house:
        return const Color(0xFFC0C0C0);
      case TowerTier.building:
        return AppColors.gold;
      case TowerTier.skyscraper:
        return AppColors.teal;
      case TowerTier.landmark:
        return const Color(0xFFFF6B9D);
    }
  }

  void _showCommunityTowerDetail(
    BuildContext ctx,
    int rank,
    Map<String, Object> m,
  ) {
    final tier = m['tier'] as TowerTier;
    final floors = m['floors'] as int;
    final flag = m['flag'] as String;
    final name = m['name'] as String;
    final label = m['label'] as String;
    final tierColor = _communityTierColor(tier);

    // 층수에서 타워 높이 계산 (내 타워와 동일 공식)
    final towerH = (60 + floors * 4.0).clamp(60.0, 240.0);

    final rankLabel = rank == 1
        ? '🥇 1위'
        : rank == 2
        ? '🥈 2위'
        : rank == 3
        ? '🥉 3위'
        : '🌍 ${rank}위';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tierColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // 국기 + 이름
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgSurface,
                    border: Border.all(color: tierColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withOpacity(0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(flag, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tierColor.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              '${tier.emoji}  $label',
                              style: TextStyle(
                                color: tierColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 통계 카드 2개
            Row(
              children: [
                // 세계 랭킹
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          rankLabel,
                          style: TextStyle(
                            color: rank <= 3
                                ? AppColors.gold
                                : AppColors.textSecondary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '세계 랭킹',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 건물 층수
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tierColor.withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${floors}F',
                          style: TextStyle(
                            color: tierColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '건물 층수',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 타워 높이 프로그레스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2D44)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '타워 높이',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${towerH.toInt()}px',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: towerH / 240.0,
                      backgroundColor: AppColors.bgDeep,
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgSurface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext ctx, AppState state) {
    final nameCtrl = TextEditingController(text: state.currentUser.username);
    final socialCtrl = TextEditingController(
      text: state.currentUser.socialLink ?? '',
    );
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('프로필 수정', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  prefixIcon: Icon(
                    Icons.person_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: socialCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'SNS 링크 (선택)',
                  prefixIcon: Icon(
                    Icons.link_rounded,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  hintText: 'https://instagram.com/...',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final username = nameCtrl.text.trim().isNotEmpty
                        ? nameCtrl.text.trim()
                        : null;
                    final socialLink = socialCtrl.text.trim().isNotEmpty
                        ? socialCtrl.text.trim()
                        : null;
                    // AppState + SharedPreferences 동시 업데이트
                    state.updateProfile(
                      username: username,
                      socialLink: socialLink,
                    );
                    await AuthService.updateProfile(
                      username: username,
                      socialLink: socialLink,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext ctx, AppState state) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_rounded,
                color: AppColors.textSecondary,
              ),
              title: const Text(
                '설정',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(color: Color(0xFF1F2D44)),
            ListTile(
              leading: const Icon(Icons.mail_rounded, color: AppColors.teal),
              title: const Text(
                '받은 편지 관리',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                '총 ${state.inbox.length}통',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showLetterManagement(ctx, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded, color: AppColors.gold),
              title: const Text(
                '보낸 편지 관리',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                '총 ${state.sent.length}통',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showLetterManagement(ctx, state, showSent: true);
              },
            ),
            const Divider(color: Color(0xFF1F2D44)),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: AppColors.textMuted,
              ),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmLogout(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
              title: const Text(
                '회원탈퇴',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLetterManagement(
    BuildContext ctx,
    AppState state, {
    bool showSent = false,
  }) {
    final letters = showSent
        ? state.sent.reversed.toList()
        : state.inbox.reversed.toList();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    showSent
                        ? '📤 보낸 편지 (${letters.length})'
                        : '📬 받은 편지 (${letters.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: letters.isEmpty
                  ? const Center(
                      child: Text(
                        '편지가 없습니다',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: letters.length,
                      itemBuilder: (_, i) {
                        final l = letters[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1F2D44)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                showSent
                                    ? l.destinationCountryFlag
                                    : l.senderCountryFlag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      showSent
                                          ? '→ ${l.destinationCountry}'
                                          : (l.isAnonymous
                                                ? '익명의 편지'
                                                : l.senderName),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!showSent && l.status == DeliveryStatus.read)
                                const Text(
                                  '✓',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                  ),
                                )
                              else if (!showSent)
                                const Text(
                                  '●',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                  ),
                                ),
                              if (showSent && l.isReadByRecipient)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '읽음',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '회원탈퇴',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.deleteAccount();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              Navigator.of(ctx).pushNamedAndRemoveUntil('/auth', (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '정말 로그아웃 하시겠어요?\n편지와 타워 데이터는 유지됩니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 통계 카드 ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final double contribution;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.contribution,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D44)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '+${contribution.toStringAsFixed(1)}점',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 성취 배지 ─────────────────────────────────────────────────────────────────
class _Achievement {
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;

  const _Achievement({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.unlocked,
  });
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? AppColors.bgCard
            : AppColors.bgCard.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achievement.unlocked
              ? AppColors.gold.withOpacity(0.4)
              : const Color(0xFF1F2D44),
          width: achievement.unlocked ? 1.5 : 1.0,
        ),
        boxShadow: achievement.unlocked
            ? [BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 8)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.unlocked ? achievement.emoji : '🔒',
            style: TextStyle(
              fontSize: 26,
              color: achievement.unlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.title,
            style: TextStyle(
              color: achievement.unlocked
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            achievement.desc,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── 타워 그리기 CustomPainter ─────────────────────────────────────────────────
class _TowerPainter extends CustomPainter {
  final int floors;
  final TowerTier tier;
  final double glowIntensity;

  _TowerPainter({
    required this.floors,
    required this.tier,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tier == TowerTier.cottage || tier == TowerTier.house) {
      _drawHouse(canvas, size);
    } else {
      _drawSkyscraper(canvas, size);
    }
  }

  void _drawHouse(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 벽
    final wallPaint = Paint()
      ..color = const Color(0xFF1A2B4A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.5, w * 0.8, h * 0.5),
        const Radius.circular(4),
      ),
      wallPaint,
    );

    // 지붕
    final roofPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final roofPath = Path()
      ..moveTo(w * 0.0, h * 0.5)
      ..lineTo(w * 0.5, h * 0.1)
      ..lineTo(w * 1.0, h * 0.5)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // 창문
    final winPaint = Paint()
      ..color = AppColors.goldLight.withOpacity(0.6 + glowIntensity * 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.6, w * 0.3, h * 0.2),
        const Radius.circular(3),
      ),
      winPaint,
    );

    // 글로우
    final glowPaint = Paint()
      ..color = AppColors.gold.withOpacity(glowIntensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);
  }

  void _drawSkyscraper(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floorCount = floors.clamp(5, 50);
    final floorH = h / floorCount;

    // 빌딩 윤곽 (테이퍼 형태)
    for (int i = 0; i < floorCount; i++) {
      final tapering = 1.0 - (i / floorCount) * 0.3;
      final floorW = w * tapering;
      final floorX = (w - floorW) / 2;
      final floorY = h - (i + 1) * floorH;

      // 층 배경
      final floorBg = Paint()
        ..color = const Color(0xFF1A2B4A)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(floorX, floorY, floorW, floorH * 0.9),
        floorBg,
      );

      // 창문들
      final windowsPerFloor = (floorW / 14).floor().clamp(1, 8);
      final windowW = (floorW - 4) / windowsPerFloor;
      for (int j = 0; j < windowsPerFloor; j++) {
        final rng = Random(i * 100 + j);
        final litUp = rng.nextDouble() > 0.3;
        final winPaint = Paint()
          ..color = litUp
              ? AppColors.goldLight.withOpacity(0.5 + glowIntensity * 0.4)
              : const Color(0xFF0D1F3C)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(
            floorX + 2 + j * windowW + 1,
            floorY + 2,
            windowW - 3,
            floorH * 0.7,
          ),
          winPaint,
        );
      }

      // 층 구분선
      final linePaint = Paint()
        ..color = AppColors.gold.withOpacity(0.08)
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(floorX, floorY + floorH * 0.9),
        Offset(floorX + floorW, floorY + floorH * 0.9),
        linePaint,
      );
    }

    // 꼭대기 안테나/스파이어
    if (tier == TowerTier.skyscraper || tier == TowerTier.landmark) {
      final spireP = Paint()
        ..color = AppColors.gold.withOpacity(0.9)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h * 0.05), spireP);
      // 안테나 불빛
      final blinkPaint = Paint()
        ..color = AppColors.error.withOpacity(glowIntensity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(w / 2, 3), 3, blinkPaint);
    }

    // 전체 글로우
    final glowPaint = Paint()
      ..color = AppColors.gold.withOpacity(glowIntensity * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.9),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_TowerPainter old) =>
      old.floors != floors ||
      old.tier != tier ||
      (old.glowIntensity - glowIntensity).abs() > 0.01;
}

// ── 스카이라인 배경 ─────────────────────────────────────────────────────────────
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D1A30)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    final rng = Random(42);
    final buildings = 12;
    final segW = size.width / buildings;

    for (int i = 0; i < buildings; i++) {
      final bH = rng.nextDouble() * size.height * 0.7 + size.height * 0.1;
      final bW = segW * (0.5 + rng.nextDouble() * 0.5);
      final bX = i * segW;
      path.lineTo(bX, size.height - bH);
      path.lineTo(bX + bW, size.height - bH);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // 창문 점들
    final winPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final rng2 = Random(i * 7);
      canvas.drawRect(
        Rect.fromLTWH(
          rng2.nextDouble() * size.width,
          rng2.nextDouble() * size.height * 0.7 + 10,
          3,
          4,
        ),
        winPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
