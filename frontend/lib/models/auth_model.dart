class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime? createdDate;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.createdDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdDate': createdDate?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
    );
  }
}

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiration;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiration,
    required this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiration': expiration?.toIso8601String(),
      'user': user.toJson(),
    };
  }

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiration: json['expiration'] != null
          ? DateTime.tryParse(json['expiration'] as String)
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : UserModel(
              id: json['userId']?.toString() ?? '',
              name: json['username'] as String? ?? '',
              email: json['email'] as String? ?? '',
            ),
    );
  }
}
