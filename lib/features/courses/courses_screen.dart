import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import '../../shared/widgets/animated_indicators.dart';
import '../images/image_service.dart';
import 'courses_controller.dart';
import 'courses_models.dart';
import 'courses_repository.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncCourses = ref.watch(coursesProvider);
    final asyncImages = ref.watch(scheduleImagesProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: '课程表',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GlassIconButton(
              icon: const Icon(Icons.close_rounded),
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: const SectionIndicator(
                      label: '本周课程表',
                      colors: [AppColors.accent4, AppColors.accent1],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 课程表图片（参考）
                  asyncImages.when(
                    data: (imgs) => imgs.isEmpty
                        ? _ImageUploadPrompt(onPick: _pickScheduleImage)
                        : SizedBox(
                            height: 180,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: imgs.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (ctx, i) {
                                final img = imgs[i];
                                return GlassCard(
                                  padding: EdgeInsets.zero,
                                  borderRadius: 20,
                                  onTap: () => _viewImage(context, img.filePath),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(
                                          File(img.filePath),
                                          width: 220,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GlassIconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onTap: () async {
                                            await ImageService.instance.delete(img.id);
                                            ref.invalidate(scheduleImagesProvider);
                                          },
                                          size: 30,
                                          backgroundOpacity: 0.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // 周视图网格
                  asyncCourses.when(
                    data: (courses) => _WeekGrid(
                      courses: courses,
                      onEdit: (c) => _showEditSheet(context, c),
                      onDelete: (c) => _confirmDelete(context, c),
                    ),
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: PulsingDot(size: 18)),
                    ),
                    error: (e, _) => Center(child: Text('加载失败：$e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加课程'),
      ),
    );
  }

  Future<void> _pickScheduleImage() async {
    final path = await ImageService.instance.fromGallery(refType: 'course_schedule', refId: 'global');
    if (path != null) {
      await CourseRepository.instance.attachScheduleImage(path);
      ref.invalidate(scheduleImagesProvider);
    }
  }

  void _viewImage(BuildContext context, String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ImagePreview(path: path),
    ));
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _CourseSheet(),
    ).then((_) => ref.invalidate(coursesProvider));
  }

  void _showEditSheet(BuildContext context, Course existing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CourseSheet(existing: existing),
    ).then((_) => ref.invalidate(coursesProvider));
  }

  /// 长按课程方块时弹出删除确认
  Future<void> _confirmDelete(BuildContext context, Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除「${course.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CourseRepository.instance.delete(course.id);
      ref.invalidate(coursesProvider);
    }
  }
}

class _ImageUploadPrompt extends StatelessWidget {
  const _ImageUploadPrompt({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onPick,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent4.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.accent4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '上传课程表照片',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '从相册选图作为参考，方便手动录入',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.courses,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Course> courses;
  final void Function(Course) onEdit;
  final void Function(Course) onDelete;

  @override
  Widget build(BuildContext context) {
    // 找出最大节次
    final maxPeriod = courses.fold<int>(8, (prev, c) => c.period > prev ? c.period : prev);
    final periodCount = maxPeriod < 8 ? 8 : maxPeriod;
    final cellWidth = 64.0;
    final cellHeight = 64.0;

    return GlassCard(
      padding: const EdgeInsets.all(8),
      borderRadius: 24,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // 表头
            Row(
              children: [
                SizedBox(
                  width: cellWidth,
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text('节/天', style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                ),
                ...Course.weekdayNames.map((d) => SizedBox(
                  width: cellWidth,
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(d, style: TextStyle(
                      color: AppColors.accent1,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )),
                  ),
                )),
              ],
            ),
            // 数据行
            ...List.generate(periodCount, (periodIdx) {
              final period = periodIdx + 1;
              return Row(
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: Container(
                      height: cellHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.glassLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$period', style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                    ),
                  ),
                  ...List.generate(7, (dayIdx) {
                    final weekday = dayIdx + 1;
                    final course = courses.cast<Course?>().firstWhere(
                      (c) => c?.weekday == weekday && c?.period == period,
                      orElse: () => null,
                    );
                    return SizedBox(
                      width: cellWidth,
                      child: Container(
                        height: cellHeight,
                        padding: const EdgeInsets.all(4),
                        child: course == null
                            ? null
                            : _CourseCell(
                                course: course,
                                onEdit: () => onEdit(course),
                                onDelete: () => onDelete(course),
                              ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CourseCell extends StatelessWidget {
  const _CourseCell({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  course.colorValue.withOpacity(0.85),
                  course.colorValue.withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: course.colorValue.withOpacity(0.6),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    course.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
                if (course.location != null && course.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      course.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 右上角的删除小按钮
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 0.5),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseSheet extends ConsumerStatefulWidget {
  const _CourseSheet({this.existing});
  final Course? existing;

  @override
  ConsumerState<_CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends ConsumerState<_CourseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _teacherCtrl;
  late int _weekday;
  late int _period;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _locationCtrl = TextEditingController(text: widget.existing?.location ?? '');
    _teacherCtrl = TextEditingController(text: widget.existing?.teacher ?? '');
    _weekday = widget.existing?.weekday ?? 1;
    _period = widget.existing?.period ?? 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
                  SectionIndicator(
                    label: isEdit ? '编辑课程' : '添加课程',
                    colors: const [AppColors.accent4, AppColors.accent1],
                  ),
                  const Spacer(),
                  if (isEdit)
                    GlassIconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onTap: () async {
                        await CourseRepository.instance.delete(widget.existing!.id);
                        ref.invalidate(coursesProvider);
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
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: '课程名',
                  prefixIcon: Icon(Icons.book_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入课程名' : null,
              ),
              const SizedBox(height: 16),
              Text('星期', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final d = i + 1;
                  final selected = d == _weekday;
                  return ChoiceChip(
                    label: Text(Course.weekdayNames[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _weekday = d),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text('节次', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(12, (i) {
                  final p = i + 1;
                  final selected = p == _period;
                  return ChoiceChip(
                    label: Text('第$p节'),
                    selected: selected,
                    onSelected: (_) => setState(() => _period = p),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: '教室 / 地点',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacherCtrl,
                decoration: const InputDecoration(
                  hintText: '教师',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final newC = Course(
                      id: widget.existing?.id ?? '',
                      name: _nameCtrl.text.trim(),
                      weekday: _weekday,
                      period: _period,
                      location: _locationCtrl.text.trim().isEmpty
                          ? null
                          : _locationCtrl.text.trim(),
                      teacher: _teacherCtrl.text.trim().isEmpty
                          ? null
                          : _teacherCtrl.text.trim(),
                      color: widget.existing?.color,
                      createdAt: widget.existing?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    if (isEdit) {
                      await CourseRepository.instance.update(newC);
                    } else {
                      await CourseRepository.instance.create(newC);
                    }
                    ref.invalidate(coursesProvider);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(isEdit ? '保存修改' : '添加'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
