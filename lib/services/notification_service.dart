import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// 练习提醒：每日固定时间推送本地通知，支持开关与自定义时间
class NotificationService extends ChangeNotifier {
  static const int _reminderId = 1;
  static const String _keyEnabled = 'reminder_enabled';
  static const String _keyHour = 'reminder_hour';
  static const String _keyMinute = 'reminder_minute';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _enabled = false;
  int _hour = 20;   // 默认 20:00
  int _minute = 0;
  bool _initialized = false;

  bool get reminderEnabled => _enabled;
  int get reminderHour => _hour;
  int get reminderMinute => _minute;
  bool get isInitialized => _initialized;

  /// 格式化为 "20:00"
  String get reminderTimeStr =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (_) {
      // 若无 Asia/Shanghai 则使用本地
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _loadSettings();
    if (_enabled) await _scheduleReminder();
    _initialized = true;
    notifyListeners();
  }

  void _onNotificationTap(NotificationResponse response) {
    // 用户点击通知时可在此处理（如跳转首页）
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _hour = prefs.getInt(_keyHour) ?? 20;
    _minute = prefs.getInt(_keyMinute) ?? 0;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, _enabled);
    await prefs.setInt(_keyHour, _hour);
    await prefs.setInt(_keyMinute, _minute);
  }

  /// 请求通知权限（Android 13+ / iOS）
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// 开启/关闭提醒。返回 true 表示成功，false 表示权限被拒绝（仅当开启时）
  Future<bool> setReminderEnabled(bool enabled) async {
    if (_enabled == enabled) return true;
    if (enabled) {
      final granted = await requestPermission();
      if (!granted) {
        notifyListeners();
        return false;
      }
    }
    _enabled = enabled;
    await _saveSettings();
    if (enabled) {
      await _scheduleReminder();
    } else {
      await _plugin.cancel(_reminderId);
    }
    notifyListeners();
    return true;
  }

  /// 设置提醒时间（0–23 时，0–59 分）
  Future<void> setReminderTime(int hour, int minute) async {
    if (_hour == hour && _minute == minute) return;
    _hour = hour.clamp(0, 23);
    _minute = minute.clamp(0, 59);
    await _saveSettings();
    if (_enabled) await _scheduleReminder();
    notifyListeners();
  }

  /// 调度每日重复提醒
  Future<void> _scheduleReminder() async {
    await _plugin.cancel(_reminderId);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _hour,
      _minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'practice_reminder',
      '练习提醒',
      channelDescription: '每日练习提醒，帮助技能防锈',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        _reminderId,
        '该练一练了',
        '技能不练会生锈～打开 Skill Keeper 保持状态',
        scheduledDate,
        details,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService schedule error: $e');
    }
  }
}
