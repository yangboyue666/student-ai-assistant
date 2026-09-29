import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_indicator.dart';
import 'mood_controller.dart';
import 'mood_models.dart';

/// 心情日历：以月视图展示每天的心情 emoji
class MoodCalendarScreen extends ConsumerStatefulWidget {
  const MoodCalendarScreen({super.key});

  @override
  ConsumerState<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends ConsumerState<MoodCalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodsAsync = ref.watch(moodListProvider);
    final now = DateTime.now();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: '心情日历'),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: appBackgroundGradient)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
              children: [
                // 月份切换
                _buildMonthSwitcher(),
                const SizedBox(height: 16),
                // 星期表头
                _buildWeekdayHeader(),
                const SizedBox(height: 8),
                moodsAsync.when(
                  data: (allMoods) => _buildCalendarGrid(allMoods, now),
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
                const SizedBox(height: 24),
                // 心情统计
                moodsAsync.when(
                  data: (allMoods) => _buildStats(allMoods),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassIconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onTap: _prevMonth,
        ),
        Text(
          '${_currentMonth.year}年 ${_currentMonth.month}月',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        GlassIconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onTap: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      children: weekdays
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(List<Mood> allMoods, DateTime now) {
    // 当月心情映射：日期 -> 当天最后一条心情
    final moodMap = <int, Mood>{};
    for (final m in allMoods) {
      if (m.date.year == _currentMonth.year && m.date.month == _currentMonth.month) {
        final existing = moodMap[m.date.day];
        if (existing == null || m.createdAt.isAfter(existing.createdAt)) {
          moodMap[m.date.day] = m;
        }
      }
    }

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // 周一为一周第一天（1=周一, 7=周日）
    final firstWeekday = firstDay.weekday;
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final cells = <Widget>[];
    // 前置空白
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.expand());
    }
    // 日期格子
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = now.year == _currentMonth.year &&
          now.month == _currentMonth.month &&
          now.day == day;
      final mood = moodMap[day];
      cells.add(_buildDayCell(day, mood, isToday));
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 24,
      backgroundOpacity: 0.08,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
        children: cells,
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildDayCell(int day, Mood? mood, bool isToday) {
    return Container(
      decoration: BoxDecoration(
        color: isToday ? AppColors.accent3.withOpacity(0.20) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(color: AppColors.accent3.withOpacity(0.6), width: 1.5)
            : Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day}日',
            style: TextStyle(
              color: isToday ? AppColors.accent3 : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (mood != null)
            Text(mood.emoji, style: const TextStyle(fontSize: 22))
          else
            const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _buildStats(List<Mood> allMoods) {
    if (allMoods.isEmpty) return const SizedBox.shrink();
    // 统计当月心情数量
    final monthMoods = allMoods
        .where((m) =>
            m.date.year == _currentMonth.year && m.date.month == _currentMonth.month)
        .toList();
    if (monthMoods.isEmpty) return const SizedBox.shrink();

    final emojiCount = <String, int>{};
    for (final m in monthMoods) {
      emojiCount[m.emoji] = (emojiCount[m.emoji] ?? 0) + 1;
    }
    final sorted = emojiCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionIndicator(
          label: '本月心情统计',
          colors: [AppColors.accent2, AppColors.accent1],
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 22,
          backgroundOpacity: 0.08,
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: sorted
                .map((e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 6),
                        Text(
                          '${e.value} 次',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
