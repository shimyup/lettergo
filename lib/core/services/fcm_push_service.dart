import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

/// FCM HTTP API를 통한 푸시 알림 서비스
/// Firebase Admin SDK 없이 HTTP API로 푸시 전송
class FcmPushService {
  // ── 특정 디바이스에 알림 전송 ─────────────────────────────────────────────
  static Future<bool> sendToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required String serverKey, // Firebase 서버 키 (레거시 API)
  }) async {
    if (!FirebaseConfig.kFirebaseEnabled) return false;
    try {
      final res = await http
          .post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$serverKey',
            },
            body: jsonEncode({
              'to': deviceToken,
              'notification': {
                'title': title,
                'body': body,
                'sound': 'default',
              },
              'data': data ?? {},
              'priority': 'high',
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e, st) {
      debugPrint('[FCMPush] 에러: $e\n$st');
    }
    return false;
  }

  // ── 편지 도착 알림 ───────────────────────────────────────────────────────────
  static Future<void> sendLetterArrivedNotification({
    required String recipientToken,
    required String senderCountry,
    required String senderFlag,
    required String serverKey,
  }) async {
    await sendToDevice(
      deviceToken: recipientToken,
      title: '📩 새 편지가 도착했어요!',
      body: '$senderFlag $senderCountry에서 보낸 편지가 도착했습니다',
      data: {'type': 'letter_arrived'},
      serverKey: serverKey,
    );
  }

  // ── DM 알림 ─────────────────────────────────────────────────────────────────
  static Future<void> sendDMNotification({
    required String recipientToken,
    required String senderName,
    required String message,
    required String serverKey,
  }) async {
    await sendToDevice(
      deviceToken: recipientToken,
      title: '💬 $senderName님의 DM',
      body: message.length > 40 ? '${message.substring(0, 40)}...' : message,
      data: {'type': 'dm_arrived'},
      serverKey: serverKey,
    );
  }
}
