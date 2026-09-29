import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';
import 'mood_models.dart';

class MoodRepository {
  MoodRepository._();
  static final MoodRepository instance = MoodRepository._();
  final _uuid = const Uuid();

  Future<Mood> create(Mood mood) async {
    final db = await AppDatabase.instance.database;
    final id = mood.id.isEmpty ? _uuid.v4() : mood.id;
    final newMood = Mood.create(
      id: id,
      emoji: mood.emoji,
      content: mood.content,
      date: mood.date,
    );
    await db.insert(Tables.moods, newMood.toMap());
    return newMood;
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.moods, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Mood>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.moods,
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(Mood.fromMap).toList();
  }

  /// 获取指定日期的心情记录
  Future<List<Mood>> byDay(DateTime day) async {
    final db = await AppDatabase.instance.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      Tables.moods,
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
    return rows.map(Mood.fromMap).toList();
  }
}
