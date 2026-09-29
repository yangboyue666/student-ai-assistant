import 'dart:async';
import 'dart:io';

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
/// - 从国内镜像（hf-mirror.com）下载 Qwen3-0.6B GGUF 模型，失败自动回退官方源
/// - 支持断点续传、进度与速度上报
/// - 缓存下载状态
class ModelManager {
  ModelManager._();
  static final ModelManager instance = ModelManager._();

  /// 主下载源（国内镜像，速度快）
  static const String primaryUrl =
      'https://hf-mirror.com/NobodyWho/Qwen_Qwen3-0.6B-GGUF/resolve/main/Qwen_Qwen3-0.6B-Q4_K_M.gguf';

  /// 备用下载源（HuggingFace 官方）
  static const String fallbackUrl =
      'https://huggingface.co/NobodyWho/Qwen_Qwen3-0.6B-GGUF/resolve/main/Qwen_Qwen3-0.6B-Q4_K_M.gguf';

  /// 模型文件名
  static const String modelFileName = 'Qwen3-0.6B-Q4_K_M.gguf';

  /// 预期文件大小（约 379 MB，用于进度估算）
  static const int expectedFileSize = 379 * 1024 * 1024;

  /// 有效模型的最小体积（小于该值视为损坏）
  static const int minValidSize = 100 * 1024 * 1024;

  ModelStatus _status = ModelStatus.notDownloaded;
  double _progress = 0.0; // 0.0 - 1.0
  double _speedBytesPerSec = 0.0;
  String? _error;

  final StreamController<ModelStatus> _statusCtrl =
      StreamController<ModelStatus>.broadcast();
  final StreamController<double> _progressCtrl =
      StreamController<double>.broadcast();
  final StreamController<double> _speedCtrl =
      StreamController<double>.broadcast();

  ModelStatus get status => _status;
  double get progress => _progress;
  double get speedBytesPerSec => _speedBytesPerSec;
  String? get error => _error;
  bool get isDownloading => _status == ModelStatus.downloading;

  Stream<ModelStatus> get statusStream => _statusCtrl.stream;
  Stream<double> get progressStream => _progressCtrl.stream;
  Stream<double> get speedStream => _speedCtrl.stream;

  /// 获取模型本地路径
  Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$modelFileName';
  }

  /// 检查模型是否已下载且完整
  Future<bool> isModelDownloaded() async {
    final path = await modelPath;
    final file = File(path);
    if (!await file.exists()) return false;
    final len = await file.length();
    return len >= minValidSize;
  }

  /// 刷新状态（根据本地文件判断）
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

  /// 开始下载模型（支持断点续传 + 镜像回退）
  Future<void> download() async {
    if (_status == ModelStatus.downloading) return;
    _setStatus(ModelStatus.downloading);
    _error = null;
    _progress = 0.0;
    _speedBytesPerSec = 0.0;
    _progressCtrl.add(0.0);
    _speedCtrl.add(0.0);

    final path = await modelPath;
    final partFile = File('$path.part');

    Object? lastError;
    for (final url in const [primaryUrl, fallbackUrl]) {
      try {
        await _downloadFrom(url, partFile);
        // 下载完成：重命名临时文件
        final finalFile = File(path);
        if (await finalFile.exists()) await finalFile.delete();
        await partFile.rename(path);

        final len = await finalFile.length();
        if (len < minValidSize) {
          throw Exception('下载的文件不完整（${len ~/ (1024 * 1024)} MB）');
        }
        _progress = 1.0;
        _progressCtrl.add(1.0);
        _setStatus(ModelStatus.ready);
        return;
      } catch (e) {
        lastError = e;
        // 当前源失败：保留 .part 以支持下次续传，继续尝试下一个源
      }
    }

    _error = lastError?.toString() ?? '下载失败';
    _setStatus(ModelStatus.error);
  }

  Future<void> _downloadFrom(String url, File partFile) async {
    int existing = await partFile.exists() ? await partFile.length() : 0;

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.getUrl(Uri.parse(url));
      // 断点续传
      if (existing > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
      }
      final response = await request.close();

      final serverSupportsResume = response.statusCode == 206;
      if (existing > 0 && !serverSupportsResume) {
        // 服务器不支持续传，从头下载
        existing = 0;
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException('下载失败，HTTP ${response.statusCode}',
            uri: Uri.parse(url));
      }

      final remaining = response.contentLength;
      final total = remaining > 0
          ? remaining + existing
          : (existing > 0 ? expectedFileSize : expectedFileSize);

      final sink = partFile.openWrite(
        mode: existing > 0 ? FileMode.append : FileMode.write,
      );
      int downloaded = existing;
      final stopwatch = Stopwatch()..start();
      int lastEmitMs = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        downloaded += chunk.length;
        _progress = (downloaded / total).clamp(0.0, 1.0);
        _progressCtrl.add(_progress);

        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs - lastEmitMs >= 500) {
          lastEmitMs = elapsedMs;
          if (elapsedMs > 0) {
            _speedBytesPerSec = downloaded / (elapsedMs / 1000.0);
            _speedCtrl.add(_speedBytesPerSec);
          }
        }
      }

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  /// 删除已下载的模型（释放空间）
  Future<void> delete() async {
    final path = await modelPath;
    for (final p in ['$path', '$path.part']) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _progress = 0.0;
    _speedBytesPerSec = 0.0;
    _error = null;
    _setStatus(ModelStatus.notDownloaded);
  }

  /// 标记为加载中
  void markLoading() => _setStatus(ModelStatus.loading);

  /// 标记为运行中
  void markRunning() => _setStatus(ModelStatus.running);

  /// 标记为错误
  void markError(String message) {
    _error = message;
    _setStatus(ModelStatus.error);
  }

  void _setStatus(ModelStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }

  void dispose() {
    _statusCtrl.close();
    _progressCtrl.close();
    _speedCtrl.close();
  }
}
