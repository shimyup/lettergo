class ActivityScore {
  int receivedCount;
  int replyCount;
  int sentCount;
  int likeCount; // 받은 좋아요 수
  int ratingTotal; // 별점 합계
  int ratingCount; // 별점 받은 횟수

  ActivityScore({
    this.receivedCount = 0,
    this.replyCount = 0,
    this.sentCount = 0,
    this.likeCount = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
  });

  double get avgRating => ratingCount > 0 ? ratingTotal / ratingCount : 0.0;

  // 랭킹 점수: 받은편지 + 좋아요 + 답장 + 별점
  double get towerHeight =>
      (receivedCount * 1.2) +
      (likeCount * 2.0) +
      (replyCount * 1.5) +
      (sentCount * 0.8) +
      (avgRating * 3.0);

  // 랭킹 스코어 (타워 높이와 동일하게 사용)
  double get rankScore => towerHeight;

  int get towerFloors => (towerHeight / 5).floor().clamp(1, 99);

  Map<String, dynamic> toJson() => {
    'receivedCount': receivedCount,
    'replyCount': replyCount,
    'sentCount': sentCount,
    'likeCount': likeCount,
    'ratingTotal': ratingTotal,
    'ratingCount': ratingCount,
  };

  static ActivityScore fromJson(Map<String, dynamic> j) => ActivityScore(
    receivedCount: j['receivedCount'] as int? ?? 0,
    replyCount: j['replyCount'] as int? ?? 0,
    sentCount: j['sentCount'] as int? ?? 0,
    likeCount: j['likeCount'] as int? ?? 0,
    ratingTotal: j['ratingTotal'] as int? ?? 0,
    ratingCount: j['ratingCount'] as int? ?? 0,
  );

  TowerTier get tier {
    final h = towerHeight;
    if (h < 10) return TowerTier.cottage;
    if (h < 30) return TowerTier.house;
    if (h < 60) return TowerTier.building;
    if (h < 120) return TowerTier.skyscraper;
    return TowerTier.landmark;
  }
}

enum TowerTier { cottage, house, building, skyscraper, landmark }

extension TowerTierExt on TowerTier {
  String get label {
    switch (this) {
      case TowerTier.cottage:
        return '오두막';
      case TowerTier.house:
        return '마을집';
      case TowerTier.building:
        return '빌딩';
      case TowerTier.skyscraper:
        return '마천루';
      case TowerTier.landmark:
        return '랜드마크';
    }
  }

  String get emoji {
    switch (this) {
      case TowerTier.cottage:
        return '🏠';
      case TowerTier.house:
        return '🏡';
      case TowerTier.building:
        return '🏢';
      case TowerTier.skyscraper:
        return '🏙️';
      case TowerTier.landmark:
        return '🗼';
    }
  }

  String get nextGoal {
    switch (this) {
      case TowerTier.cottage:
        return '편지 8개 더 받으면 마을집으로!';
      case TowerTier.house:
        return '답장 10개 더 보내면 빌딩으로!';
      case TowerTier.building:
        return '활동 점수 60점이면 마천루로!';
      case TowerTier.skyscraper:
        return '활동 점수 120점이면 랜드마크로!';
      case TowerTier.landmark:
        return '최고 등급 달성! 🎉';
    }
  }
}

class UserProfile {
  final String id;
  String username;
  String? profileImagePath;
  String country;
  String countryFlag;
  bool isPremium;
  String? email;
  String? socialLink;
  String languageCode; // e.g. 'ko', 'en', 'ja'
  final ActivityScore activityScore;
  final DateTime joinedAt;
  double latitude;
  double longitude;
  List<String> followingIds; // IDs of users I follow
  List<String> followerIds; // IDs of users who follow me
  bool isUsernamePublic; // 닉네임 공개 여부
  bool isSnsPublic; // SNS 링크 공개 여부

  UserProfile({
    required this.id,
    required this.username,
    this.profileImagePath,
    required this.country,
    required this.countryFlag,
    this.isPremium = false,
    this.email,
    this.socialLink,
    this.languageCode = 'ko',
    ActivityScore? activityScore,
    DateTime? joinedAt,
    this.latitude = 37.5665,
    this.longitude = 126.9780,
    List<String>? followingIds,
    List<String>? followerIds,
    this.isUsernamePublic = true,
    this.isSnsPublic = true,
  }) : activityScore = activityScore ?? ActivityScore(),
       joinedAt = joinedAt ?? DateTime.now(),
       followingIds = followingIds ?? [],
       followerIds = followerIds ?? [];
}
