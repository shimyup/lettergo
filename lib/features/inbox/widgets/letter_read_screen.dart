import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/letter_style.dart';
import '../../../core/localization/language_config.dart';
import '../../../models/letter.dart';
import '../../../state/app_state.dart';
import '../../compose/screens/compose_screen.dart';
import '../../../models/direct_message.dart';
import '../../dm/dm_conversation_screen.dart';

class LetterReadScreen extends StatefulWidget {
  final Letter letter;
  final String userLanguageCode;

  const LetterReadScreen({
    super.key,
    required this.letter,
    this.userLanguageCode = 'ko',
  });

  @override
  State<LetterReadScreen> createState() => _LetterReadScreenState();
}

class _LetterReadScreenState extends State<LetterReadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _openController;
  late Animation<double> _openAnimation;
  bool _isOpened = false;
  bool _isTranslated = false;
  bool _isTranslating = false;
  String? _translatedText;
  String? _translateError;
  bool _hasLiked = false;
  int _userRating = 0; // 0 = 미선택, 1-5 = 별점

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _openAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutBack,
    );
    // 봉투 열기 애니메이션 시작
    Future.delayed(const Duration(milliseconds: 300), () {
      _openController.forward().then((_) {
        if (mounted) setState(() => _isOpened = true);
      });
    });
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  // SNS 링크 열기
  Future<void> _launchSnsLink(String rawUrl) async {
    // http(s):// 없으면 자동 추가
    final urlStr = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('링크를 열 수 없어요: $urlStr'),
          backgroundColor: const Color(0xFF1F2D44),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // MyMemory 번역 API 호출
  Future<void> _doTranslate(String text, String fromLang, String toLang) async {
    if (fromLang == toLang) {
      setState(() {
        _translatedText = text;
        _translateError = null;
        _isTranslated = true;
        _isTranslating = false;
      });
      return;
    }
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$fromLang|$toLang',
      );
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(uri);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final translated =
          (json['responseData'] as Map<String, dynamic>?)?['translatedText']
              as String?;
      if (translated != null && translated.isNotEmpty) {
        setState(() {
          _translatedText = translated;
          _translateError = null;
          _isTranslated = true;
          _isTranslating = false;
        });
      } else {
        setState(() {
          _translateError = '번역 결과를 가져오지 못했어요';
          _isTranslating = false;
        });
      }
      client.close();
    } catch (_) {
      if (mounted) {
        setState(() {
          _translateError = '번역 중 오류가 발생했어요';
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // 배경 별빛
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _LetterBgPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, letter),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _openAnimation,
                    builder: (_, __) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // 발신자 정보 카드
                            _buildSenderCard(letter),
                            const SizedBox(height: 20),
                            // 편지 본문
                            Transform.scale(
                              scale: _openAnimation.value.clamp(0.8, 1.0),
                              child: Opacity(
                                opacity: _openAnimation.value.clamp(0.0, 1.0),
                                child: _buildLetterContent(letter),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_isOpened) _buildReactionBar(context, letter),
                            const SizedBox(height: 12),
                            if (_isOpened)
                              Consumer<AppState>(
                                builder: (ctx, state, _) {
                                  final status = state.getChatStatus(
                                    letter.senderId,
                                  );
                                  if (status == ChatStatus.pendingAgreement) {
                                    return _buildChatInviteCard(
                                      ctx,
                                      letter,
                                      state,
                                    );
                                  }
                                  if (status == ChatStatus.chatting) {
                                    return _buildDMButton(ctx, letter);
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            const SizedBox(height: 24),
                            // 배송 여정
                            if (_isOpened) _buildJourneyCard(letter),
                            const SizedBox(height: 24),
                            // 답장 버튼
                            if (_isOpened) _buildReplyButton(context, letter),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext ctx, Letter letter, AppState state) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '편지 신고',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          '이 편지를 신고하시겠어요?\n3회 이상 신고된 발신자는 자동으로 차단됩니다.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.6,
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
            onPressed: () {
              state.reportLetter(letter.id, state.currentUser.id);
              Navigator.pop(ctx);
              Navigator.pop(ctx); // 편지 화면 닫기
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('신고가 접수되었습니다. 검토 후 조치됩니다.'),
                  backgroundColor: Color(0xFF1F2D44),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              '신고',
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

  Widget _buildReactionBar(BuildContext ctx, Letter letter) {
    return Consumer<AppState>(
      builder: (ctx2, state, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2D44)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '편지에 반응하기',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // 좋아요 버튼
                GestureDetector(
                  onTap: () {
                    if (!_hasLiked) {
                      setState(() => _hasLiked = true);
                      state.likeLetter(letter.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _hasLiked
                          ? AppColors.gold.withOpacity(0.15)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _hasLiked
                            ? AppColors.gold.withOpacity(0.5)
                            : const Color(0xFF1F2D44),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _hasLiked ? '❤️' : '🤍',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${letter.likeCount}',
                          style: TextStyle(
                            color: _hasLiked
                                ? AppColors.gold
                                : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 별점
                Expanded(
                  child: Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () {
                          final prev = _userRating;
                          setState(() => _userRating = star);
                          if (prev == 0) {
                            state.rateLetter(letter.id, star);
                          } else {
                            // 별점 변경: 이전 별점 취소 후 새 별점 적용
                            state.updateRating(letter.id, prev, star);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            star <= _userRating ? '⭐' : '☆',
                            style: TextStyle(
                              fontSize: 20,
                              color: star <= _userRating
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            if (_userRating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '별점 ${_userRating}점 (편지함 나가기 전까지 변경 가능)',
                  style: const TextStyle(color: AppColors.gold, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext ctx, Letter letter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              '✉️  받은 편지',
              textAlign: TextAlign.center,
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Consumer<AppState>(
            builder: (ctx2, state, _) => IconButton(
              onPressed: () => _showReportDialog(ctx, letter, state),
              icon: const Icon(
                Icons.flag_outlined,
                color: AppColors.error,
                size: 20,
              ),
              tooltip: '신고하기',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderCard(Letter letter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          // 국가 플래그
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                letter.senderCountryFlag,
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
                  letter.isAnonymous ? '🎭 익명의 발신자' : letter.senderName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 12,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${letter.senderCountry}에서 출발',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(letter.sentAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // SNS 링크
          if (letter.socialLink != null)
            GestureDetector(
              onTap: () => _launchSnsLink(letter.socialLink!),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.teal,
                  size: 18,
                ),
              ),
            ),
          if (letter.socialLink != null) const SizedBox(width: 8),
          // Follow button (익명 편지에서는 팔로우 불가)
          if (!letter.isAnonymous)
            Consumer<AppState>(
              builder: (ctx, state, _) {
                final isFollowing = state.isFollowing(letter.senderId);
                return GestureDetector(
                  onTap: () {
                    if (isFollowing) {
                      state.unfollowUser(letter.senderId);
                    } else {
                      state.followUser(
                        letter.senderId,
                        letter.senderName,
                        country: letter.senderCountry,
                        flag: letter.senderCountryFlag,
                      );
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('${letter.senderName}님을 팔로우했습니다 ⚡'),
                          backgroundColor: const Color(0xFF0D1421),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? AppColors.teal.withOpacity(0.15)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFollowing
                            ? AppColors.teal.withOpacity(0.5)
                            : const Color(0xFF1F2D44),
                      ),
                    ),
                    child: Text(
                      isFollowing ? '⚡ 팔로잉' : '+ 팔로우',
                      style: TextStyle(
                        color: isFollowing
                            ? AppColors.teal
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChatInviteCard(BuildContext ctx, Letter letter, AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${letter.senderName}님도 팔로우 중이에요!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '빠른 1:1 편지 대화를 시작하시겠어요?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    state.acceptChatInvite(letter.senderId);
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => DmConversationScreen(
                          partnerId: letter.senderId,
                          partnerName: letter.senderName,
                          partnerFlag: letter.senderCountryFlag,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.teal.withOpacity(0.5),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '💬 대화 시작',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => state.declineChatInvite(letter.senderId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1F2D44)),
                  ),
                  child: const Text(
                    '나중에',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDMButton(BuildContext ctx, Letter letter) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => DmConversationScreen(
              partnerId: letter.senderId,
              partnerName: letter.senderName,
              partnerFlag: letter.senderCountryFlag,
            ),
          ),
        ),
        icon: const Text('💬', style: TextStyle(fontSize: 16)),
        label: Text(
          '${letter.senderName}님과 DM 대화',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: BorderSide(color: AppColors.teal.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterContent(Letter letter) {
    final paper = LetterStyles.paper(letter.paperStyle);
    final font = LetterStyles.font(letter.fontStyle);
    final fromLang = LanguageConfig.getLanguageCode(letter.senderCountry);
    final toLang = widget.userLanguageCode;
    final canTranslate = fromLang != toLang;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: LetterPaperPainter(paper),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 편지지 헤더
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    color: AppColors.gold.withOpacity(0.5),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '당신에게',
                    style: TextStyle(
                      color: AppColors.gold.withOpacity(0.7),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 편지 내용 (원문 또는 번역)
              Text(
                _isTranslated && _translatedText != null
                    ? _translatedText!
                    : letter.content,
                style: font.textStyle.copyWith(color: paper.inkColor),
              ),
              if (canTranslate && _isTranslated && _translatedText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '🔤 번역됨 (${_langLabel(widget.userLanguageCode)})',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (canTranslate && _translateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ $_translateError',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (canTranslate)
                GestureDetector(
                  onTap: () async {
                    if (_isTranslating) return;
                    if (_isTranslated) {
                      // 원문으로 되돌리기
                      setState(() {
                        _isTranslated = false;
                        _translateError = null;
                      });
                      return;
                    }
                    setState(() {
                      _isTranslating = true;
                      _translateError = null;
                    });
                    await _doTranslate(letter.content, fromLang, toLang);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.teal.withOpacity(0.3),
                      ),
                    ),
                    child: _isTranslating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.teal,
                            ),
                          )
                        : Text(
                            _isTranslated ? '🔤 원문 보기' : '🔤 번역하기',
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              if (canTranslate) const SizedBox(height: 16),
              // 서명
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— ${letter.isAnonymous ? "어딘가의 낯선 이" : letter.senderName}',
                  style: TextStyle(
                    color: AppColors.gold.withOpacity(0.6),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCard(Letter letter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2D44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.teal, size: 16),
              SizedBox(width: 6),
              Text(
                '배송 여정',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                letter.senderCountryFlag,
                style: const TextStyle(fontSize: 24),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 1,
                      color: AppColors.gold.withOpacity(0.3),
                    ),
                    const Icon(
                      Icons.flight_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
              Text(
                letter.destinationCountryFlag,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                letter.senderCountry,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                '${_calcDistance(letter)} km',
                style: const TextStyle(color: AppColors.teal, fontSize: 11),
              ),
              Text(
                letter.destinationCountry,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext ctx, Letter letter) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => ComposeScreen(
              replyToId: letter.id,
              replyToName: letter.isAnonymous ? '익명' : letter.senderName,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgCard,
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💌', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              '답장 쓰기',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  String _calcDistance(Letter letter) {
    final dist = letter.originLocation.distanceTo(letter.destinationLocation);
    return (dist / 1000).toStringAsFixed(0);
  }
}

String _langLabel(String code) {
  const labels = {
    'ko': '한국어',
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'pt': 'Português',
  };
  return labels[code] ?? code;
}

class _LetterBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withOpacity(0.03);
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
