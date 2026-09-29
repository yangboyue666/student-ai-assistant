import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import '../../shared/widgets/animated_indicators.dart';
import 'assignments_controller.dart';
import 'assignments_models.dart';
import 'assignments_repository.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(assignmentListProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: '作业进度'),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const SectionIndicator(
                        label: '我的作业',
                        colors: [AppColors.accent3, AppColors.accent1],
                      ),
                      const Spacer(),
                      _FilterChips(),
                    ],
                  ),
                ),
                Expanded(
                  child: asyncList.when(
                    data: (list) => list.isEmpty
                        ? _empty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: list.length,
                            itemBuilder: (ctx, i) {
                              final a = list[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AssignmentItem(a: a)
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: (i * 60).ms)
                                    .slideY(
                                        begin: 0.08,
                                        duration: 400.ms,
                                        curve: Curves.easeOutCubic),
                              );
                            },
                          ),
                    loading: () => const Center(child: PulsingDot(size: 18)),
                    error: (e, _) => Center(child: Text('加载失败：$e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新作业'),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WaveIndicator(height: 24, barCount: 5),
          const SizedBox(height: 16),
          Text(
            '还没有作业',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点击右下角 + 添加\n或对 AI 说："明天交数学作业"',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _AssignmentSheet(),
    ).then((_) => ref.invalidate(assignmentListProvider));
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(assignmentFilterProvider);
    final labels = {
      'all': '全部',
      'not_started': '未开始',
      'in_progress': '进行中',
      'completed': '已完成',
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: labels.entries.map((e) {
        final selected = filter == e.key;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => ref.read(assignmentFilterProvider.notifier).state = e.key,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent3.withOpacity(0.35)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.accent3.withOpacity(0.7)
                      : Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AssignmentItem extends ConsumerWidget {
  const _AssignmentItem({required this.a});
  final Assignment a;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = a.status == AssignmentStatus.completed
        ? AppColors.success
        : a.isOverdue
            ? AppColors.danger
            : a.status == AssignmentStatus.inProgress
                ? AppColors.warning
                : AppColors.info;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _edit(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent2.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.course,
                  style: const TextStyle(
                    color: AppColors.accent3,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                a.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.title,
            style: TextStyle(
              color: a.status == AssignmentStatus.completed
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              decoration: a.status == AssignmentStatus.completed
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                '${a.dueDate.month}/${a.dueDate.day} ${a.dueDate.hour.toString().padLeft(2, '0')}:${a.dueDate.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Text(
                a.dueLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (a.notes != null && a.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              a.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: a.progress / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                a.status == AssignmentStatus.completed
                    ? AppColors.success
                    : AppColors.accent1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${a.progress}%',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (a.status != AssignmentStatus.completed)
                GestureDetector(
                  onTap: () => _showProgressSlider(context, ref),
                  child: Text(
                    '调整进度',
                    style: TextStyle(
                      color: AppColors.accent1,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AssignmentSheet(existing: a),
    ).then((_) => ref.invalidate(assignmentListProvider));
  }

  void _showProgressSlider(BuildContext context, WidgetRef ref) {
    int progress = a.progress;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B5E),
        title: const Text('调整进度', style: TextStyle(color: AppColors.textPrimary)),
        content: StatefulBuilder(builder: (ctx, setS) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$progress%', style: const TextStyle(
                color: AppColors.accent1,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              )),
              Slider(
                value: progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppColors.accent2,
                onChanged: (v) => setS(() => progress = v.round()),
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AssignmentRepository.instance.updateProgress(a.id, progress);
              ref.invalidate(assignmentListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentSheet extends ConsumerStatefulWidget {
  const _AssignmentSheet({this.existing});
  final Assignment? existing;

  @override
  ConsumerState<_AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends ConsumerState<_AssignmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _due;
  late AssignmentStatus _status;
  late int _progress;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _courseCtrl = TextEditingController(text: e?.course ?? '');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _due = e?.dueDate ??
        DateTime.now().add(const Duration(days: 3));
    _status = e?.status ?? AssignmentStatus.notStarted;
    _progress = e?.progress ?? 0;
  }

  @override
  void dispose() {
    _courseCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassCard(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        borderRadius: 28,
        blurSigma: 24,
        backgroundOpacity: 0.16,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SectionIndicator(
                    label: isEdit ? '编辑作业' : '新建作业',
                    colors: const [AppColors.accent3, AppColors.accent1],
                  ),
                  const Spacer(),
                  if (isEdit)
                    GlassIconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onTap: () async {
                        await AssignmentRepository.instance.delete(widget.existing!.id);
                        ref.invalidate(assignmentListProvider);
                        if (mounted) Navigator.pop(context);
                      },
                      size: 36,
                    ),
                  if (isEdit) const SizedBox(width: 6),
                  GlassIconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onTap: () => Navigator.pop(context),
                    size: 36,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseCtrl,
                decoration: const InputDecoration(
                  hintText: '课程名（如：数学）',
                  prefixIcon: Icon(Icons.book_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入课程' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: '作业标题',
                  prefixIcon: Icon(Icons.assignment_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入标题' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: _due,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: Theme.of(ctx).colorScheme.copyWith(
                              primary: AppColors.accent2,
                              onPrimary: Colors.white,
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_due),
                  );
                  if (time == null) return;
                  setState(() {
                    _due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.glassLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 20, color: AppColors.accent1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '截止 ${_due.year}/${_due.month}/${_due.day} ${_due.hour.toString().padLeft(2, '0')}:${_due.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  hintText: '备注（可选）',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('状态', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Wrap(
                spacing: 8,
                children: AssignmentStatus.values.map((s) {
                  final selected = s == _status;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _status = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('进度 $_progress%',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Slider(
                value: _progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppColors.accent2,
                onChanged: (v) => setState(() => _progress = v.round()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final newA = Assignment(
                      id: widget.existing?.id ?? '',
                      course: _courseCtrl.text.trim(),
                      title: _titleCtrl.text.trim(),
                      dueDate: _due,
                      status: _status,
                      progress: _progress,
                      notes: _notesCtrl.text.trim().isEmpty
                          ? null
                          : _notesCtrl.text.trim(),
                      priority: widget.existing?.priority ?? 0,
                      createdAt: widget.existing?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    if (isEdit) {
                      await AssignmentRepository.instance.update(newA);
                    } else {
                      await AssignmentRepository.instance.create(newA);
                    }
                    ref.invalidate(assignmentListProvider);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(isEdit ? '保存修改' : '添加作业'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
