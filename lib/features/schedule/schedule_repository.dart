import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';
import '../../core/notifications/notification_service.dart';
import 'schedule_models.dart';

class ScheduleRepository {
  ScheduleRepository._();
  static final ScheduleRepository instance = ScheduleRepository._();
  final _uuid = const Uuid();

  Future<List<Schedule>> all({bool onlyUpcoming = false}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.schedules,
      orderBy: 'datetime ASC',
      where: onlyUpcoming ? 'datetime >= ?' : null,
      whereArgs: onlyUpcoming ? [DateTime.now().millisecondsSinceEpoch] : null,
    );
    return rows.map(Schedule.fromMap).toList();
  }

  Future<List<Schedule>> byDay(DateTime day) async {
    final db = await AppDatabase.instance.database;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await db.query(
      Tables.schedules,
      where: 'datetime BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'datetime ASC',
    );
    return rows.map(Schedule.fromMap).toList();
  }

  Future<List<Schedule>> thisWeek() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.schedules,
      where: 'datetime BETWEEN ? AND ?',
      whereArgs: [
        weekStart.millisecondsSinceEpoch,
        weekEnd.millisecondsSinceEpoch,
      ],
      orderBy: 'datetime ASC',
    );
    return rows.map(Schedule.fromMap).toList();
  }

  Future<Schedule> create(Schedule s) async {
    final db = await AppDatabase.instance.database;
    final id = s.id.isEmpty ? _uuid.v4() : s.id;
    final newSchedule = Schedule(
      id: id,
      title: s.title,
      datetime: s.datetime,
      remindBefore: s.remindBefore,
      note: s.note,
      isDone: s.isDone,
      source: s.source,
      createdAt: s.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.insert(Tables.schedules, newSchedule.toMap());

    // 设置本地通知
    if (!newSchedule.isDone) {
      final fireAt = newSchedule.datetime.subtract(
        Duration(seconds: newSchedule.remindBefore),
      );
      if (fireAt.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleReminder(
          title: '日程提醒：${newSchedule.title}',
          body: '将于 ${newSchedule.shortTime} 开始',
          fireAt: fireAt,
          payload: 'schedule:$id',
          channelId: 'schedule_reminders',
          channel: scheduleChannel,
        );
      }
    }
    return newSchedule;
  }

  Future<Schedule?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(Tables.schedules, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Schedule.fromMap(rows.first);
  }

  Future<void> update(Schedule s) async {
    final db = await AppDatabase.instance.database;
    final updated = Schedule(
      id: s.id,
      title: s.title,
      datetime: s.datetime,
      remindBefore: s.remindBefore,
      note: s.note,
      isDone: s.isDone,
      source: s.source,
      createdAt: s.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.update(Tables.schedules, updated.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> markDone(String id, {bool done = true}) async {
    final s = await getById(id);
    if (s == null) return;
    await update(s.copyWith(isDone: done));
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.schedules, where: 'id = ?', whereArgs: [id]);
  }
}
