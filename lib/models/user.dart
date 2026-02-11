/// 当前登录用户（来自微信或本地）
class User {
  final String id;
  final String? nickname;
  final String? avatarUrl;

  const User({
    required this.id,
    this.nickname,
    this.avatarUrl,
  });

  String get displayName => nickname?.trim().isNotEmpty == true ? nickname! : '微信用户';

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? '',
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
