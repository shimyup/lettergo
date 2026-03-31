import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/app_state.dart';
import '../config/app_keys.dart';

enum ScheduledPlanTarget { free, brand }

// ── RevenueCat API Keys ─────────────────────────────────────────────────────
// 빌드 시 dart-define 으로 주입:
//   flutter run \
//     --dart-define=REVENUECAT_IOS_KEY=appl_xxxx \
//     --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxx
//
class _RcKeys {
  static const String ios = String.fromEnvironment('REVENUECAT_IOS_KEY');
  static const String android = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );
}

// ── RevenueCat Entitlement IDs ──────────────────────────────────────────────
// RevenueCat 대시보드 → Entitlements 에서 동일하게 생성 필요
class _RcEntitlements {
  static const String premium = 'premium'; // Premium 구독
  static const String brand = 'brand'; // Brand / Creator 구독
}

// ── 상품 ID (App Store Connect / Play Console 에 동일하게 등록 필요) ──────────
class PurchaseProductIds {
  static const String premiumMonthly = 'letter_go_premium_monthly'; // ₩4,900/월
  static const String brandMonthly = 'letter_go_brand_monthly'; // ₩99,000/월
  static const String giftCard = 'letter_go_gift_1month'; // ₩8,910 (10%할인)
  static const String brandExtra1000 =
      'letter_go_brand_extra_1000'; // ₩15,000 (소모성)
}

// ── RevenueCat Offering/Package 식별자 ─────────────────────────────────────
class _RcOfferings {
  static const String defaultOffering = 'default';
}

/// UI 표시용 상품 정보
class ProductInfo {
  final String id;
  final String title;
  final String price; // 로컬 통화 가격 문자열 (RevenueCat에서 로드되면 업데이트)
  final String description;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
  });
}

// ── 구매 서비스 (RevenueCat 기반) ───────────────────────────────────────────
class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _isBrand = false;
  bool get isBrand => _isBrand;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _initialized = false;
  String? _activeAppUserId;
  SharedPreferences? _prefs; // 캐시 — getInstance() 반복 호출 방지

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _saveSecurePremiumState({
    required bool isPremium,
    required bool isBrand,
  }) async {
    await _secure.write(key: 'ps_isPremium', value: isPremium ? '1' : '0');
    await _secure.write(key: 'ps_isBrand', value: isBrand ? '1' : '0');
  }

  Future<void> _loadSecurePremiumState() async {
    _isPremium = (await _secure.read(key: 'ps_isPremium')) == '1';
    _isBrand = (await _secure.read(key: 'ps_isBrand')) == '1';
  }

  Future<void> _clearSecurePremiumState() async {
    await _secure.delete(key: 'ps_isPremium');
    await _secure.delete(key: 'ps_isBrand');
  }

  // 플랜 변경 예약 (다음 결제일부터 반영)
  DateTime? _scheduledPlanChangeDate;
  ScheduledPlanTarget? _scheduledPlanTarget;
  DateTime? get scheduledPlanChangeDate => _scheduledPlanChangeDate;
  ScheduledPlanTarget? get scheduledPlanTarget => _scheduledPlanTarget;
  bool get isPendingPlanChange =>
      _scheduledPlanChangeDate != null && _scheduledPlanTarget != null;
  bool get isPendingDowngrade =>
      isPendingPlanChange && _scheduledPlanTarget == ScheduledPlanTarget.free;
  DateTime? get scheduledDowngradeDate =>
      _scheduledPlanTarget == ScheduledPlanTarget.free
      ? _scheduledPlanChangeDate
      : null;

  // RevenueCat Offering (실제 가격 포함)
  Offerings? _offerings;
  DateTime? _nextBillingDate;
  DateTime? get nextBillingDate => _nextBillingDate;

  // UI 표시용 기본 상품 목록 (Offering 로드 전 fallback)
  List<ProductInfo> get products => const [
    ProductInfo(
      id: PurchaseProductIds.premiumMonthly,
      title: 'Premium',
      price: '₩4,900',
      description: '하루 30통 발송 · 사진 첨부 · 타워 커스텀',
    ),
    ProductInfo(
      id: PurchaseProductIds.brandMonthly,
      title: 'Brand / Creator',
      price: '₩99,000',
      description: '인증 배지 · 하루 200통 · 대량 발송 · Premium 포함',
    ),
    ProductInfo(
      id: PurchaseProductIds.giftCard,
      title: '1개월 선물권',
      price: '₩8,910',
      description: '친구에게 1개월 프리미엄 선물 (10% 할인)',
    ),
  ];

  // ── 테스트 모드 여부 (디버그 전용) ────────────────────────────────────────
  /// UI에서 테스트 모드 여부를 확인할 때 사용
  bool get isTestMode => _isTestMode;
  static const bool _allowRealPurchasesInDebug = bool.fromEnvironment(
    'RC_REAL_PURCHASES_IN_DEBUG',
    defaultValue: false,
  );

  static bool get _isTestMode {
    if (!kDebugMode) return false;
    if (_allowRealPurchasesInDebug) return false;
    return true;
  }

  static bool get _isRcKeyConfiguredForCurrentPlatform {
    final iosMissing = _RcKeys.ios.isEmpty || _RcKeys.ios.contains('XXXX');
    final androidMissing =
        _RcKeys.android.isEmpty || _RcKeys.android.contains('XXXX');
    if (defaultTargetPlatform == TargetPlatform.iOS) return !iosMissing;
    if (defaultTargetPlatform == TargetPlatform.android) return !androidMissing;
    return false;
  }

  // ── 초기화 ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 디버그 빌드에서는 SharedPreferences 폴백 (개발/테스트용)
    if (_isTestMode) {
      await _initFromPrefs();
      return;
    }
    if (!_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

      final config = PurchasesConfiguration(
        defaultTargetPlatform == TargetPlatform.android
            ? _RcKeys.android
            : _RcKeys.ios,
      );
      await Purchases.configure(config);

      // 구매 업데이트 리스너
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // 현재 상태 로드
      final info = await Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
      await _persistBillingDateToPrefs();
      final prefs = await _getPrefs();
      await _loadAndApplyScheduledPlanChange(prefs);

      // Offering 로드 (실제 스토어 가격)
      try {
        _offerings = await Purchases.getOfferings();
      } on PlatformException catch (e) {
        debugPrint('[PurchaseService] Offering 로드 실패: $e');
      }
    } on PlatformException catch (e) {
      debugPrint('[PurchaseService] RC 초기화 실패: $e');
      await _initFromPrefs(); // 폴백
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _applyCustomerInfo(info);
    unawaited(_persistBillingDateToPrefs());
    notifyListeners();
  }

  void _applyCustomerInfo(CustomerInfo info) {
    _isBrand = info.entitlements.active.containsKey(_RcEntitlements.brand);
    _isPremium =
        _isBrand ||
        info.entitlements.active.containsKey(_RcEntitlements.premium);
    _nextBillingDate = _parseRevenueCatDate(info.latestExpirationDate);
  }

  DateTime? _parseRevenueCatDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> _persistBillingDateToPrefs() async {
    final prefs = await _getPrefs();
    final date = _nextBillingDate;
    if (date == null) {
      await prefs.remove(PrefKeys.purchaseNextBillingDate);
      return;
    }
    await prefs.setInt(
      PrefKeys.purchaseNextBillingDate,
      date.millisecondsSinceEpoch,
    );
  }

  // SharedPreferences 폴백 (RevenueCat 미연동 시)
  Future<void> _initFromPrefs() async {
    final prefs = await _getPrefs();
    await _loadSecurePremiumState();
    // SharedPrefs에 기존 값이 있으면 마이그레이션 후 삭제
    final legacyPremium = prefs.getBool(PrefKeys.purchaseIsPremium);
    final legacyBrand = prefs.getBool(PrefKeys.purchaseIsBrand);
    if (legacyPremium != null || legacyBrand != null) {
      _isPremium = legacyPremium ?? _isPremium;
      _isBrand = legacyBrand ?? _isBrand;
      await _saveSecurePremiumState(isPremium: _isPremium, isBrand: _isBrand);
      await prefs.remove(PrefKeys.purchaseIsPremium);
      await prefs.remove(PrefKeys.purchaseIsBrand);
    }

    final giftExpiry = prefs.getInt(PrefKeys.purchaseGiftExpiry) ?? 0;
    if (giftExpiry > 0) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(giftExpiry);
      if (DateTime.now().isAfter(expiry)) {
        if (!_isBrand) _isPremium = false;
        await prefs.remove(PrefKeys.purchaseGiftExpiry);
      }
    }

    _nextBillingDate = _loadDateFromPrefs(
      prefs,
      PrefKeys.purchaseNextBillingDate,
    );
    await _loadAndApplyScheduledPlanChange(prefs);
    notifyListeners();
  }

  DateTime? _loadDateFromPrefs(SharedPreferences prefs, String key) {
    final ts = prefs.getInt(key) ?? 0;
    if (ts <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> _loadAndApplyScheduledPlanChange(SharedPreferences prefs) async {
    // legacy migration: purchase_scheduledDowngrade -> free
    final legacyTs =
        prefs.getInt(PrefKeys.purchaseScheduledDowngradeLegacy) ?? 0;
    final savedTs = prefs.getInt(PrefKeys.purchaseScheduledPlanChangeDate) ?? 0;
    final savedTarget =
        prefs.getString(PrefKeys.purchaseScheduledPlanChangeTarget) ?? '';

    DateTime? date;
    ScheduledPlanTarget? target;

    if (savedTs > 0 && savedTarget.isNotEmpty) {
      date = DateTime.fromMillisecondsSinceEpoch(savedTs);
      target = savedTarget == 'brand'
          ? ScheduledPlanTarget.brand
          : ScheduledPlanTarget.free;
    } else if (legacyTs > 0) {
      date = DateTime.fromMillisecondsSinceEpoch(legacyTs);
      target = ScheduledPlanTarget.free;
      await prefs.setInt(PrefKeys.purchaseScheduledPlanChangeDate, legacyTs);
      await prefs.setString(PrefKeys.purchaseScheduledPlanChangeTarget, 'free');
      await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    }

    if (date == null || target == null) {
      _scheduledPlanChangeDate = null;
      _scheduledPlanTarget = null;
      return;
    }

    if (DateTime.now().isAfter(date)) {
      if (target == ScheduledPlanTarget.free) {
        _isPremium = false;
        _isBrand = false;
        await _saveSecurePremiumState(isPremium: false, isBrand: false);
      } else if (target == ScheduledPlanTarget.brand &&
          _isPremium &&
          !_isBrand) {
        _isPremium = true;
        _isBrand = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
      }
      _scheduledPlanChangeDate = null;
      _scheduledPlanTarget = null;
      await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
      await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
      return;
    }

    _scheduledPlanChangeDate = date;
    _scheduledPlanTarget = target;
  }

  // ── Premium 구매 ────────────────────────────────────────────────────────
  Future<bool> buyPremium() async {
    _setLoading(true);
    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 디버그 빌드 or RevenueCat 미연동 → 테스트 모드
    if (_isTestMode) {
      return await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isPremium = true;
        _isBrand = false;
        await _saveSecurePremiumState(isPremium: true, isBrand: false);
        await _markBillingCycleRefreshed(prefs);
      });
    }

    try {
      final pkg = await _resolvePackage(PurchaseProductIds.premiumMonthly);
      if (pkg == null) {
        _setError('상품 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final result = await Purchases.purchasePackage(pkg);
      _applyCustomerInfo(result);
      final prefs = await _getPrefs();
      await _persistBillingDateToPrefs();
      await _clearScheduledPlanChange(prefs);
      _setLoading(false);
      return _isPremium;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── Brand 구매 ──────────────────────────────────────────────────────────
  Future<bool> buyBrand() async {
    _setLoading(true);
    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    if (_isTestMode) {
      return await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isBrand = true;
        _isPremium = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
        await _markBillingCycleRefreshed(prefs);
      });
    }

    try {
      final pkg = await _resolvePackage(PurchaseProductIds.brandMonthly);
      if (pkg == null) {
        _setError('상품 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      final result = await Purchases.purchasePackage(pkg);
      _applyCustomerInfo(result);
      final prefs = await _getPrefs();
      await _persistBillingDateToPrefs();
      await _clearScheduledPlanChange(prefs);
      _setLoading(false);
      return _isBrand;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── 선물권 구매 ─────────────────────────────────────────────────────────
  // 실제 결제는 구매자가 처리하고, 코드를 받아서 수신자가 사용하는 형태
  // 테스트 모드에서는 구매자 자신의 계정에 영향 없이 코드만 생성
  Future<bool> buyGiftCard() async {
    _setLoading(true);
    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    if (_isTestMode) {
      // 테스트 모드: 구매자 프리미엄 활성화 없이 결제 흐름만 시뮬레이션
      await _fakePurchase(() async {});
      return true;
    }

    try {
      final pkg = await _resolvePackage(PurchaseProductIds.giftCard);
      if (pkg == null) {
        _setError('상품 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      // 선물권은 구매자 자신의 entitlement를 활성화하지 않음
      // RevenueCat에서 선물권 상품이 non-consumable 또는 소모성으로 설정되어 있어야 함
      await Purchases.purchasePackage(pkg);
      _setLoading(false);
      return true;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── 브랜드 추가 발송권 구매 (소모성 상품 1,000통 ₩15,000) ──────────────────
  Future<bool> buyBrandExtra(AppState appState) async {
    if (!appState.isBrandMember) return false;
    _setLoading(true);
    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return false;
    }

    // 디버그 빌드 or RevenueCat 미연동 → 테스트 모드
    if (_isTestMode) {
      return await _fakePurchase(() async {
        await appState.purchaseBrandExtraQuota();
      });
    }

    try {
      final pkg = await _resolvePackage(PurchaseProductIds.brandExtra1000);
      if (pkg == null) {
        _setError('상품 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      // 소모성 상품: purchaseProduct 사용
      await Purchases.purchasePackage(pkg);
      // 구매 성공 → 발송 쿼터 1,000통 추가
      await appState.purchaseBrandExtraQuota();
      _setLoading(false);
      return true;
    } on PlatformException catch (e) {
      _handlePlatformException(e);
      return false;
    }
  }

  // ── 구매 복원 ───────────────────────────────────────────────────────────
  Future<void> restorePurchases() async {
    _setLoading(true);
    if (!_isTestMode && !_isRcKeyConfiguredForCurrentPlatform) {
      _setError('결제 설정이 누락되었습니다. 앱 업데이트 후 다시 시도해주세요.');
      return;
    }

    if (_isTestMode) {
      final prefs = await _getPrefs();
      await _loadSecurePremiumState();
      _nextBillingDate = _loadDateFromPrefs(
        prefs,
        PrefKeys.purchaseNextBillingDate,
      );
      await _loadAndApplyScheduledPlanChange(prefs);
      _setLoading(false);
      return;
    }

    try {
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      await _persistBillingDateToPrefs();
      _setLoading(false);
    } on PlatformException catch (e) {
      _setError(e.message ?? '복원 중 오류가 발생했습니다.');
    }
  }

  // ── 구독 해지 안내 (실제 해지는 앱스토어/플레이스토어에서) ────────────────
  Future<void> cancelSubscription() async {
    // RevenueCat에서는 앱 내에서 직접 해지할 수 없음
    // 앱스토어/플레이스토어 구독 관리 페이지로 이동 안내 필요
    // UI에서 url_launcher로 아래 URL 열기:
    // iOS: https://apps.apple.com/account/subscriptions
    // AOS: https://play.google.com/store/account/subscriptions
    final prefs = await _getPrefs();
    await _clearScheduledPlanChange(prefs);
    notifyListeners();
  }

  // ── 플랜 다운그레이드 예약 (다음 결제일 = 약 30일 후부터 무료 전환) ─────────
  Future<void> scheduleDowngradeToFree() async {
    if (!_isPremium && !_isBrand) return;
    final prefs = await _getPrefs();
    final effectiveDate =
        _nextBillingDate ?? DateTime.now().add(const Duration(days: 30));

    _scheduledPlanChangeDate = effectiveDate;
    _scheduledPlanTarget = ScheduledPlanTarget.free;
    await prefs.setInt(
      PrefKeys.purchaseScheduledPlanChangeDate,
      effectiveDate.millisecondsSinceEpoch,
    );
    await prefs.setString(PrefKeys.purchaseScheduledPlanChangeTarget, 'free');
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    notifyListeners();
  }

  // ── Premium -> Brand 변경 예약 (다음 결제일부터 반영) ───────────────────────
  Future<void> scheduleUpgradeToBrand({String? userEmail}) async {
    if (!_isPremium || _isBrand) return;

    // 테스트 모드: 즉시 브랜드로 업그레이드 (발송 한도는 AppState에서 계정별로 제한)
    if (_isTestMode) {
      _setLoading(true);
      await _fakePurchase(() async {
        final prefs = await _getPrefs();
        _isBrand = true;
        _isPremium = true;
        await _saveSecurePremiumState(isPremium: true, isBrand: true);
        await _markBillingCycleRefreshed(prefs);
      });
      return;
    }

    final prefs = await _getPrefs();
    final effectiveDate =
        _nextBillingDate ?? DateTime.now().add(const Duration(days: 30));
    _scheduledPlanChangeDate = effectiveDate;
    _scheduledPlanTarget = ScheduledPlanTarget.brand;
    await prefs.setInt(
      PrefKeys.purchaseScheduledPlanChangeDate,
      effectiveDate.millisecondsSinceEpoch,
    );
    await prefs.setString(PrefKeys.purchaseScheduledPlanChangeTarget, 'brand');
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    notifyListeners();
  }

  // ── 테스트 이메일 자동 브랜드 설정 (DEBUG 전용) ──────────────────────────────
  Future<void> applyTestEmailOverride(String? email) async {
    if (!kDebugMode) return;
    if (email == null || email.isEmpty) return;
    if (email.toLowerCase() != DebugConstants.testBrandEmail) return;
    if (_isBrand) return; // 이미 브랜드면 skip
    final prefs = await _getPrefs();
    _isBrand = true;
    _isPremium = true;
    await _saveSecurePremiumState(isPremium: true, isBrand: true);
    await _markBillingCycleRefreshed(prefs);
    notifyListeners();
  }

  // ── 관리자 전용: 등급 직접 변경 (DEBUG 전용) ────────────────────────────────
  Future<void> debugSetTier({
    required bool isPremium,
    required bool isBrand,
  }) async {
    if (!kDebugMode) return;
    _isPremium = isPremium;
    _isBrand = isBrand;
    await _saveSecurePremiumState(isPremium: isPremium, isBrand: isBrand);
    notifyListeners();
  }

  // ── 다운그레이드 예약 취소 ──────────────────────────────────────────────────
  Future<void> cancelScheduledDowngrade() async {
    final prefs = await _getPrefs();
    _scheduledPlanChangeDate = null;
    _scheduledPlanTarget = null;
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
    notifyListeners();
  }

  // ── 디버그 / 테스트용 ────────────────────────────────────────────────────
  Future<void> debugSetPremium({
    bool premium = true,
    bool brand = false,
  }) async {
    if (!kDebugMode) return;
    final prefs = await _getPrefs();
    _isPremium = premium;
    _isBrand = brand;
    await _saveSecurePremiumState(isPremium: premium, isBrand: brand);
    await _markBillingCycleRefreshed(prefs);
    notifyListeners();
  }

  Future<void> _markBillingCycleRefreshed(SharedPreferences prefs) async {
    _nextBillingDate = DateTime.now().add(const Duration(days: 30));
    await prefs.setInt(
      PrefKeys.purchaseNextBillingDate,
      _nextBillingDate!.millisecondsSinceEpoch,
    );
    await _clearScheduledPlanChange(prefs);
  }

  Future<void> _clearScheduledPlanChange(SharedPreferences prefs) async {
    _scheduledPlanChangeDate = null;
    _scheduledPlanTarget = null;
    await prefs.remove(PrefKeys.purchaseScheduledDowngradeLegacy);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeDate);
    await prefs.remove(PrefKeys.purchaseScheduledPlanChangeTarget);
  }

  Future<void> syncUserIdentity({String? userId, String? email}) async {
    final normalizedUserId = _normalizeAppUserId(userId: userId, email: email);
    if (_isTestMode) {
      _activeAppUserId = normalizedUserId;
      return;
    }
    if (!_initialized) {
      _activeAppUserId = normalizedUserId;
      return;
    }

    try {
      if (normalizedUserId == null) {
        if (_activeAppUserId == null) return;
        final info = await Purchases.logOut();
        _activeAppUserId = null;
        _applyCustomerInfo(info);
        await _persistBillingDateToPrefs();
        final prefs = await _getPrefs();
        await _loadAndApplyScheduledPlanChange(prefs);
        notifyListeners();
        return;
      }

      if (_activeAppUserId == normalizedUserId) return;
      final result = await Purchases.logIn(normalizedUserId);
      _activeAppUserId = normalizedUserId;
      _applyCustomerInfo(result.customerInfo);
      await _persistBillingDateToPrefs();
      final prefs = await _getPrefs();
      await _loadAndApplyScheduledPlanChange(prefs);
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('[PurchaseService] 사용자 식별 동기화 실패: $e');
    }
  }

  String? _normalizeAppUserId({String? userId, String? email}) {
    final id = userId?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) return normalizedEmail;
    return null;
  }

  // ── Private 헬퍼 ────────────────────────────────────────────────────────

  /// Offering에서 productId에 맞는 Package 찾기
  Package? _findPackage(String productId) {
    if (_offerings == null) return null;
    final offering =
        _offerings!.getOffering(_RcOfferings.defaultOffering) ??
        _offerings!.current;
    if (offering == null) return null;
    for (final pkg in offering.availablePackages) {
      if (pkg.storeProduct.identifier == productId) return pkg;
    }
    return null;
  }

  Future<Package?> _resolvePackage(String productId) async {
    var pkg = _findPackage(productId);
    if (pkg != null) return pkg;
    if (_isTestMode) return null;
    try {
      _offerings = await Purchases.getOfferings();
      pkg = _findPackage(productId);
      return pkg;
    } on PlatformException catch (e) {
      debugPrint('[PurchaseService] 상품 재조회 실패 ($productId): $e');
      return null;
    }
  }

  /// 테스트 모드용 가짜 구매
  Future<bool> _fakePurchase(Future<void> Function() action) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await action();
    _setLoading(false);
    return true;
  }

  void _setLoading(bool v) {
    _loading = v;
    if (v) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _loading = false;
    _errorMessage = msg;
    notifyListeners();
  }

  /// purchases_flutter v8에서는 PurchasesErrorCode가 enum이라 직접 throw되지 않음.
  /// PlatformException.code 값이 PurchasesErrorCode 인덱스 문자열로 전달됨.
  /// - code "1" = purchaseCancelledError (사용자 취소) → 에러 없이 조용히 처리
  void _handlePlatformException(PlatformException e) {
    final codeInt = int.tryParse(e.code);
    // 사용자 취소 (PurchasesErrorCode.purchaseCancelledError.index == 1)
    if (codeInt == PurchasesErrorCode.purchaseCancelledError.index) {
      _setLoading(false);
      return;
    }
    // 그 외 에러: 코드 → 사람이 읽을 수 있는 메시지로 변환
    final rcCode =
        (codeInt != null && codeInt < PurchasesErrorCode.values.length)
        ? PurchasesErrorCode.values[codeInt]
        : null;
    _setError(
      rcCode != null
          ? _rcErrorMessage(rcCode)
          : (e.message ?? '구매 중 오류가 발생했습니다.'),
    );
  }

  String _rcErrorMessage(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return '네트워크 오류가 발생했습니다. 연결을 확인해주세요.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return '이 기기에서 구매가 허용되지 않습니다.';
      case PurchasesErrorCode.purchaseInvalidError:
        return '구매 정보가 올바르지 않습니다.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return '현재 구매할 수 없는 상품입니다.';
      case PurchasesErrorCode.storeProblemError:
        return 'App Store 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '구매 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }
}
