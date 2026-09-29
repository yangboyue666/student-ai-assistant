import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import '../../shared/widgets/animated_indicators.dart';
import '../../core/llm/llm_service.dart';
import '../../core/llm/model_manager.dart';
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.embedded = false});

  /// true 表示嵌入在主界面中央，不显示自己的 AppBar
  final bool embedded;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).ensureSession();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    try {
      await ref.read(chatMessagesProvider.notifier).send(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    if (messages.isNotEmpty) _scrollToBottom();

    final modelBanner = _ModelStatusBanner();

    if (widget.embedded) {
      return Column(
        children: [
          modelBanner,
          Expanded(child: _buildMessages(messages)),
          _buildInput(),
        ],
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'AI 助手'),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: const SectionIndicator(
                    label: '与 AI 对话',
                    colors: [AppColors.accent1, AppColors.accent2],
                  ),
                ),
                modelBanner,
                Expanded(child: _buildMessages(messages)),
                _buildInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(List<UIMessage> messages) {
    if (messages.isEmpty) {
      return SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const PulsingDot(size: 12, color: AppColors.accent1),
            const SizedBox(height: 10),
            Text(
              '我是你的本地 AI 助手',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: widget.embedded ? 15 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '完全离线运行，不会上传你的数据。\n试试说："明天下午3点开会"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: widget.embedded ? 12 : 13,
              ),
            ),
            const SizedBox(height: 14),
            _QuickPrompts(embedded: widget.embedded),
            const SizedBox(height: 8),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final m = messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MessageBubble(message: m)
              .animate()
              .fadeIn(duration: 300.ms, delay: (i * 20).ms)
              .slideY(begin: 0.04, duration: 300.ms, curve: Curves.easeOutCubic),
        );
      },
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        borderRadius: 26,
        blurSigma: 18,
        backgroundOpacity: 0.14,
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _sending ? null : () => _showActions(context),
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent1),
                iconSize: 26,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration.collapsed(
                    hintText: '说点什么吧...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accent1, AppColors.accent2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _sending
                    ? const Center(child: PulsingDot(size: 10, color: Colors.white))
                    : IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        padding: EdgeInsets.zero,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassCard(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        borderRadius: 28,
        backgroundOpacity: 0.16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionIndicator(
              label: '快捷操作',
              colors: [AppColors.accent1, AppColors.accent3],
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.event_available_rounded, color: AppColors.accent2),
              title: const Text('添加日程'),
              subtitle: const Text('自然语言解析为日程并提醒'),
              onTap: () {
                Navigator.pop(ctx);
                _inputCtrl.text = '明天下午3点开会';
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded, color: AppColors.accent3),
              title: const Text('添加作业'),
              subtitle: const Text('解析课程、标题、截止日期'),
              onTap: () {
                Navigator.pop(ctx);
                _inputCtrl.text = '后天交《高等数学》第3章习题';
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week_rounded, color: AppColors.accent4),
              title: const Text('添加课程'),
              subtitle: const Text('解析星期、节次、教室'),
              onTap: () {
                Navigator.pop(ctx);
                _inputCtrl.text = '周一第3节有《英语》课，教室A201';
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 模型下载状态横幅
class _ModelStatusBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ModelStatusBanner> createState() => _ModelStatusBannerState();
}

class _ModelStatusBannerState extends ConsumerState<_ModelStatusBanner> {
  ModelStatus _status = ModelStatus.notDownloaded;
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = ModelManager.instance.status;
    _progress = ModelManager.instance.progress;
    _error = ModelManager.instance.error;
    ModelManager.instance.refresh();

    ModelManager.instance.statusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
    ModelManager.instance.progressStream.listen((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  Future<void> _download() async {
    setState(() => _error = null);
    await ModelManager.instance.download();
  }

  @override
  Widget build(BuildContext context) {
    // 已就绪或运行中：显示简洁状态
    if (_status == ModelStatus.ready || _status == ModelStatus.running) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            const SizedBox(width: 6),
            Text(
              '千问模型已就绪 · 离线推理',
              style: TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 下载中：显示进度条
    if (_status == ModelStatus.downloading) {
      final pct = (_progress * 100).toStringAsFixed(0);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          backgroundOpacity: 0.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '正在下载千问模型... $pct%',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent1),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '模型约 380MB，下载完成后即可使用真实 AI',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    // 出错
    if (_status == ModelStatus.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          backgroundOpacity: 0.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '模型下载失败',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _download,
                    child: const Text('重试'),
                  ),
                ],
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      );
    }

    // 未下载：显示下载按钮
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        backgroundOpacity: 0.08,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.accent1, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '下载千问大模型，获得更智能的对话体验',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Qwen3-0.6B · 约 380MB · 从国内镜像下载',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _download,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent1.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('下载模型'),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '不下载也可使用基础 AI（模式匹配）',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      ('明天下午3点开会', Icons.event_available_rounded, AppColors.accent2),
      ('后天交数学作业', Icons.assignment_rounded, AppColors.accent3),
      ('怎么学英语更高效？', Icons.school_rounded, AppColors.accent4),
      ('1+1等于几', Icons.calculate_rounded, AppColors.accent1),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: prompts
          .map((p) => Chip(
                label: Text(
                  p.$1,
                  style: TextStyle(fontSize: embedded ? 12 : 13),
                ),
                avatar: Icon(p.$2, size: embedded ? 14 : 16, color: p.$3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ))
          .toList(),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final UIMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: GlassCard(
          margin: const EdgeInsets.only(left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 20,
          backgroundOpacity: 0.30,
          gradient: LinearGradient(
            colors: [
              AppColors.accent2.withOpacity(0.55),
              AppColors.accent3.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      );
    }
    if (message.role == 'tool') {
      // 工具结果展示
      return Align(
        alignment: Alignment.centerLeft,
        child: GlassCard(
          margin: const EdgeInsets.only(right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 16,
          backgroundOpacity: 0.06,
          borderOpacity: 0.25,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // assistant
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accent1, AppColors.accent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent1.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: GlassCard(
              margin: const EdgeInsets.only(right: 40),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: 20,
              backgroundOpacity: 0.12,
              child: message.isStreaming && message.content.isEmpty
                  ? const WaveIndicator(height: 20, barCount: 4, barWidth: 3, color: AppColors.accent1)
                  : Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
