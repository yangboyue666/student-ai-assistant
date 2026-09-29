import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // 通知 channel
  static const _scheduleChannel = NotificationChannel(
    id: 'schedule_reminders',
    name: '日程提醒',
    description: '日程即将开始的提醒通知',
  );
  static const _assignmentChannel = NotificationChannel(
    id: 'assignment_reminders',
    name: '作业截止提醒',
    description: '作业截止日期临近时的提醒通知',
  );
  static const _aiChannel = NotificationChannel(
    id: 'ai_events',
    name: 'AI 助手事件',
    description: 'AI 工具调用相关通知',
  );

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // 自动选择本地时区
    try {
      final tzName = tz.local.name.isEmpty ? 'Asia/Shanghai' : tz.local.name;
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void Function(int notificationId, String? payload)? onTapNotification;

  void _onTap(NotificationResponse resp) {
    onTapNotification?.call(resp.id ?? 0, resp.payload);
  }

  Future<int> _nextId() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now % 0x7FFFFFFF;
  }

  Future<int> scheduleReminder({
    required String title,
    required String body,
    required DateTime fireAt,
    String? payload,
    String channelId = 'schedule_reminders',
    NotificationChannel? channel,
  }) async {
    await ensureInitialized();
    final id = await _nextId();
    final android = AndroidNotificationDetails(
      channelId,
      channel?.name ?? '提醒',
      channelDescription: channel?.description,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      enableVibration: true,
      enableLights: true,
      colorized: true,
      color: const Color(0xFF7DD3FC),
    );
    const ios = DarwinNotificationDetails();
    final tzTime = _toTZ(fireAt);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    return id;
  }

  Future<int> showImmediate({
    required String title,
    required String body,
    String? payload,
    String channelId = 'ai_events',
    NotificationChannel? channel,
  }) async {
    await ensureInitialized();
    final id = await _nextId();
    final android = AndroidNotificationDetails(
      channelId,
      channel?.name ?? '助手',
      channelDescription: channel?.description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      colorized: true,
      color: const Color(0xFFA78BFA),
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
    return id;
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _toTZ(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }
}

class NotificationChannel {
  final String id;
  final String name;
  final String? description;
  const NotificationChannel({
    required this.id,
    required this.name,
    this.description,
  });
}

final scheduleChannel = NotificationService._scheduleChannel;
final assignmentChannel = NotificationService._assignmentChannel;
final aiChannel = NotificationService._aiChannel;
