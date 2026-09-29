import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/db/tables.dart';

/// 图片上传服务：拍照 / 相册选择，保存到应用目录，并记录路径到数据库
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  /// 拍照并保存
  Future<String?> fromCamera({
    String refType = 'generic',
    String? refId,
  }) async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    return _persist(x, refType: refType, refId: refId);
  }

  /// 相册选择并保存
  Future<String?> fromGallery({
    String refType = 'generic',
    String? refId,
  }) async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    return _persist(x, refType: refType, refId: refId);
  }

  Future<String?> _persist(
    XFile? file, {
    required String refType,
    String? refId,
  }) async {
    if (file == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final fileName = '${_uuid.v4()}$ext';
    final destPath = p.join(imagesDir.path, fileName);
    await file.saveTo(destPath);

    // 记录到数据库
    final db = await AppDatabase.instance.database;
    final id = _uuid.v4();
    final bytes = await File(destPath).length();
    await db.insert(Tables.images, {
      'id': id,
      'ref_type': refType,
      'ref_id': refId,
      'file_path': destPath,
      'file_name': fileName,
      'mime_type': file.mimeType,
      'bytes': bytes,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    return destPath;
  }

  /// 查询某个引用下的图片
  Future<List<ImageRecord>> listByRef({
    required String refType,
    String? refId,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      Tables.images,
      where: refId == null
          ? 'ref_type = ?'
          : 'ref_type = ? AND ref_id = ?',
      whereArgs: refId == null ? [refType] : [refType, refId],
      orderBy: 'created_at DESC',
    );
    return rows.map(ImageRecord.fromMap).toList();
  }

  /// 删除图片
  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(Tables.images, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final path = rows.first['file_path'] as String;
    final f = File(path);
    if (await f.exists()) await f.delete();
    await db.delete(Tables.images, where: 'id = ?', whereArgs: [id]);
  }
}

class ImageRecord {
  final String id;
  final String refType;
  final String? refId;
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final int? bytes;
  final DateTime createdAt;

  ImageRecord({
    required this.id,
    required this.refType,
    this.refId,
    required this.filePath,
    this.fileName,
    this.mimeType,
    this.bytes,
    required this.createdAt,
  });

  factory ImageRecord.fromMap(Map<String, dynamic> m) {
    return ImageRecord(
      id: m['id'] as String,
      refType: m['ref_type'] as String,
      refId: m['ref_id'] as String?,
      filePath: m['file_path'] as String,
      fileName: m['file_name'] as String?,
      mimeType: m['mime_type'] as String?,
      bytes: m['bytes'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }
}
