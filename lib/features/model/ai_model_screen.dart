import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/llm/model_manager.dart';
import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';

/// AI 模型管理页
///
/// 把模型下载/管理从聊天框里独立出来：不占用对话历史空间，
/// 下载完成后回到对话即可自动使用真实端侧模型。
class AiModelScreen extends ConsumerStatefulWidget {
  const AiModelScreen({super.key});

  @override
  ConsumerState<AiModelScreen> createState() => _AiModelScreenState();
}

class _AiModelScreenState extends ConsumerState<AiModelScreen> {
  ModelStatus _status = ModelStatus.notDownloaded;
  double _progress = 0.0;
  double _speed = 0.0;
  String? _error;

  StreamSubscription<ModelStatus>? _statusSub;
  StreamSubscription<double>? _progressSub;
  StreamSubscription<double>? _speedSub;

  @override
  void initState() {
    super.initState();
    final m = ModelManager.instance;
    _status = m.status;
    _progress = m.progress;
    _speed = m.speedBytesPerSec;
    _error = m.error;

    _statusSub = m.statusStream.listen((s) {
      if (mounted) {
        setState(() {
          _status = s;
          _error = m.error;
        });
      }
    });
    _progressSub = m.progressStream.listen((p) {
      if (mounted && (p - _progress).abs() >= 0.002) {
        setState(() => _progress = p);
      }
    });
    _speedSub = m.speedStream.listen((s) {
      if (mounted) setState(() => _speed = s);
    });

    m.refresh();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _progressSub?.cancel();
    _speedSub?.cancel();
    super.dispose();
  }

  Future<void> _download() async {
    await ModelManager.instance.download();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241442),
        title: const Text('删除模型', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          '删除后需重新下载（约 380MB）才能使用真实 AI。基础对话不受影响。',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await ModelManager.instance.delete();
  }

  String _fmtSpeed(double bps) {
    if (bps <= 0) return '';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'AI 模型'),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionIndicator(
                    label: '端侧大模型',
                    colors: [AppColors.accent1, AppColors.accent2],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildDescription(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    switch (_status) {
      case ModelStatus.ready:
      case ModelStatus.running:
        return _readyCard();
      case ModelStatus.downloading:
        return _downloadingCard();
      case ModelStatus.loading:
        return _loadingCard();
      case ModelStatus.error:
        return _errorCard();
      case ModelStatus.notDownloaded:
        return _notDownloadedCard();
    }
  }

  Widget _notDownloadedCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: AppColors.accent1, size: 20),
              SizedBox(width: 8),
              Text(
                '下载千问大模型',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '下载后即可在原来的对话框里直接使用真实端侧 AI，'
            '更智能、完全离线、不消耗流量与 API 费用。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('Qwen3-0.6B'),
              const SizedBox(width: 8),
              _chip('约 380MB'),
              const SizedBox(width: 8),
              _chip('国内镜像'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _download,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent1.withOpacity(0.85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('下载模型', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '不下载也可以使用基础 AI（离线模式匹配）。',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _downloadingCard() {
    final pct = (_progress * 100).toStringAsFixed(1);
    final speed = _fmtSpeed(_speed);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent1),
              ),
              const SizedBox(width: 10),
              Text(
                '正在下载千问模型… $pct%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent1),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '约 380MB · 支持断点续传',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (speed.isNotEmpty)
                Text(
                  speed,
                  style: const TextStyle(color: AppColors.accent4, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '请保持网络连接，下载完成后即可回到对话直接使用。',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundOpacity: 0.10,
      child: Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '模型加载中，首次加载可能需要十几秒，请稍候…',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readyCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 8),
              Text(
                '千问模型已就绪',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '回到对话即可直接使用真实端侧 AI，无需重启应用。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('删除模型以释放空间'),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text(
                '模型不可用',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _download,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent1.withOpacity(0.85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重新下载'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      backgroundOpacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '关于端侧 AI',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          _Bullet('推理完全在手机本地完成，数据不上传。'),
          _Bullet('未下载模型时使用离线模式匹配，基础对话可用。'),
          _Bullet('下载完成后自动升级为真实大模型，无需重启。'),
          _Bullet('模型较大（约 380MB），建议在 Wi-Fi 下下载。'),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppColors.accent1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
