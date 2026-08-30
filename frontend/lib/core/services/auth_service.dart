import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_model.dart';

class AuthService {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUser = 'auth_user_json';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  UserModel? _cachedUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedAccessToken = prefs.getString(_keyAccessToken);
    _cachedRefreshToken = prefs.getString(_keyRefreshToken);
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      try {
        _cachedUser = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  String? get accessToken => _cachedAccessToken;
  String? get refreshToken => _cachedRefreshToken;
  UserModel? get currentUser => _cachedUser;
  bool get isAuthenticated => _cachedAccessToken != null && _cachedAccessToken!.isNotEmpty;

  Future<void> saveAuth(AuthResponseModel auth) async {
    _cachedAccessToken = auth.accessToken;
    _cachedRefreshToken = auth.refreshToken;
    _cachedUser = auth.user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, auth.accessToken);
    await prefs.setString(_keyRefreshToken, auth.refreshToken);
    await prefs.setString(_keyUser, jsonEncode(auth.user.toJson()));
  }

  Future<void> clearAuth() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);
  }
}
