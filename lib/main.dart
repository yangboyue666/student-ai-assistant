import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;

import 'app.dart';
import 'core/background/workmanager_setup.dart';
import 'core/notifications/notification_service.dart';
import 'core/llm/model_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地通知
  await NotificationService.instance.ensureInitialized();
  await NotificationService.instance.requestPermissions();

  // 初始化后台任务（每日检查作业/日程提醒）
  try {
    await WorkmanagerSetup.init();
  } catch (_) {
    // 后台任务初始化失败不阻断启动
  }

  // 初始化端侧 AI 推理引擎（nobodywho / llama.cpp）
  try {
    await nobodywho.NobodyWho.init();
  } catch (_) {
    // nobodywho 初始化失败不阻断启动，AI 功能会自动降级到模式匹配
  }

  // 刷新模型下载状态
  try {
    await ModelManager.instance.refresh();
  } catch (_) {}

  runApp(const ProviderScope(child: StudentAssistantApp()));
}
