import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../db/tables.dart';
import '../notifications/notification_service.dart';

/// Workmanager 后台任务：每日检查作业截止、日程提醒
class WorkmanagerSetup {
  WorkmanagerSetup._();

  static const _dailyCheckTask = 'student.dailyCheckTask';
  static const _scheduleRemindersTask = 'student.scheduleReminders';

  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    await Workmanager().registerPeriodicTask(
      _dailyCheckTask,
      _dailyCheckTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// 提供给 Workmanager 的回调
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        switch (task) {
          case _dailyCheckTask:
            await _checkAssignments();
            await _checkSchedules();
            break;
        }
      } catch (e) {
        // 即使出错也返回 true，避免被系统反复重试
        debugPrint('Workmanager task $task error: $e');
      }
      return true;
    });
  }

  /// 作业截止检查：找出 24 小时内即将截止的未完成作业，发送通知
  static Future<void> _checkAssignments() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    final rows = await db.query(
      Tables.assignments,
      where: 'due_date BETWEEN ? AND ? AND status != ?',
      whereArgs: [now.millisecondsSinceEpoch, tomorrow.millisecondsSinceEpoch, 'completed'],
      orderBy: 'due_date ASC',
    );
    for (final row in rows) {
      final title = row['title'] as String?;
      final course = row['course'] as String?;
      final dueMs = row['due_date'] as int;
      final due = DateTime.fromMillisecondsSinceEpoch(dueMs);
      final diff = due.difference(now);
      final hours = diff.inHours;
      await NotificationService.instance.showImmediate(
        title: '作业即将截止',
        body: '《$course》$title 将在 $hours 小时后截止（$due）',
        channelId: 'assignment_reminders',
        channel: assignmentChannel,
      );
    }
  }

  /// 日程提醒：找出 1 小时内即将开始的日程，发送通知
  static Future<void> _checkSchedules() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    final rows = await db.query(
      Tables.schedules,
      where: 'datetime BETWEEN ? AND ? AND is_done = 0',
      whereArgs: [now.millisecondsSinceEpoch, oneHourLater.millisecondsSinceEpoch],
      orderBy: 'datetime ASC',
    );
    for (final row in rows) {
      final title = row['title'] as String?;
      final dtMs = row['datetime'] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(dtMs);
      await NotificationService.instance.showImmediate(
        title: '日程即将开始',
        body: '《$title》将在 ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} 开始',
        channelId: 'schedule_reminders',
        channel: scheduleChannel,
      );
    }
  }
}
