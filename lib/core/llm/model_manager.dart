import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 模型下载与管理状态
enum ModelStatus {
  /// 模型不存在，需要下载
  notDownloaded,

  /// 下载中
  downloading,

  /// 已下载，待加载
  ready,

  /// 加载中
  loading,

  /// 运行中（已加载到内存）
  running,

  /// 出错
  error,
}

/// 端侧 LLM 模型管理器
///
/// 负责：
/// - 检查本地模型是否存在
/// - 从国内镜像（hf-mirror.com）下载 Qwen3-0.6B GGUF 模型
/// - 上报下载进度
/// - 缓存下载状态
class ModelManager {
  ModelManager._();
  static final ModelManager instance = ModelManager._();

  /// 模型在 hf-mirror.com 的下载地址
  static const String modelUrl =
      'https://hf-mirror.com/NobodyWho/Qwen_Qwen3-0.6B-GGUF/resolve/main/Qwen_Qwen3-0.6B-Q4_K_M.gguf';

  /// 模型文件名
  static const String modelFileName = 'Qwen3-0.6B-Q4_K_M.gguf';

  /// 预期文件大小（约 379 MB，用于进度估算）
  static const int expectedFileSize = 379 * 1024 * 1024;

  ModelStatus _status = ModelStatus.notDownloaded;
  double _progress = 0.0; // 0.0 - 1.0
  String? _error;

  final StreamController<ModelStatus> _statusCtrl =
      StreamController<ModelStatus>.broadcast();
  final StreamController<double> _progressCtrl =
      StreamController<double>.broadcast();

  ModelStatus get status => _status;
  double get progress => _progress;
  String? get error => _error;

  Stream<ModelStatus> get statusStream => _statusCtrl.stream;
  Stream<double> get progressStream => _progressCtrl.stream;

  /// 获取模型本地路径
  Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$modelFileName';
  }

  /// 检查模型是否已下载
  Future<bool> isModelDownloaded() async {
    final path = await modelPath;
    final file = File(path);
    if (!await file.exists()) return false;
    // 文件大小需超过 100MB 才算有效模型
    final len = await file.length();
    return len > 100 * 1024 * 1024;
  }

  /// 刷新状态
  Future<void> refresh() async {
    if (_status == ModelStatus.downloading ||
        _status == ModelStatus.loading ||
        _status == ModelStatus.running) {
      return;
    }
    if (await isModelDownloaded()) {
      _setStatus(ModelStatus.ready);
    } else {
      _setStatus(ModelStatus.notDownloaded);
    }
  }

  /// 开始下载模型
  Future<void> download() async {
    if (_status == ModelStatus.downloading) return;
    _setStatus(ModelStatus.downloading);
    _error = null;
    _progress = 0.0;
    _progressCtrl.add(0.0);

    try {
      final path = await modelPath;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      // 使用 HttpClient 下载，支持断点续传（此处简化为完整下载）
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(modelUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
            '下载失败，HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength > 0
          ? response.contentLength
          : expectedFileSize;

      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        downloaded += chunk.length;
        _progress = downloaded / totalBytes;
        _progressCtrl.add(_progress);
      }

      await sink.close();
      client.close();

      // 校验文件大小
      final len = await file.length();
      if (len < 100 * 1024 * 1024) {
        throw Exception('下载的文件不完整（${len ~/ (1024 * 1024)} MB）');
      }

      _progress = 1.0;
      _progressCtrl.add(1.0);
      _setStatus(ModelStatus.ready);
    } catch (e) {
      _error = e.toString();
      _setStatus(ModelStatus.error);
      // 清理不完整的文件
      try {
        final path = await modelPath;
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// 标记为加载中
  void markLoading() => _setStatus(ModelStatus.loading);

  /// 标记为运行中
  void markRunning() => _setStatus(ModelStatus.running);

  void _setStatus(ModelStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }

  void dispose() {
    _statusCtrl.close();
    _progressCtrl.close();
  }
}
