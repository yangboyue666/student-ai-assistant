import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import '../../shared/widgets/animated_indicators.dart';
import 'schedule_controller.dart';
import 'schedule_models.dart';
import 'schedule_repository.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(scheduleFilterProvider);
    final asyncList = ref.watch(scheduleListProvider(filter));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: '日程安排'),
      body: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: const BoxDecoration(gradient: appBackgroundGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const SectionIndicator(
                        label: '我的日程',
                        colors: [AppColors.accent2, AppColors.accent3],
                      ),
                      const Spacer(),
                      _FilterChips(),
                    ],
                  ),
                ),
                Expanded(
                  child: asyncList.when(
                    data: (list) => _ScheduleList(list: list),
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
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新日程'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _CreateScheduleSheet(),
    ).then((_) => ref.invalidate(scheduleListProvider));
  }
}

class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(scheduleFilterProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ScheduleFilter.values.map((f) {
        final selected = f == filter;
        final labels = {
          ScheduleFilter.today: '今天',
          ScheduleFilter.thisWeek: '本周',
          ScheduleFilter.upcoming: '待办',
          ScheduleFilter.all: '全部',
        };
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => ref.read(scheduleFilterProvider.notifier).state = f,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent2.withOpacity(0.35)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.accent1.withOpacity(0.7)
                      : Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Text(
                labels[f]!,
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

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.list});
  final List<Schedule> list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WaveIndicator(height: 24, barCount: 5),
            const SizedBox(height: 16),
            Text(
              '这里空空如也',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点击右下角 + 添加日程\n或对 AI 说："明天下午3点开会"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ScheduleItem(schedule: s)
              .animate()
              .fadeIn(duration: 400.ms, delay: (i * 60).ms)
              .slideY(begin: 0.08, duration: 400.ms, curve: Curves.easeOutCubic),
        );
      },
    );
  }
}

class _ScheduleItem extends ConsumerWidget {
  const _ScheduleItem({required this.schedule});
  final Schedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPast = schedule.datetime.isBefore(DateTime.now());
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _edit(context, ref),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 时间左侧
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Text(
                  schedule.shortTime,
                  style: TextStyle(
                    color: schedule.isDone
                        ? AppColors.textMuted
                        : AppColors.accent1,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.datetime.month}/${schedule.datetime.day}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 主标题区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: TextStyle(
                    color: schedule.isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: schedule.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (schedule.note != null && schedule.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    schedule.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (schedule.source == 'ai')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent2.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AI 创建',
                          style: TextStyle(
                            color: AppColors.accent3,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (schedule.source == 'ai') const SizedBox(width: 6),
                    Text(
                      schedule.relativeDescription,
                      style: TextStyle(
                        color: isPast
                            ? AppColors.warning
                            : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 完成按钮
          GestureDetector(
            onTap: () async {
              await ScheduleRepository.instance.markDone(schedule.id, done: !schedule.isDone);
              ref.invalidate(scheduleListProvider);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: schedule.isDone
                    ? AppColors.success.withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: schedule.isDone ? AppColors.success : AppColors.glassBorder,
                  width: 1.5,
                ),
              ),
              child: schedule.isDone
                  ? const Icon(Icons.check_rounded, size: 18, color: AppColors.success)
                  : null,
            ),
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
      builder: (ctx) => _EditScheduleSheet(schedule: schedule),
    ).then((_) => ref.invalidate(scheduleListProvider));
  }
}

class _CreateScheduleSheet extends ConsumerStatefulWidget {
  const _CreateScheduleSheet();
  @override
  ConsumerState<_CreateScheduleSheet> createState() => _CreateScheduleSheetState();
}

class _CreateScheduleSheetState extends ConsumerState<_CreateScheduleSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _selectedDt;
  int _remind = 600;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
                  const SectionIndicator(
                    label: '新建日程',
                    colors: [AppColors.accent2, AppColors.accent3],
                  ),
                  const Spacer(),
                  GlassIconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onTap: () => Navigator.pop(context),
                    size: 36,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: '日程标题（如：开会）',
                  prefixIcon: Icon(Icons.event_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (v) => (v == null || v.isEmpty) ? '请输入标题' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final dt = await _pickDateTime(context);
                  if (dt != null) setState(() => _selectedDt = dt);
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
                      const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accent1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDt == null
                              ? '选择时间'
                              : '${_selectedDt!.year}/${_selectedDt!.month}/${_selectedDt!.day} ${_selectedDt!.hour.toString().padLeft(2, '0')}:${_selectedDt!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _selectedDt == null ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  hintText: '备注（可选）',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('提前提醒', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  ChoiceChip(label: const Text('10 分'), selected: _remind == 600, onSelected: (_) => setState(() => _remind = 600)),
                  const SizedBox(width: 6),
                  ChoiceChip(label: const Text('30 分'), selected: _remind == 1800, onSelected: (_) => setState(() => _remind = 1800)),
                  const SizedBox(width: 6),
                  ChoiceChip(label: const Text('1 小时'), selected: _remind == 3600, onSelected: (_) => setState(() => _remind = 3600)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (_selectedDt == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('请选择时间')),
                      );
                      return;
                    }
                    final s = Schedule.create(
                      id: '',
                      title: _titleCtrl.text.trim(),
                      datetime: _selectedDt!,
                      remindBefore: _remind,
                      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                      source: 'manual',
                    );
                    await ScheduleRepository.instance.create(s);
                    ref.invalidate(scheduleListProvider);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('保存日程'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      initialDate: DateTime.now(),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: AppColors.accent2,
              onPrimary: Colors.white,
            ),
      ),
      child: child!,
    );
  }
}

class _EditScheduleSheet extends ConsumerStatefulWidget {
  const _EditScheduleSheet({required this.schedule});
  final Schedule schedule;
  @override
  ConsumerState<_EditScheduleSheet> createState() => _EditScheduleSheetState();
}

class _EditScheduleSheetState extends ConsumerState<_EditScheduleSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _dt;
  late bool _done;
  late int _remind;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.schedule.title);
    _noteCtrl = TextEditingController(text: widget.schedule.note ?? '');
    _dt = widget.schedule.datetime;
    _done = widget.schedule.isDone;
    _remind = widget.schedule.remindBefore;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    return GlassCard(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      borderRadius: 28,
      blurSigma: 24,
      backgroundOpacity: 0.16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionIndicator(
                label: '编辑日程',
                colors: [AppColors.accent2, AppColors.accent3],
              ),
              const Spacer(),
              GlassIconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onTap: () async {
                  await ScheduleRepository.instance.delete(s.id);
                  ref.invalidate(scheduleListProvider);
                  if (mounted) Navigator.pop(context);
                },
                size: 36,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onTap: () => Navigator.pop(context),
                size: 36,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '日程标题',
              prefixIcon: Icon(Icons.event_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final dt = await _pickDateTime(context);
              if (dt != null) setState(() => _dt = dt);
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
                  const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accent1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_dt.year}/${_dt.month}/${_dt.day} ${_dt.hour.toString().padLeft(2, '0')}:${_dt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '备注',
              prefixIcon: Icon(Icons.notes_rounded, size: 20),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('提前提醒', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 12),
              ChoiceChip(label: const Text('10 分'), selected: _remind == 600, onSelected: (_) => setState(() => _remind = 600)),
              const SizedBox(width: 6),
              ChoiceChip(label: const Text('30 分'), selected: _remind == 1800, onSelected: (_) => setState(() => _remind = 1800)),
              const SizedBox(width: 6),
              ChoiceChip(label: const Text('1 小时'), selected: _remind == 3600, onSelected: (_) => setState(() => _remind = 3600)),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('标记为已完成'),
            value: _done,
            onChanged: (v) => setState(() => _done = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final updated = widget.schedule.copyWith(
                  title: _titleCtrl.text.trim(),
                  datetime: _dt,
                  note: _noteCtrl.text.trim(),
                  isDone: _done,
                  remindBefore: _remind,
                );
                await ScheduleRepository.instance.update(updated);
                ref.invalidate(scheduleListProvider);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('保存修改'),
            ),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _dt,
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
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dt),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
