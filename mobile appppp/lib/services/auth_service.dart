import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static const String _userKey = 'user';
  static const String _tokenKey = 'token';

  late SharedPreferences _prefs;
  User? _currentUser;
  String? _currentToken;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final userJson = _prefs.getString(_userKey);
    final token = _prefs.getString(_tokenKey);

    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('Error loading user: $e');
      }
    }
    _currentToken = token;
    if (token != null) {
      ApiService().setToken(token);
    }
  }

  User? get currentUser => _currentUser;
  String? get currentToken => _currentToken;
  bool get isAuthenticated => _currentUser != null && _currentToken != null;

  Future<void> saveUser(User user, String token) async {
    _currentUser = user;
    _currentToken = token;

    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await _prefs.setString(_tokenKey, token);
    ApiService().setToken(token);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentToken = null;

    await _prefs.remove(_userKey);
    await _prefs.remove(_tokenKey);
    ApiService().setToken('');
    notifyListeners();
  }

  void clear() {
    _currentUser = null;
    _currentToken = null;
  }
}
