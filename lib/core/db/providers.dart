import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

/// 数据库 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
