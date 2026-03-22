import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserId = 'userId';
  static const _keyUsername = 'username';
  static const _keyEmail = 'email';
  static const _keyCountry = 'country';
  static const _keyCountryFlag = 'countryFlag';
  static const _keySocialLink = 'socialLink';
  static const _keyPassword = 'password';
  static const _keyTempPasswordHash = 'tempPasswordHash';
  static const _keyTempPasswordExpiresAt = 'tempPasswordExpiresAt';
  static const _keyMustChangePassword = 'mustChangePassword';
  static const _keySecureMigrated = 'auth_secure_migrated_v1';
  static const _tempPasswordTtl = Duration(minutes: 15);

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const List<String> _authKeys = [
    _keyIsLoggedIn,
    _keyUserId,
    _keyUsername,
    _keyEmail,
    _keyCountry,
    _keyCountryFlag,
    _keySocialLink,
    _keyPassword,
  ];

  /// 비밀번호를 SHA-256 해시로 변환 (소금값: 앱 고유 prefix)
  static String _hashPassword(String raw) {
    const salt = 'globaldrift_v1_';
    final bytes = utf8.encode(salt + raw);
    return sha256.convert(bytes).toString(); // 64자 hex 문자열
  }

  /// 저장된 값이 이미 해시인지 확인 (64자 hex = SHA-256)
  static bool _isHashed(String value) =>
      value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);

  static String _generateTempPassword({int length = 12}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    final rnd = Random.secure();
    final out = StringBuffer();
    for (var i = 0; i < length; i++) {
      out.write(chars[rnd.nextInt(chars.length)]);
    }
    return out.toString();
  }

  static Future<void> _writeSecure(String key, String value) async {
    await _secure.write(key: key, value: value);
  }

  static Future<void> _deleteSecure(String key) async {
    await _secure.delete(key: key);
  }

  static Future<String?> _readSecure(String key) async {
    return _secure.read(key: key);
  }

  static Future<void> _migrateLegacyAuthDataIfNeeded(
    SharedPreferences prefs,
  ) async {
    final migrated = prefs.getBool(_keySecureMigrated) ?? false;
    if (migrated) return;

    for (final key in _authKeys) {
      final legacy = key == _keyIsLoggedIn
          ? (prefs.getBool(key)?.toString())
          : prefs.getString(key);
      if (legacy == null) continue;

      final secureExisting = await _readSecure(key);
      if (secureExisting == null) {
        await _writeSecure(key, legacy);
      }
      await prefs.remove(key);
    }

    await prefs.setBool(_keySecureMigrated, true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);
    return (await _readSecure(_keyIsLoggedIn)) == 'true';
  }

  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    if ((await _readSecure(_keyIsLoggedIn)) != 'true') return null;
    return {
      'id': (await _readSecure(_keyUserId)) ?? '',
      'username': (await _readSecure(_keyUsername)) ?? '',
      'email': (await _readSecure(_keyEmail)) ?? '',
      'country': (await _readSecure(_keyCountry)) ?? '대한민국',
      'countryFlag': (await _readSecure(_keyCountryFlag)) ?? '🇰🇷',
      'socialLink': (await _readSecure(_keySocialLink)) ?? '',
    };
  }

  // ── 유효성 정규식 ──────────────────────────────────────────────────────────
  /// 아이디: 영문으로 시작, 영문+숫자+_로 2~20자
  static final _usernameRe = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{1,19}$');
  /// 비밀번호: 영문+숫자 포함 6~12자 (특수문자 허용)
  static final _passwordRe = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9]).{6,12}$');
  static final _emailRe =
      RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+(\.[a-zA-Z\d\-]+)*\.[a-zA-Z]{2,}$');

  /// 아이디 유효성 검사 (UI 실시간 체크용)
  static String? validateUsername(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.length < 2) return '2자 이상 입력해주세요';
    if (v.length > 20) return '20자 이하로 입력해주세요';
    if (!_usernameRe.hasMatch(v)) return '영문으로 시작, 영문·숫자·_ 만 사용 가능';
    return null; // 유효
  }

  /// 비밀번호 유효성 검사 (UI 실시간 체크용)
  static String? validatePassword(String value) {
    if (value.isEmpty) return null;
    if (value.length < 6) return '6자 이상 입력해주세요';
    if (value.length > 12) return '12자 이하로 입력해주세요';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return '영문을 포함해야 합니다';
    if (!RegExp(r'[0-9]').hasMatch(value)) return '숫자를 포함해야 합니다';
    return null; // 유효
  }

  /// 이메일 중복 여부 확인 (기기 내 저장된 계정 한정)
  static Future<bool> isEmailTaken(String email) async {
    final saved = await _readSecure(_keyEmail);
    return saved != null &&
        saved.toLowerCase() == email.trim().toLowerCase();
  }

  /// 아이디 중복 여부 확인 (기기 내 저장된 계정 한정)
  static Future<bool> isUsernameTaken(String username) async {
    final saved = await _readSecure(_keyUsername);
    return saved != null &&
        saved.toLowerCase() == username.trim().toLowerCase();
  }

  /// 회원가입 - nickname + password
  static Future<String?> signUp({
    required String username,
    required String password,
    required String country,
    required String countryFlag,
    String? email,
    String? socialLink,
  }) async {
    // ── 형식 검사 ──
    final usernameErr = validateUsername(username);
    if (usernameErr != null) return '아이디: $usernameErr';
    final passwordErr = validatePassword(password);
    if (passwordErr != null) return '비밀번호: $passwordErr';
    if (email == null || email.trim().isEmpty) return '이메일을 입력해주세요.';
    if (!_emailRe.hasMatch(email.trim())) return '올바른 이메일 형식이 아닙니다.';

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    // ── 중복 체크 ──
    final existingUsername = await _readSecure(_keyUsername);
    if (existingUsername != null &&
        existingUsername.toLowerCase() == username.trim().toLowerCase()) {
      return '이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요.';
    }
    final existingEmail = await _readSecure(_keyEmail);
    if (existingEmail != null &&
        existingEmail.toLowerCase() == email.trim().toLowerCase()) {
      return '이미 가입된 이메일입니다. 다른 이메일을 사용하거나 로그인해주세요.';
    }

    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await _writeSecure(_keyIsLoggedIn, 'true');
    await _writeSecure(_keyUserId, userId);
    await _writeSecure(_keyUsername, username.trim());
    if (email != null && email.isNotEmpty) {
      await _writeSecure(_keyEmail, email.trim());
    } else {
      await _deleteSecure(_keyEmail);
    }
    await _writeSecure(_keyPassword, _hashPassword(password)); // SHA-256 저장
    await _writeSecure(_keyCountry, country);
    await _writeSecure(_keyCountryFlag, countryFlag);
    if (socialLink != null && socialLink.isNotEmpty) {
      await _writeSecure(_keySocialLink, socialLink.trim());
    } else {
      await _deleteSecure(_keySocialLink);
    }
    return null; // null = 성공
  }

  /// 로그인 - nickname + password
  static Future<String?> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty) return '닉네임을 입력해주세요.';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';

    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    final savedUsername = await _readSecure(_keyUsername);
    final savedPassword = await _readSecure(_keyPassword);

    if (savedUsername == null) return '등록된 계정이 없습니다. 회원가입을 먼저 해주세요.';
    if (savedUsername != username.trim()) return '닉네임 또는 비밀번호가 올바르지 않습니다.';

    var primaryPasswordMatched = false;

    // 기존 평문 비밀번호 자동 마이그레이션: 로그인 성공 시 해시로 재저장
    if (savedPassword != null && !_isHashed(savedPassword)) {
      if (savedPassword == password) {
        await _writeSecure(_keyPassword, _hashPassword(password)); // 마이그레이션
        primaryPasswordMatched = true;
      }
    } else {
      if (savedPassword != _hashPassword(password)) {
        primaryPasswordMatched = false;
      } else {
        primaryPasswordMatched = true;
      }
    }

    if (!primaryPasswordMatched) {
      final tempHash = await _readSecure(_keyTempPasswordHash);
      final tempExpiresAtRaw = await _readSecure(_keyTempPasswordExpiresAt);
      final tempExpiresAt = int.tryParse(tempExpiresAtRaw ?? '');
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (tempHash != null &&
          tempExpiresAt != null &&
          nowMs <= tempExpiresAt &&
          tempHash == _hashPassword(password)) {
        await _writeSecure(_keyMustChangePassword, 'true');
        await _writeSecure(_keyIsLoggedIn, 'true');
        return null;
      }

      // 만료된 임시 비밀번호는 즉시 폐기
      if (tempHash != null && tempExpiresAt != null && nowMs > tempExpiresAt) {
        await _deleteSecure(_keyTempPasswordHash);
        await _deleteSecure(_keyTempPasswordExpiresAt);
      }

      return '닉네임 또는 비밀번호가 올바르지 않습니다.';
    }

    await _deleteSecure(_keyTempPasswordHash);
    await _deleteSecure(_keyTempPasswordExpiresAt);
    await _writeSecure(_keyMustChangePassword, 'false');
    await _writeSecure(_keyIsLoggedIn, 'true');
    return null; // null = 성공
  }

  /// 로그아웃
  static Future<void> logout() async {
    await _writeSecure(_keyIsLoggedIn, 'false');
  }

  /// 프로필 업데이트
  static Future<void> updateProfile({
    String? username,
    String? country,
    String? countryFlag,
    String? socialLink,
  }) async {
    if (username != null && username.isNotEmpty) {
      await _writeSecure(_keyUsername, username.trim());
    }
    if (country != null) await _writeSecure(_keyCountry, country);
    if (countryFlag != null) await _writeSecure(_keyCountryFlag, countryFlag);
    if (socialLink != null) {
      await _writeSecure(_keySocialLink, socialLink.trim());
    }
  }

  // Find username by email
  static Future<Map<String, dynamic>> findId({required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    final storedEmail = (await _readSecure(_keyEmail)) ?? '';
    if (storedEmail.toLowerCase() == email.toLowerCase()) {
      final username = (await _readSecure(_keyUsername)) ?? '';
      return {'success': true, 'username': username};
    }
    return {'success': false, 'error': '해당 이메일로 등록된 계정을 찾을 수 없습니다.'};
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAuthDataIfNeeded(prefs);

    final inputUsername = username.trim();
    final inputEmail = email.trim();
    if (inputUsername.isEmpty || inputEmail.isEmpty) {
      return {'success': false, 'error': '닉네임과 가입 이메일을 모두 입력해주세요.'};
    }

    final storedUsername = (await _readSecure(_keyUsername)) ?? '';
    final storedEmail = (await _readSecure(_keyEmail)) ?? '';
    if (storedUsername == inputUsername &&
        storedEmail.isNotEmpty &&
        storedEmail.toLowerCase() == inputEmail.toLowerCase()) {
      final tempPassword = _generateTempPassword();
      final expiresAt = DateTime.now()
          .add(_tempPasswordTtl)
          .millisecondsSinceEpoch;
      await _writeSecure(_keyTempPasswordHash, _hashPassword(tempPassword));
      await _writeSecure(_keyTempPasswordExpiresAt, expiresAt.toString());
      await _writeSecure(_keyMustChangePassword, 'true');
      return {
        'success': true,
        'tempPassword': tempPassword,
        'expiresInMinutes': _tempPasswordTtl.inMinutes,
      };
    }
    return {'success': false, 'error': '닉네임 또는 이메일이 일치하지 않습니다.'};
  }

  // Change password (requires old password verified by caller)
  static Future<void> updatePassword(String newPassword) async {
    await _writeSecure(_keyPassword, _hashPassword(newPassword));
    await _deleteSecure(_keyTempPasswordHash);
    await _deleteSecure(_keyTempPasswordExpiresAt);
    await _writeSecure(_keyMustChangePassword, 'false');
  }

  // Delete account
  static Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secure.deleteAll();
  }

  // Check onboarding completion (v2 = with country selection)
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_v2_complete') ?? false;
  }

  // Mark onboarding complete
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_v2_complete', true);
  }

  // Save onboarding country selection
  static Future<void> saveOnboardingCountry({
    required String country,
    required String countryFlag,
  }) async {
    await _writeSecure(_keyCountry, country);
    await _writeSecure(_keyCountryFlag, countryFlag);
  }

  static Future<Map<String, String>> getOnboardingCountry() async {
    return {
      'country': (await _readSecure(_keyCountry)) ?? '대한민국',
      'countryFlag': (await _readSecure(_keyCountryFlag)) ?? '🇰🇷',
    };
  }
}
