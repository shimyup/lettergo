import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../state/app_state.dart';
import '../../../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifyNearby = true;
  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyNearby = prefs.getBool('notify_nearby') ?? true;
      _loading = false;
    });
  }

  Future<void> _setNotifyNearby(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_nearby', value);
    setState(() => _notifyNearby = value);
  }

  void _showNicknameCooldownMessage(BuildContext ctx, AppState state) {
    final next = state.nextNicknameChangeAvailableAt;
    final dateLabel = next == null
        ? ''
        : ' (${next.year}.${next.month.toString().padLeft(2, '0')}.${next.day.toString().padLeft(2, '0')} 이후)';
    _showSnack(
      ctx,
      '닉네임은 3개월에 1회만 변경할 수 있어요. 약 ${state.nicknameChangeRemainingDays}일 남았습니다$dateLabel',
    );
  }

  // ── 닉네임 수정 ────────────────────────────────────────────────────────────
  void _editUsername(BuildContext ctx, AppState state) {
    final ctrl = TextEditingController(text: state.currentUser.username);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '닉네임 수정',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          maxLength: 20,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '새 닉네임',
            hintStyle: TextStyle(color: AppColors.textMuted),
            counterStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.teal),
            ),
          ),
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
              final name = ctrl.text.trim();
              if (name.length < 2) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('닉네임은 2자 이상이어야 합니다'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (name == state.currentUser.username) {
                if (ctx.mounted) Navigator.pop(ctx);
                return;
              }
              if (!state.canChangeNicknameNow()) {
                _showNicknameCooldownMessage(ctx, state);
                return;
              }
              await AuthService.updateProfile(username: name);
              final changed = state.updateUsername(name);
              if (!changed) {
                _showNicknameCooldownMessage(ctx, state);
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  // ── SNS 링크 수정 ──────────────────────────────────────────────────────────
  void _editSnsLink(BuildContext ctx, AppState state) {
    final ctrl = TextEditingController(
      text: state.currentUser.socialLink ?? '',
    );
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'SNS 링크 수정',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'https://instagram.com/...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.teal),
            ),
          ),
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
              final link = ctrl.text.trim();
              await AuthService.updateProfile(socialLink: link);
              state.updateSocialLink(link.isEmpty ? null : link);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfileImage(BuildContext ctx, AppState state) async {
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.teal,
                  ),
                  title: const Text(
                    '앨범에서 선택',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1400,
                      maxHeight: 1400,
                      imageQuality: 90,
                    );
                    if (picked == null || !mounted) return;

                    final appDir = await getApplicationDocumentsDirectory();
                    final ext = picked.path.contains('.')
                        ? picked.path.split('.').last
                        : 'jpg';
                    final newPath =
                        '${appDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
                    await File(picked.path).copy(newPath);

                    final oldPath = state.currentUser.profileImagePath;
                    state.updateProfileImage(newPath);
                    if (oldPath != null &&
                        oldPath.isNotEmpty &&
                        oldPath != newPath &&
                        oldPath.startsWith(appDir.path)) {
                      try {
                        final oldFile = File(oldPath);
                        if (await oldFile.exists()) await oldFile.delete();
                      } catch (_) {}
                    }
                    if (mounted) _showSnack(ctx, '프로필 사진이 변경되었습니다');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    '기본 아바타로 변경',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final oldPath = state.currentUser.profileImagePath;
                    state.updateProfileImage(null);
                    if (oldPath != null && oldPath.isNotEmpty) {
                      try {
                        final oldFile = File(oldPath);
                        if (await oldFile.exists()) await oldFile.delete();
                      } catch (_) {}
                    }
                    if (mounted) _showSnack(ctx, '기본 아바타로 변경되었습니다');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showThemeModeSelector(BuildContext ctx, AppState state) async {
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '화면 모드 선택',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RadioListTile<DisplayThemeMode>(
                  value: DisplayThemeMode.auto,
                  groupValue: state.displayThemeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateDisplayThemeMode(v);
                    Navigator.pop(sheetCtx);
                  },
                  title: const Text(
                    '자동 (시간대)',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    '국가 시간에 따라 낮/밤 테마 자동 변경',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  activeColor: AppColors.gold,
                ),
                RadioListTile<DisplayThemeMode>(
                  value: DisplayThemeMode.light,
                  groupValue: state.displayThemeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateDisplayThemeMode(v);
                    Navigator.pop(sheetCtx);
                  },
                  title: const Text(
                    '밝은 모드',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    '항상 낮 테마로 표시',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  activeColor: AppColors.gold,
                ),
                RadioListTile<DisplayThemeMode>(
                  value: DisplayThemeMode.dark,
                  groupValue: state.displayThemeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateDisplayThemeMode(v);
                    Navigator.pop(sheetCtx);
                  },
                  title: const Text(
                    '다크 모드',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    '항상 밤 테마로 표시',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  activeColor: AppColors.gold,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 비밀번호 변경 ──────────────────────────────────────────────────────────
  void _changePassword(BuildContext ctx) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pwField(oldCtrl, '현재 비밀번호'),
            const SizedBox(height: 12),
            _pwField(newCtrl, '새 비밀번호 (6자 이상)'),
            const SizedBox(height: 12),
            _pwField(confirmCtrl, '새 비밀번호 확인'),
          ],
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
              if (newCtrl.text.length < 6) {
                _showSnack(ctx, '비밀번호는 6자 이상이어야 합니다');
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                _showSnack(ctx, '새 비밀번호가 일치하지 않습니다');
                return;
              }
              final user = await AuthService.getCurrentUser();
              if (user == null) return;
              final err = await AuthService.login(
                username: user['username'] ?? '',
                password: oldCtrl.text,
              );
              if (err != null) {
                if (ctx.mounted) _showSnack(ctx, '현재 비밀번호가 올바르지 않습니다');
                return;
              }
              await AuthService.updatePassword(newCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSnack(ctx, '비밀번호가 변경되었습니다 ✓');
              }
            },
            child: const Text('변경', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textMuted),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.teal),
        ),
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAvatarContent(UserProfile user) {
    final imagePath = user.profileImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, fit: BoxFit.cover, width: 64, height: 64),
        );
      }
    }
    return Center(
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.bgDeep,
        ),
      ),
    );
  }

  // ── 로그아웃 ───────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '정말 로그아웃 하시겠어요?',
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
            child: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── 회원탈퇴 ───────────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원탈퇴', style: TextStyle(color: AppColors.error)),
        content: const Text(
          '계정을 삭제하면 모든 편지와 데이터가 영구적으로 사라집니다.\n정말 탈퇴하시겠어요?',
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
              await AuthService.deleteAccount();
              if (ctx.mounted) {
                Navigator.of(
                  ctx,
                ).pushNamedAndRemoveUntil('/auth', (_) => false);
              }
            },
            child: const Text('탈퇴', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowSection(
    BuildContext ctx,
    AppState state,
    UserProfile user,
  ) {
    return DefaultTabController(
      length: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2D44)),
        ),
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: '👥 팔로잉 ${user.followingIds.length}'),
                Tab(text: '🌟 팔로워 ${user.followerIds.length}'),
              ],
            ),
            SizedBox(
              height: user.followingIds.isEmpty && user.followerIds.isEmpty
                  ? 100
                  : 200,
              child: TabBarView(
                children: [
                  _FollowListContent(
                    title: '팔로잉',
                    userIds: user.followingIds,
                    sessions: state.chatSessions,
                  ),
                  _FollowListContent(
                    title: '팔로워',
                    userIds: user.followerIds,
                    sessions: state.chatSessions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final user = state.currentUser;

        return Scaffold(
          backgroundColor: AppTimeColors.of(ctx).bgDeep,
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                )
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(ctx, user, state),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildStatsRow(ctx, state, user),
                          const SizedBox(height: 8),
                          _buildFollowSection(ctx, state, user),
                          const SizedBox(height: 8),
                          _sectionHeader('계정'),
                          _tile(
                            icon: Icons.person_rounded,
                            label: '닉네임',
                            trailing: Text(
                              user.username,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => _editUsername(ctx, state),
                          ),
                          _tile(
                            icon: Icons.account_circle_rounded,
                            label: '프로필 사진',
                            trailing: Text(
                              user.profileImagePath?.isNotEmpty == true
                                  ? '설정됨'
                                  : '기본',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => _changeProfileImage(ctx, state),
                          ),
                          _tile(
                            icon: Icons.link_rounded,
                            label: 'SNS 링크',
                            trailing: Text(
                              user.socialLink?.isNotEmpty == true
                                  ? user.socialLink!
                                  : '미설정',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            onTap: () => _editSnsLink(ctx, state),
                          ),
                          _tile(
                            icon: Icons.lock_outline_rounded,
                            label: '비밀번호 변경',
                            onTap: () => _changePassword(ctx),
                          ),
                          const SizedBox(height: 8),
                          _sectionHeader('공개 설정'),
                          _switchTile(
                            icon: Icons.badge_rounded,
                            label: '닉네임 공개',
                            subtitle: '다른 사용자에게 닉네임 표시',
                            value: user.isUsernamePublic,
                            onChanged: (v) => state.updatePrivacySettings(
                              isUsernamePublic: v,
                            ),
                          ),
                          _switchTile(
                            icon: Icons.link_rounded,
                            label: 'SNS 링크 공개',
                            subtitle: '편지에 SNS 링크 노출 허용',
                            value: user.isSnsPublic,
                            onChanged: (v) =>
                                state.updatePrivacySettings(isSnsPublic: v),
                          ),
                          const SizedBox(height: 8),
                          _sectionHeader('알림'),
                          _switchTile(
                            icon: Icons.notifications_active_rounded,
                            label: '근처 편지 알림',
                            subtitle: '500m 이내에 편지가 도착하면 알림',
                            value: _notifyNearby,
                            onChanged: _setNotifyNearby,
                          ),
                          const SizedBox(height: 8),
                          _sectionHeader('화면'),
                          _tile(
                            icon: Icons.brightness_6_rounded,
                            label: '화면 모드',
                            trailing: Text(
                              state.displayThemeModeLabel,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => _showThemeModeSelector(ctx, state),
                          ),
                          const SizedBox(height: 8),
                          _sectionHeader('앱 정보'),
                          _tile(
                            icon: Icons.info_outline_rounded,
                            label: '버전',
                            trailing: const Text(
                              '1.0.0',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _tile(
                            icon: Icons.public_rounded,
                            label: '나라',
                            trailing: Text(
                              '${user.countryFlag} ${user.country}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _sectionHeader('계정 관리'),
                          _tile(
                            icon: Icons.logout_rounded,
                            label: '로그아웃',
                            color: AppColors.textSecondary,
                            onTap: () => _confirmLogout(ctx),
                          ),
                          _tile(
                            icon: Icons.delete_forever_rounded,
                            label: '회원탈퇴',
                            color: AppColors.error,
                            onTap: () => _confirmDeleteAccount(ctx),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ── SliverAppBar (프로필 헤더) ─────────────────────────────────────────────
  Widget _buildSliverAppBar(
    BuildContext ctx,
    UserProfile user,
    AppState state,
  ) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTimeColors.of(ctx).bgDeep,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgCard.withOpacity(0.8),
                AppTimeColors.of(ctx).bgDeep,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  // 아바타
                  GestureDetector(
                    onTap: () => _changeProfileImage(ctx, state),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.goldLight,
                                AppColors.gold,
                                AppColors.goldDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _buildAvatarContent(user),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal,
                              border: Border.all(
                                color: AppTimeColors.of(ctx).bgDeep,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 팔로잉/팔로워 수
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FollowStatChip(
                        label: '팔로잉',
                        count: user.followingIds.length,
                      ),
                      const SizedBox(width: 20),
                      _FollowStatChip(
                        label: '팔로워',
                        count: user.followerIds.length,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${user.countryFlag} ${user.country}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (user.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.goldLight, AppColors.goldDark],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: AppColors.bgDeep,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        '프로필',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── 활동 통계 카드 ─────────────────────────────────────────────────────────
  Widget _buildStatsRow(BuildContext ctx, AppState state, UserProfile user) {
    final score = user.activityScore;
    final tier = score.tier;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // 타워 등급
          Row(
            children: [
              Text(tier.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.label,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    tier.nextGoal,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 4가지 통계
          Row(
            children: [
              _statCell('보낸 편지', '${score.sentCount}', Icons.send_rounded),
              _statDivider(),
              _statCell('받은 편지', '${score.receivedCount}', Icons.mail_rounded),
              _statDivider(),
              _statCell('답장', '${score.replyCount}', Icons.reply_rounded),
              _statDivider(),
              _statCell('받은 좋아요', '${score.likeCount}', Icons.favorite_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 40, color: AppColors.bgSurface);
  }

  // ── 섹션 헤더 ──────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── 일반 타일 ──────────────────────────────────────────────────────────────
  Widget _tile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 15),
      ),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                trailing,
                const SizedBox(width: 4),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
              ],
            )
          : onTap != null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            )
          : null,
      onTap: onTap,
      tileColor: Colors.transparent,
    );
  }

  // ── 스위치 타일 ────────────────────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.teal,
        inactiveThumbColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.bgCard,
      ),
    );
  }
}

class _FollowListContent extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final Map<String, dynamic> sessions;

  const _FollowListContent({
    required this.title,
    required this.userIds,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title == '팔로잉' ? '🔭' : '🌟',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title == '팔로잉' ? '팔로잉 중인 유저가 없어요' : '아직 팔로워가 없어요',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: userIds.length,
      itemBuilder: (ctx, i) {
        final uid = userIds[i];
        final session = sessions[uid];
        final name = session?.partnerName ?? uid;
        final flag = session?.partnerFlag ?? '🌍';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (session != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text('💬', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FollowStatChip extends StatelessWidget {
  final String label;
  final int count;
  const _FollowStatChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
