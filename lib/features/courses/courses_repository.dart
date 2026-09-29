import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';
import '../images/image_service.dart';
import 'courses_models.dart';

class CourseRepository {
  CourseRepository._();
  static final CourseRepository instance = CourseRepository._();
  final _uuid = const Uuid();

  Future<List<Course>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.courses,
      orderBy: 'weekday ASC, period ASC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<List<Course>> byWeekday(int weekday) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.courses,
      where: 'weekday = ?',
      whereArgs: [weekday],
      orderBy: 'period ASC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<Course?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(Tables.courses, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Course.fromMap(rows.first);
  }

  Future<Course> create(Course c) async {
    final db = await AppDatabase.instance.database;
    final id = c.id.isEmpty ? _uuid.v4() : c.id;
    final newC = Course(
      id: id,
      name: c.name,
      weekday: c.weekday,
      period: c.period,
      weekStart: c.weekStart,
      weekEnd: c.weekEnd,
      weekPattern: c.weekPattern,
      location: c.location,
      teacher: c.teacher,
      color: c.color,
      note: c.note,
      createdAt: c.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.insert(Tables.courses, newC.toMap());
    return newC;
  }

  Future<void> update(Course c) async {
    final db = await AppDatabase.instance.database;
    final updated = Course(
      id: c.id,
      name: c.name,
      weekday: c.weekday,
      period: c.period,
      weekStart: c.weekStart,
      weekEnd: c.weekEnd,
      weekPattern: c.weekPattern,
      location: c.location,
      teacher: c.teacher,
      color: c.color,
      note: c.note,
      createdAt: c.createdAt,
      updatedAt: DateTime.now(),
    );
    await db.update(Tables.courses, updated.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(Tables.courses, where: 'id = ?', whereArgs: [id]);
    // 关联的图片也会被孤立，但不删除
  }

  /// 关联一张图片到课程
  Future<void> attachImage(String courseId, String filePath) async {
    final db = await AppDatabase.instance.database;
    await db.insert(Tables.images, {
      'id': _uuid.v4(),
      'ref_type': 'course',
      'ref_id': courseId,
      'file_path': filePath,
      'file_name': filePath.split('/').last,
      'mime_type': 'image/jpeg',
      'bytes': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ImageRecord>> imagesForCourse(String courseId) async {
    return ImageService.instance.listByRef(refType: 'course', refId: courseId);
  }

  /// "课程表整体图片" - 用 ref_id = 'global' 表示课程表全图
  Future<List<ImageRecord>> scheduleImages() {
    return ImageService.instance.listByRef(refType: 'course_schedule', refId: 'global');
  }

  Future<String?> attachScheduleImage(String filePath) async {
    final db = await AppDatabase.instance.database;
    final id = _uuid.v4();
    await db.insert(Tables.images, {
      'id': id,
      'ref_type': 'course_schedule',
      'ref_id': 'global',
      'file_path': filePath,
      'file_name': filePath.split('/').last,
      'mime_type': 'image/jpeg',
      'bytes': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return filePath;
  }
}
