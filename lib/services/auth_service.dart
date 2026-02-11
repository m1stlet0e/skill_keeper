import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluwx/fluwx.dart';

import '../models/user.dart';

/// 微信开放平台配置
const String _kWeChatAppId = 'wxb3dd79ab2bacbc49';
// iOS 必填：与微信开放平台、Xcode Associated Domains 一致，需 HTTPS，例如 https://你的域名/skillkeeper/
const String _kWeChatUniversalLink = 'https://your-domain.com/';

const String _kKeyLoggedIn = 'auth_logged_in';
const String _kKeyUserId = 'auth_user_id';
const String _kKeyNickname = 'auth_nickname';
const String _kKeyAvatarUrl = 'auth_avatar_url';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  User? _user;
  bool _isWeChatRegistered = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  bool get isWeChatRegistered => _isWeChatRegistered;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final Fluwx _fluwx = Fluwx();
  FluwxCancelable? _authCancelable;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    await load();
    _listenWeChatResponse();
    await _registerWeChat();
  }

  void _listenWeChatResponse() {
    _authCancelable = _fluwx.addSubscriber((WeChatResponse res) {
      if (res is WeChatAuthResponse) {
        if (res.isSuccessful && res.code != null && res.code!.isNotEmpty) {
          _onWeChatCodeReceived(res.code!);
        } else {
          _errorMessage = res.errStr ?? '微信授权失败';
          _isLoading = false;
          notifyListeners();
        }
      }
    });
  }

  /// 收到微信 code 后的处理：本地直接视为登录成功（仅做演示）
  /// 正式环境应把 code 发给后端，后端用 code 换 access_token 并拉取用户信息后返回，再保存 token 与用户信息
  void _onWeChatCodeReceived(String code) {
    if (!_isWeChatRegistered) return;
    _isLoading = false;
    _isLoggedIn = true;
    _user = User(
      id: 'wx_${code.hashCode.abs()}',
      nickname: null, // 需后端用 access_token 拉取用户信息后写入
      avatarUrl: null,
    );
    _errorMessage = null;
    _save();
    notifyListeners();
  }

  Future<void> _registerWeChat() async {
    if (_kWeChatAppId.isEmpty || _kWeChatAppId == 'YOUR_WECHAT_APP_ID') {
      _isWeChatRegistered = false;
      notifyListeners();
      return;
    }
    try {
      final ok = await _fluwx.registerApi(
        appId: _kWeChatAppId,
        doOnAndroid: true,
        doOnIOS: true,
        universalLink: _kWeChatUniversalLink,
      );
      _isWeChatRegistered = ok;
    } catch (e) {
      _isWeChatRegistered = false;
    }
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_kKeyLoggedIn) ?? false;
    final id = prefs.getString(_kKeyUserId);
    if (id != null && _isLoggedIn) {
      _user = User(
        id: id,
        nickname: prefs.getString(_kKeyNickname),
        avatarUrl: prefs.getString(_kKeyAvatarUrl),
      );
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKeyLoggedIn, _isLoggedIn);
    if (_user != null) {
      await prefs.setString(_kKeyUserId, _user!.id);
      await prefs.setString(_kKeyNickname, _user!.nickname ?? '');
      await prefs.setString(_kKeyAvatarUrl, _user!.avatarUrl ?? '');
    }
  }

  /// 游客体验进入（未配置微信或开发时使用）
  void loginAsGuest() {
    _errorMessage = null;
    _isLoading = false;
    _isLoggedIn = true;
    _user = const User(id: 'guest', nickname: '体验用户', avatarUrl: null);
    _save();
    notifyListeners();
  }

  /// 微信一键登录
  Future<void> loginByWeChat() async {
    if (!_isWeChatRegistered) {
      _errorMessage = '请先在微信开放平台配置 AppID';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      final installed = await _fluwx.isWeChatInstalled;
      if (!installed) {
        _errorMessage = '请先安装微信';
        _isLoading = false;
        notifyListeners();
        return;
      }
      await _fluwx.authBy(
        which: NormalAuth(scope: 'snsapi_userinfo', state: 'skill_keeper'),
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _user = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKeyLoggedIn, false);
    await prefs.remove(_kKeyUserId);
    await prefs.remove(_kKeyNickname);
    await prefs.remove(_kKeyAvatarUrl);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authCancelable?.cancel();
    super.dispose();
  }
}
