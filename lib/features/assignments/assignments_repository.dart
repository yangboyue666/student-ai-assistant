import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';
import '../../core/notifications/notification_service.dart';
import 'assignments_models.dart';

class AssignmentRepository {
  AssignmentRepository._();
  static final AssignmentRepository instance = AssignmentRepository._();
  final _uuid = const Uuid();

  Future<List<Assignment>> all({String? statusFilter, String? courseFilter}) async {
    final db = await AppDatabase.instance.database;
    final where = StringBuffer();
    final args = <dynamic>[];
    if (statusFilter != null && statusFilter != 'all') {
      where.write('status = ?');
      args.add(statusFilter);
    }
    if (courseFilter != null && courseFilter.isNotEmpty) {
      if (where.isNotEmpty) where.write(' AND ');
      where.write('course = ?');
      args.add(courseFilter);
    }
    final rows = await db.query(
      Tables.assignments,
      where: where.isEmpty ? null : where.toString(),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'due_date ASC',
    );
    return rows.map(Assignment.fromMap).toList();
  }

  Future<List<String>> courses() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.assignments,
      columns: ['DISTINCT course'],
      orderBy: 'course ASC',
    );
    return rows.map((r) => r['course'] as String).toList();
  }

  Future<Assignment?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(Tables.assignments, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Assignment.fromMap(rows.first);
  }

  Future<Assignment> create(Assignment a) async {
    final db = await AppDatabase.instance.database;
    final id = a.id.isEmpty ? _uuid.v4() : a.id;
    final newA = Assignment(
      id: id,
      course: a.course,
      title: a.title,
      dueDate: a.dueDate,
      status: a.status,
      progress: a.progress,
      notes: a.notes,
      priority: a.priority,
      createdAt: a.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.insert(Tables.assignments, newA.toMap());

    // 设置截止前 24 小时通知
    if (newA.status != AssignmentStatus.completed) {
      final fireAt = newA.dueDate.subtract(const Duration(hours: 24));
      if (fireAt.isAfter(DateTime.now())) {
        await NotificationService.instance.scheduleReminder(
          title: '作业即将截止',
          body: '《${newA.course}》${newA.title} 将于 ${newA.dueDate.month}/${newA.dueDate.day} 截止',
          fireAt: fireAt,
          payload: 'assignment:$id',
          channelId: 'assignment_reminders',
          channel: assignmentChannel,
        );
      }
    }
    return newA;
  }

  Future<void> update(Assignment a) async {
    final db = await AppDatabase.instance.database;
    final updated = Assignment(
      id: a.id,
      course: a.course,
      title: a.title,
      dueDate: a.dueDate,
      status: a.status,
      progress: a.progress,
      notes: a.notes,
      priority: a.priority,
      createdAt: a.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.update(Tables.assignments, updated.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.assignments, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProgress(String id, int progress, {AssignmentStatus? status}) async {
    final a = await getById(id);
    if (a == null) return;
    final newStatus = status ??
        (progress >= 100
            ? AssignmentStatus.completed
            : (progress > 0
                ? AssignmentStatus.inProgress
                : AssignmentStatus.notStarted));
    await update(a.copyWith(progress: progress, status: newStatus));
  }
}
