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
  static const String _resendUrl = 'https://api.resend.com/emails';

  /// 이메일 발송 프로바이더가 하나라도 설정되어 있는지.
  /// Resend 우선, SendGrid 폴백.
  static bool get isConfigured => FirebaseConfig.isEmailProviderEnabled;

  /// OTP 인증 이메일 발송.
  /// 성공 시 null 반환, 실패 시 에러 메시지 반환.
  ///
  /// 프로바이더 선택 우선순위:
  ///   1) Resend  (RESEND_API_KEY + RESEND_FROM_EMAIL)
  ///   2) SendGrid (SENDGRID_API_KEY + SENDGRID_FROM_EMAIL)
  ///   3) 미설정 — null 반환 (auth_screen 에서 on-screen OTP fallback)
  static Future<String?> sendOtp({
    required String to,
    required String code,
    String langCode = 'en',
  }) async {
    if (!isConfigured) {
      // 개발/베타 환경: 이메일 프로바이더 미설정 시 성공 처리
      // (OTP 는 auth_screen 의 on-screen fallback 으로 표시됨)
      assert(() {
        debugPrint('[EmailService] 이메일 프로바이더 미설정 — 발송 스킵 (화면 노출 fallback)');
        return true;
      }());
      return null;
    }

    final subject = _otpSubject(langCode);
    final htmlBody = _otpHtmlBody(code, langCode);
    final textBody = _otpTextBody(code, langCode);

    // Resend 우선 시도
    if (FirebaseConfig.isResendEnabled) {
      final err = await _sendViaResend(
        to: to,
        subject: subject,
        htmlBody: htmlBody,
        textBody: textBody,
        langCode: langCode,
      );
      if (err == null) return null; // 성공
      // Resend 가 실패했고 SendGrid 가 설정되어 있으면 폴백
      if (!FirebaseConfig.isSendgridEnabled) return err;
      assert(() {
        debugPrint('[EmailService] Resend 실패 → SendGrid 폴백');
        return true;
      }());
    }

    // SendGrid 경로
    return _sendViaSendgrid(
      to: to,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
      langCode: langCode,
    );
  }

  /// Resend API 로 발송.
  static Future<String?> _sendViaResend({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
    required String langCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_resendUrl),
            headers: {
              'Authorization': 'Bearer ${FirebaseConfig.resendApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': 'Thiscount <${FirebaseConfig.resendFromEmail}>',
              'to': [to],
              'subject': subject,
              'html': htmlBody,
              'text': textBody,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        assert(() {
          debugPrint('[EmailService] Resend 발송 성공: $to');
          return true;
        }());
        return null; // 성공
      }

      // Resend 에러 파싱
      String errorMsg = '이메일 발송에 실패했습니다.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = (body['message'] as String?) ?? errorMsg;
      } catch (_) {}
      assert(() {
        debugPrint('[EmailService] Resend 실패 (${response.statusCode}): $errorMsg');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[EmailService] Resend 예외: $e');
        return true;
      }());
      return _networkErrorMsg(langCode);
    }
  }

  /// SendGrid API 로 발송 (폴백).
  static Future<String?> _sendViaSendgrid({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
    required String langCode,
  }) async {
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
              'from': {'email': FirebaseConfig.sendgridFromEmail, 'name': 'Thiscount'},
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
          debugPrint('[EmailService] SendGrid 발송 성공: $to');
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
        debugPrint('[EmailService] SendGrid 실패 (${response.statusCode}): $errorMsg');
        return true;
      }());
      return _networkErrorMsg(langCode);
    } on SocketException {
      return _networkErrorMsg(langCode);
    } on TimeoutException {
      return _networkErrorMsg(langCode);
    } catch (e) {
      assert(() {
        debugPrint('[EmailService] SendGrid 예외: $e');
        return true;
      }());
      return _networkErrorMsg(langCode);
    }
  }

  // Build 297 (P0 audit): 비밀번호 재설정 시 발급된 임시 비밀번호를 이메일로
  // 전송. 이전엔 release 빌드에서 화면 노출 차단(authTempPasswordHidden)만
  // 하고 실제 전송 채널이 없어 사용자가 영구 잠겼음.
  static Future<String?> sendTempPassword({
    required String to,
    required String tempPassword,
    required int expiresInMinutes,
    String langCode = 'en',
  }) async {
    if (!isConfigured) {
      assert(() {
        debugPrint('[EmailService] 임시 비밀번호 발송 — 프로바이더 미설정');
        return true;
      }());
      return null;
    }

    final subject = _tempPasswordSubject(langCode);
    final textBody = _tempPasswordTextBody(tempPassword, expiresInMinutes, langCode);
    final htmlBody = _tempPasswordHtmlBody(tempPassword, expiresInMinutes, langCode);

    if (FirebaseConfig.isResendEnabled) {
      final err = await _sendViaResend(
        to: to,
        subject: subject,
        htmlBody: htmlBody,
        textBody: textBody,
        langCode: langCode,
      );
      if (err == null) return null;
      if (!FirebaseConfig.isSendgridEnabled) return err;
    }

    return _sendViaSendgrid(
      to: to,
      subject: subject,
      htmlBody: htmlBody,
      textBody: textBody,
      langCode: langCode,
    );
  }

  static String _tempPasswordSubject(String langCode) {
    // Build 299 (MED audit): tr/ar/it/hi/th 5언어 추가 (이전엔 영어 fallback).
    const m = <String, String>{
      'ko': '[Thiscount] 임시 비밀번호 발급',
      'en': '[Thiscount] Temporary Password',
      'ja': '[Thiscount] 仮パスワードのお知らせ',
      'zh': '[Thiscount] 临时密码已发放',
      'fr': '[Thiscount] Mot de passe temporaire',
      'de': '[Thiscount] Vorübergehendes Passwort',
      'es': '[Thiscount] Contraseña temporal',
      'pt': '[Thiscount] Senha temporária',
      'ru': '[Thiscount] Временный пароль',
      'tr': '[Thiscount] Geçici şifre',
      'ar': '[Thiscount] كلمة المرور المؤقتة',
      'it': '[Thiscount] Password temporanea',
      'hi': '[Thiscount] अस्थायी पासवर्ड',
      'th': '[Thiscount] รหัสผ่านชั่วคราว',
    };
    return m[langCode] ?? m['en']!;
  }

  static String _tempPasswordTextBody(String pw, int minutes, String langCode) {
    switch (langCode) {
      case 'ko':
        return '임시 비밀번호: $pw\n유효 시간: $minutes분\n로그인 후 반드시 새 비밀번호로 변경해주세요.\n본인이 요청하지 않았다면 즉시 비밀번호를 변경해주세요.';
      case 'ja':
        return '仮パスワード: $pw\n有効期間: $minutes分\nログイン後、必ず新しいパスワードに変更してください。';
      case 'zh':
        return '临时密码: $pw\n有效期: $minutes 分钟\n登录后请立即修改为新密码。';
      case 'fr':
        return 'Mot de passe temporaire: $pw\nValidité: $minutes minutes\nChangez votre mot de passe après vous être connecté.';
      case 'de':
        return 'Vorübergehendes Passwort: $pw\nGültig für $minutes Minuten\nBitte ändern Sie es nach dem Login.';
      case 'es':
        return 'Contraseña temporal: $pw\nVálida por $minutes minutos\nCámbiala tras iniciar sesión.';
      case 'pt':
        return 'Senha temporária: $pw\nVálida por $minutes minutos\nAltere após o login.';
      case 'ru':
        return 'Временный пароль: $pw\nДействителен $minutes мин.\nИзмените после входа.';
      case 'tr':
        return 'Geçici şifre: $pw\nGeçerlilik: $minutes dakika\nGiriş yaptıktan sonra şifrenizi değiştirin.';
      case 'ar':
        return 'كلمة المرور المؤقتة: $pw\nصالحة لمدة $minutes دقيقة\nيرجى تغييرها بعد تسجيل الدخول.';
      case 'it':
        return 'Password temporanea: $pw\nValida per $minutes minuti\nCambiala dopo il login.';
      case 'hi':
        return 'अस्थायी पासवर्ड: $pw\n$minutes मिनट के लिए मान्य\nलॉगिन के बाद पासवर्ड बदलें।';
      case 'th':
        return 'รหัสผ่านชั่วคราว: $pw\nใช้ได้ $minutes นาที\nเปลี่ยนรหัสผ่านหลังจากเข้าสู่ระบบ';
      default:
        return 'Temporary password: $pw\nValid for $minutes minutes\nPlease change it after logging in.';
    }
  }

  static String _tempPasswordHtmlBody(String pw, int minutes, String langCode) {
    final subject = _tempPasswordSubject(langCode);
    final note = _tempPasswordTextBody(pw, minutes, langCode).replaceAll('\n', '<br>');
    return '''
<!DOCTYPE html>
<html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:24px;background:#F5F6FA;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#111827;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;margin:0 auto;background:#FFFFFF;border-radius:16px;border:1px solid #E5E7EB;">
    <tr><td style="padding:32px 32px 0 32px;text-align:center;">
      <div style="font-size:24px;font-weight:800;color:#111827;letter-spacing:0.5px;">Thiscount</div>
      <div style="font-size:13px;color:#6B7280;margin-top:6px;">$subject</div>
    </td></tr>
    <tr><td style="padding:24px 32px 8px 32px;text-align:center;">
      <div style="font-size:13px;color:#6B7280;margin-bottom:8px;">temporary password</div>
      <div style="display:inline-block;padding:14px 22px;font-size:24px;font-weight:800;letter-spacing:2px;background:#F3F4F6;border-radius:12px;color:#111827;">$pw</div>
    </td></tr>
    <tr><td style="padding:8px 32px 32px 32px;text-align:center;font-size:13px;color:#6B7280;line-height:1.6;">$note</td></tr>
  </table>
</body></html>''';
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
      'ko': '[Thiscount] 이메일 인증 코드',
      'en': '[Thiscount] Email Verification Code',
      'ja': '[Thiscount] メール認証コード',
      'zh': '[Thiscount] 邮箱验证码',
      'fr': '[Thiscount] Code de vérification par e-mail',
      'de': '[Thiscount] E-Mail-Bestätigungscode',
      'es': '[Thiscount] Código de verificación de correo',
      'pt': '[Thiscount] Código de verificação de e-mail',
      'ru': '[Thiscount] Код подтверждения электронной почты',
    };
    return subjects[langCode] ?? subjects['en']!;
  }

  // ── 이메일 텍스트 본문 ────────────────────────────────────────────────────────
  static String _otpTextBody(String code, String langCode) {
    switch (langCode) {
      case 'ko':
        return 'Thiscount 인증 코드: $code\n이 코드는 10분 동안 유효합니다.\n본인이 요청하지 않은 경우 이 이메일을 무시하세요.';
      case 'ja':
        return 'Thiscount 認証コード: $code\nこのコードは10分間有効です。\nご自身が申請していない場合は、このメールを無視してください。';
      case 'zh':
        return 'Thiscount 验证码: $code\n此验证码10分钟内有效。\n如非本人操作，请忽略此邮件。';
      case 'fr':
        return 'Code de vérification Thiscount: $code\nCe code est valable 10 minutes.\nSi vous n\'avez pas fait cette demande, ignorez cet e-mail.';
      case 'de':
        return 'Thiscount Bestätigungscode: $code\nDieser Code ist 10 Minuten gültig.\nWenn Sie diese Anfrage nicht gestellt haben, ignorieren Sie diese E-Mail.';
      case 'es':
        return 'Código de verificación de Thiscount: $code\nEste código es válido por 10 minutos.\nSi no solicitaste esto, ignora este correo.';
      case 'pt':
        return 'Código de verificação Thiscount: $code\nEste código é válido por 10 minutos.\nSe não foi você, ignore este e-mail.';
      case 'ru':
        return 'Код подтверждения Thiscount: $code\nКод действителен 10 минут.\nЕсли вы не запрашивали это, проигнорируйте письмо.';
      default:
        return 'Thiscount verification code: $code\nThis code is valid for 10 minutes.\nIf you did not request this, please ignore this email.';
    }
  }

  // ── 이메일 HTML 본문 ─────────────────────────────────────────────────────────
  // 이메일 클라이언트 호환성을 위한 인라인 스타일 + 테이블 레이아웃.
  // Gmail/Outlook 등은 <style> 블록을 strip 하므로 모든 시각 강조를 inline 으로
  // 배치. 코드 자체를 본문 최상단에 plain-text 로 한 번 더 노출해 다크모드/
  // 이미지차단 환경에서도 즉시 보이도록 함.
  static String _otpHtmlBody(String code, String langCode) {
    final subject = _otpSubject(langCode);
    final textBody = _otpTextBody(code, langCode);
    final note = textBody.replaceAll('\n', '<br>');
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:24px;background:#F5F6FA;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#111827;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;margin:0 auto;background:#FFFFFF;border-radius:16px;border:1px solid #E5E7EB;">
    <tr><td style="padding:32px 32px 0 32px;text-align:center;">
      <div style="font-size:24px;font-weight:800;color:#111827;letter-spacing:0.5px;">Thiscount</div>
      <div style="font-size:13px;color:#6B7280;margin-top:6px;">$subject</div>
    </td></tr>
    <tr><td style="padding:24px 32px 8px 32px;text-align:center;">
      <div style="font-size:13px;color:#6B7280;margin-bottom:8px;">verification code</div>
      <div style="font-size:36px;line-height:1.2;font-weight:800;letter-spacing:10px;color:#111827;background:#F3F4F6;border:2px solid #111827;border-radius:12px;padding:18px 12px;display:inline-block;min-width:220px;">$code</div>
    </td></tr>
    <tr><td style="padding:8px 32px 16px 32px;text-align:center;">
      <div style="font-size:14px;color:#374151;line-height:1.5;">$note</div>
    </td></tr>
    <tr><td style="padding:0 32px 24px 32px;text-align:center;">
      <div style="font-size:11px;color:#9CA3AF;line-height:1.5;border-top:1px solid #E5E7EB;padding-top:16px;">
        If you cannot see the code above, your code is: <strong style="color:#111827;font-size:14px;letter-spacing:2px;">$code</strong>
      </div>
    </td></tr>
  </table>
</body>
</html>
''';
  }
}
