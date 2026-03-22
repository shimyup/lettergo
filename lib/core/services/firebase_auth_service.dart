import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import 'firestore_service.dart';

/// Firebase Auth REST API 서비스
class FirebaseAuthService {
  static String? _idToken;
  static String? _uid;
  static DateTime? _tokenExpiry;

  static String? get currentUid => _uid;
  static bool get isSignedIn => _idToken != null && _uid != null;

  // ── 이메일/비밀번호 로그인 ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    try {
      final res = await http.post(
        Uri.parse('${FirebaseConfig.authBase}:signInWithPassword?key=${FirebaseConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['idToken'] as String?;
        _uid = data['localId'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
        return data;
      }
    } catch (_) {}
    return null;
  }

  // ── 회원가입 ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return null;
    try {
      final res = await http.post(
        Uri.parse('${FirebaseConfig.authBase}:signUp?key=${FirebaseConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['idToken'] as String?;
        _uid = data['localId'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
        return data;
      }
    } catch (_) {}
    return null;
  }

  // ── 로그아웃 ─────────────────────────────────────────────────────────────────
  static void signOut() {
    _idToken = null;
    _uid = null;
    _tokenExpiry = null;
    FirestoreService.setIdToken('');
  }

  // ── 토큰 갱신 확인 ──────────────────────────────────────────────────────────
  static Future<void> refreshTokenIfNeeded({
    required String refreshToken,
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return;
    if (_tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) return;
    try {
      final res = await http.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=${FirebaseConfig.apiKey}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$refreshToken',
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _idToken = data['id_token'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(seconds: 3600));
        FirestoreService.setIdToken(_idToken ?? '');
      }
    } catch (_) {}
  }
}
