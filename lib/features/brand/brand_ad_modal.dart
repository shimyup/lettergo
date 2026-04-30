import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';
import '../inbox/widgets/letter_read_screen.dart';

/// Build 202 — 온보딩 직후 1회 표시되는 브랜드 광고 모달.
///
/// 디자인:
/// - 화면 약 60% 차지하는 중앙 모달
/// - 상단 50%: 브랜드 광고 이미지
/// - 중간: 브랜드명 (UPPERCASE eyebrow) + 큰 헤드라인 + 본문 스니펫
/// - 하단: "닫기" (ghost) + "편지 받기" (solid coupon) 두 개 버튼
///
/// 트리거:
/// - main_scaffold initState 의 postFrameCallback 에서 1회 호출
/// - hasShownToday 체크로 같은 날 중복 노출 방지
/// - featuredBrandPromo 가 null 이면 미노출
class BrandAdModal {
  static const String _prefKey = 'brand_ad_last_shown_date';

  /// 오늘 이미 한 번 보여준 적이 없고 활성 브랜드 광고가 있으면 표시.
  static Future<void> showIfDue(BuildContext context) async {
    if (!context.mounted) return;
    final state = context.read<AppState>();
    final promo = state.featuredBrandPromo;
    if (promo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefKey);
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    if (lastShown == today) return;

    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    await prefs.setString(_prefKey, today);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _BrandAdDialog(letter: promo),
    );
  }

  /// 디버그/QA: 강제 표시.
  static void showForce(BuildContext context, Letter letter) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _BrandAdDialog(letter: letter),
    );
  }
}

class _BrandAdDialog extends StatelessWidget {
  final Letter letter;

  const _BrandAdDialog({required this.letter});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final mq = MediaQuery.of(context);
    final modalHeight = mq.size.height * 0.62;
    final imageUrl = letter.imageUrl;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: modalHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ── 이미지 영역 (상단 ~50%) ──────────────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: AppColors.bgSurface,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? _buildImage(imageUrl)
                      : _buildPlaceholder(),
                ),
              ),
              // ── 텍스트 + 버튼 영역 (하단 ~50%) ────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 브랜드 eyebrow
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coupon,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'BRAND · ${letter.senderName.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF1A0008),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 큰 제목
                      Text(
                        _firstLine(letter.content),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 본문 스니펫
                      Expanded(
                        child: Text(
                          _bodySnippet(letter.content),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // CTA 두 개
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  AppL10n.of(state.currentUser.languageCode)
                                      .languageCode
                                      .startsWith('ko')
                                      ? '닫기'
                                      : 'Close',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                _pickUp(context);
                              },
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.coupon,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.coupon
                                          .withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '편지 받기',
                                  style: TextStyle(
                                    color: Color(0xFF1A0008),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    final isNet = url.startsWith('http://') || url.startsWith('https://');
    if (isNet) {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    final f = File(url);
    if (!f.existsSync()) return _buildPlaceholder();
    return Image.file(
      f,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.bgSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 56,
        color: AppColors.textMuted,
      ),
    );
  }

  void _pickUp(BuildContext context) {
    final state = context.read<AppState>();
    state.readLetter(letter.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LetterReadScreen(
          letter: letter,
          userLanguageCode: state.currentUser.languageCode,
        ),
      ),
    );
  }

  String _firstLine(String content) {
    final lines = content.trim().split('\n');
    final first = lines.first.trim();
    if (first.isEmpty && lines.length > 1) return lines[1].trim();
    return first.isEmpty ? '광고' : first;
  }

  String _bodySnippet(String content) {
    final lines = content.trim().split('\n');
    if (lines.length <= 1) return content.trim();
    return lines.skip(1).join(' ').trim();
  }
}
