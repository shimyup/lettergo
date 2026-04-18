import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

/// 이메일 발송 서비스 (SendGrid REST API)
///
/// 빌드 시 dart-define 으로 인증 정보를 주입:
///   --dart-define=SENDGRID_API_KEY=SG.xxxxxxxxxx
///   --dart-define=SENDGRID_FROM_EMAIL=noreply@yourdomain.com
class EmailService {
  EmailService._();

  static const String _sendgridUrl =
      'https://api.sendgrid.com/v3/mail/send';

  /// SendGrid 설정이 유효한지 확인
  static bool get isConfigured => FirebaseConfig.isSendgridEnabled;

  /// OTP 인증 이메일 발송.
  /// 성공 시 null 반환, 실패 시 에러 메시지 반환.
  static Future<String?> sendOtp({
    required String to,
    required String code,
    String langCode = 'en',
  }) async {
    if (!isConfigured) {
      // 개발 환경: SendGrid 미설정 시 성공 처리 (OTP는 디버그 화면에 표시)
      assert(() {
        debugPrint('[EmailService] SendGrid 미설정 — 이메일 발송 스킵 (디버그 코드 화면 참고)');
        return true;
      }());
      return null;
    }

    final subject = _otpSubject(langCode);
    final htmlBody = _otpHtmlBody(code, langCode);
    final textBody = _otpTextBody(code, langCode);

    try {
      final response = await http
          .post(
            Uri.parse(_sendgridUrl),
            headers: {
              'Authorization': 'Bearer ${FirebaseConfig.sendgridApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'personalizations': [
                {
                  'to': [{'email': to}],
                },
              ],
              'from': {'email': FirebaseConfig.sendgridFromEmail, 'name': 'Letter Go'},
              'subject': subject,
              'content': [
                {'type': 'text/plain', 'value': textBody},
                {'type': 'text/html', 'value': htmlBody},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 202) {
        assert(() {
          debugPrint('[EmailService] 이메일 발송 성공: $to');
          return true;
        }());
        return null; // 성공
      }

      // SendGrid 에러 처리
      String errorMsg = '이메일 발송에 실패했습니다.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = body['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          errorMsg = errors.first['message'] as String? ?? errorMsg;
        }
      } catch (_) {}
      assert(() {
        debugPrint('[EmailService] 발송 실패 (${response.statusCode}): $errorMsg');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[EmailService] 예외: $e');
        return true;
      }());
      return _networkErrorMsg(langCode);
    }
  }

  // ── 네트워크 에러 메시지 ────────────────────────────────────────────────────
  static String _networkErrorMsg(String langCode) {
    const msgs = <String, String>{
      'ko': '이메일 발송 실패: 네트워크 연결을 확인해주세요.',
      'en': 'Failed to send email. Please check your connection.',
      'ja': 'メール送信失敗: ネットワーク接続を確認してください。',
      'zh': '邮件发送失败：请检查网络连接。',
      'fr': 'Échec d\'envoi de l\'e-mail. Vérifiez votre connexion.',
      'de': 'E-Mail-Versand fehlgeschlagen. Netzwerkverbindung prüfen.',
      'es': 'Error al enviar el correo. Comprueba tu conexión.',
      'pt': 'Falha ao enviar e-mail. Verifique sua conexão.',
      'ru': 'Ошибка отправки email. Проверьте подключение к сети.',
    };
    return msgs[langCode] ?? msgs['en']!;
  }

  // ── 이메일 제목 ─────────────────────────────────────────────────────────────
  static String _otpSubject(String langCode) {
    const subjects = <String, String>{
      'ko': '[Letter Go] 이메일 인증 코드',
      'en': '[Letter Go] Email Verification Code',
      'ja': '[Letter Go] メール認証コード',
      'zh': '[Letter Go] 邮箱验证码',
      'fr': '[Letter Go] Code de vérification par e-mail',
      'de': '[Letter Go] E-Mail-Bestätigungscode',
      'es': '[Letter Go] Código de verificación de correo',
      'pt': '[Letter Go] Código de verificação de e-mail',
      'ru': '[Letter Go] Код подтверждения электронной почты',
    };
    return subjects[langCode] ?? subjects['en']!;
  }

  // ── 이메일 텍스트 본문 ────────────────────────────────────────────────────────
  static String _otpTextBody(String code, String langCode) {
    switch (langCode) {
      case 'ko':
        return 'Letter Go 인증 코드: $code\n이 코드는 10분 동안 유효합니다.\n본인이 요청하지 않은 경우 이 이메일을 무시하세요.';
      case 'ja':
        return 'Letter Go 認証コード: $code\nこのコードは10分間有効です。\nご自身が申請していない場合は、このメールを無視してください。';
      case 'zh':
        return 'Letter Go 验证码: $code\n此验证码10分钟内有效。\n如非本人操作，请忽略此邮件。';
      case 'fr':
        return 'Code de vérification Letter Go: $code\nCe code est valable 10 minutes.\nSi vous n\'avez pas fait cette demande, ignorez cet e-mail.';
      case 'de':
        return 'Letter Go Bestätigungscode: $code\nDieser Code ist 10 Minuten gültig.\nWenn Sie diese Anfrage nicht gestellt haben, ignorieren Sie diese E-Mail.';
      case 'es':
        return 'Código de verificación de Letter Go: $code\nEste código es válido por 10 minutos.\nSi no solicitaste esto, ignora este correo.';
      case 'pt':
        return 'Código de verificação Letter Go: $code\nEste código é válido por 10 minutos.\nSe não foi você, ignore este e-mail.';
      case 'ru':
        return 'Код подтверждения Letter Go: $code\nКод действителен 10 минут.\nЕсли вы не запрашивали это, проигнорируйте письмо.';
      default:
        return 'Letter Go verification code: $code\nThis code is valid for 10 minutes.\nIf you did not request this, please ignore this email.';
    }
  }

  // ── 이메일 HTML 본문 ─────────────────────────────────────────────────────────
  static String _otpHtmlBody(String code, String langCode) {
    final subject = _otpSubject(langCode);
    final textContent = _otpTextBody(code, langCode)
        .replaceAll('\n', '<br>');
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: sans-serif; background: #070B14; color: #E8E8E0; margin: 0; padding: 20px; }
    .card { background: #111827; border-radius: 16px; padding: 32px; max-width: 480px; margin: 0 auto; }
    .logo { text-align: center; font-size: 48px; margin-bottom: 8px; }
    .title { text-align: center; font-size: 22px; font-weight: bold; color: #F0C35A; margin-bottom: 24px; }
    .code-box { background: #1E293B; border: 2px solid #F0C35A; border-radius: 12px; padding: 20px;
                text-align: center; font-size: 36px; font-weight: bold; letter-spacing: 8px;
                color: #F0C35A; margin: 24px 0; }
    .note { font-size: 13px; color: #9CA3AF; text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🍾</div>
    <div class="title">Letter Go</div>
    <p style="text-align:center; margin-bottom: 8px;">$subject</p>
    <div class="code-box">$code</div>
    <p class="note">$textContent</p>
  </div>
</body>
</html>
''';
  }
}
