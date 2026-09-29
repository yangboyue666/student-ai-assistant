import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import 'mood_calendar_screen.dart';
import 'mood_controller.dart';
import 'mood_models.dart';
import 'mood_repository.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  String _selectedEmoji = MoodEmojis.all.first;
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final mood = Mood.create(
        id: '',
        emoji: _selectedEmoji,
        content: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        date: DateTime.now(),
      );
      await MoodRepository.instance.create(mood);
      _contentCtrl.clear();
      setState(() => _selectedEmoji = MoodEmojis.all.first);
      ref.invalidate(moodListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('心情已记录 $_selectedEmoji'),
            backgroundColor: AppColors.success.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodsAsync = ref.watch(moodListProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: '心情日记',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GlassIconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MoodCalendarScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
              children: [
                // 记录心情
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SectionIndicator(
                    label: '记录今天的心情',
                    colors: [AppColors.accent3, AppColors.accent1],
                  ),
                ),
                _buildEmojiPicker(),
                const SizedBox(height: 14),
                _buildContentInput(),
                const SizedBox(height: 14),
                _buildSaveButton(),
                const SizedBox(height: 28),

                // 最近心情
                SectionIndicator(
                  label: '最近的心情',
                  colors: [AppColors.accent2, AppColors.accent3],
                ),
                const SizedBox(height: 14),
                moodsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return const _EmptyHint();
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < list.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MoodCard(mood: list[i]).animate().fadeIn(
                                  delay: Duration(milliseconds: i * 60),
                                  duration: const Duration(milliseconds: 350),
                                ).slideY(
                                  begin: 0.08,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.accent1),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('加载失败: $e', style: const TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      backgroundOpacity: 0.10,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: MoodEmojis.all.map((e) {
          final selected = _selectedEmoji == e;
          return GestureDetector(
            onTap: () => setState(() => _selectedEmoji = e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent3.withOpacity(0.35)
                    : Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.accent3
                      : Colors.white.withOpacity(0.12),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.accent3.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(e, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentInput() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 20,
      backgroundOpacity: 0.08,
      child: TextField(
        controller: _contentCtrl,
        maxLines: 3,
        minLines: 1,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: const InputDecoration(
          hintText: '写点什么吧（可选）...',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: 20,
        backgroundOpacity: 0.0,
        gradient: const LinearGradient(
          colors: [AppColors.accent3, AppColors.accent1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        onTap: _saving ? null : _save,
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  '保存心情',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MoodCard extends ConsumerWidget {
  const _MoodCard({required this.mood});
  final Mood mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      backgroundOpacity: 0.10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(mood.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mood.date.month}月${mood.date.day}日 ${mood.date.hour.toString().padLeft(2, '0')}:${mood.date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (mood.content != null && mood.content!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mood.content!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GlassIconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            size: 36,
            onTap: () async {
              await MoodRepository.instance.delete(mood.id);
              ref.invalidate(moodListProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32),
      borderRadius: 24,
      backgroundOpacity: 0.08,
      child: const Column(
        children: [
          Text('🌸', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            '还没有心情记录\n选一个 emoji 开始记录吧',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
