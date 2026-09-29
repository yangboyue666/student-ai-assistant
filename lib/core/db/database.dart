import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'tables.dart';

/// 全局 SQLite 数据库（替代 Isar，更稳定的构建）
///
/// 表结构：
/// - schedules       日程
/// - assignments      作业
/// - courses          课程表
/// - table_rows       通用表格行
/// - chat_messages    对话历史
/// - images           图片引用
/// - chat_sessions     对话会话
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'student_assistant.db');
    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final sql in Tables.createSql) {
          batch.execute(sql);
        }
        await batch.commit();
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v2：新增心情日记表
          await db.execute('''
            CREATE TABLE ${Tables.moods}(
              id          TEXT PRIMARY KEY,
              emoji       TEXT NOT NULL,
              content     TEXT,
              date        INTEGER NOT NULL,
              created_at  INTEGER NOT NULL
            );
          ''');
          await db.execute(
              'CREATE INDEX idx_moods_date ON ${Tables.moods}(date);');
        }
      },
    );
  }

  Future<void> reset() async {
    final db = await database;
    final batch = db.batch();
    for (final t in Tables.allTables) {
      batch.delete(t);
    }
    await batch.commit();
  }
}
