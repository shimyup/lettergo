/// Firebase 프로젝트 설정
///
/// 사용법:
/// 1. Firebase 콘솔 (https://console.firebase.google.com) 에서 새 프로젝트 생성
/// 2. iOS 앱 등록 (Bundle ID: com.globaldrift.messageInABottle)
/// 3. GoogleService-Info.plist 다운로드 → ios/Runner/ 에 추가
/// 4. 아래 값들을 Firebase 프로젝트 설정에서 복사 붙여넣기
/// 5. kFirebaseEnabled = true 로 변경
class FirebaseConfig {
  /// Firebase 사용 여부 (설정 완료 후 true로 변경)
  static const bool kFirebaseEnabled = false;

  /// Firebase 프로젝트 ID (예: letter-go-12345)
  static const String projectId = 'YOUR_PROJECT_ID';

  /// Firebase Web API Key (프로젝트 설정 → 일반 탭에서 확인)
  static const String apiKey = 'YOUR_WEB_API_KEY';

  /// Firebase Storage Bucket
  static const String storageBucket = 'YOUR_PROJECT_ID.appspot.com';

  // Firestore REST API 기본 URL
  static String get firestoreBase =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  // Firebase Auth REST API 기본 URL
  static String get authBase =>
      'https://identitytoolkit.googleapis.com/v1/accounts';

  // FCM API URL (v1)
  static String get fcmBase =>
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
}
