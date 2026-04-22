import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/letter.dart';
import '../../state/app_state.dart';

/// Build 142: 앱 시작 시 지도 상단에 자동 슬라이드-다운 되는 브랜드 홍보
/// 배너 광고. 이전 `_BrandPromoTicket` 의 center modal 을 대체.
///
/// 동작:
///   - `initState` 직후 850ms 지연 후 표시 (지도 첫 렌더 뒤 부드럽게 등장)
///   - 8초 뒤 자동 접힘 (유저 탭 없을 때). 탭 하면 `onTap` 콜백 → 지도 이동
///   - 세션 내 1회만 — `state.promoShownThisSession` 플래그 + 앱 재시작 시 리셋
///   - Brand 본인은 숨김 (자기 캠페인이라 광고 대상 아님)
///   - 활성 브랜드 coupon/voucher 가 없으면 null 편지 → 렌더 안 함
///
/// 레이아웃:
///   - 가로 꽉 찬 노란 그라데이션 카드 (이전 티켓 톤 재사용)
///   - 좌측 🎟 이모지 / 가운데 "브랜드명 · 타이틀" / 우측 "자세히" CTA + ✕
class BrandPromoBanner extends StatefulWidget {
  final VoidCallback? onTapLetter; // 편지 상세 열기 콜백 (optional)
  final void Function(Letter letter)? onRevealOnMap; // 지도 좌표 이동 콜백

  const BrandPromoBanner({
    super.key,
    this.onTapLetter,
    this.onRevealOnMap,
  });

  @override
  State<BrandPromoBanner> createState() => _BrandPromoBannerState();
}

class _BrandPromoBannerState extends State<BrandPromoBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slide;
  Letter? _promo;
  bool _showing = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShow();
    });
  }

  Future<void> _maybeShow() async {
    final state = context.read<AppState>();
    if (state.currentUser.isBrand) return;
    if (state.promoShownThisSession) return;
    final promo = state.featuredBrandPromo;
    if (promo == null) return;

    setState(() {
      _promo = promo;
      _showing = true;
    });
    state.markPromoShownThisSession();

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    _slideCtrl.forward();

    // 8초 후 자동 접힘.
    await Future.delayed(const Duration(seconds: 8));
    if (!mounted || _dismissed) return;
    _hide();
  }

  Future<void> _hide() async {
    if (!_showing) return;
    _dismissed = true;
    await _slideCtrl.reverse();
    if (!mounted) return;
    setState(() => _showing = false);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showing || _promo == null) return const SizedBox.shrink();
    final l10n = AppL10n.of(
      context.read<AppState>().currentUser.languageCode,
    );
    final promo = _promo!;
    final brandName = promo.senderName.isNotEmpty
        ? promo.senderName
        : l10n.brandTicketDefaultBrand;
    final title = _extractTitle(promo.content, l10n);

    return SlideTransition(
      position: _slide,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              widget.onRevealOnMap?.call(promo);
              widget.onTapLetter?.call();
              _hide();
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎟', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                brandName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6B4A00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.brandPromoBannerAdLabel,
                              style: TextStyle(
                                color: const Color(0xFF6B4A00)
                                    .withValues(alpha: 0.55),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2B1A00),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B1A00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.brandPromoBannerCTA,
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _hide,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: const Color(0xFF6B4A00).withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _extractTitle(String content, AppL10n l) {
    final firstLine = content.split('\n').firstWhere(
          (s) => s.trim().isNotEmpty,
          orElse: () => '',
        );
    final trimmed = firstLine.trim();
    if (trimmed.isEmpty) return l.brandTicketFallbackTitle;
    if (trimmed.length <= 28) return trimmed;
    return '${trimmed.substring(0, 26)}…';
  }
}
