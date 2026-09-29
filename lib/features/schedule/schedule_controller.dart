import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'schedule_models.dart';
import 'schedule_repository.dart';

enum ScheduleFilter { today, thisWeek, all, upcoming }

final scheduleFilterProvider =
    StateProvider<ScheduleFilter>((ref) => ScheduleFilter.upcoming);

final scheduleListProvider =
    FutureProvider.family<List<Schedule>, ScheduleFilter>((ref, filter) async {
  switch (filter) {
    case ScheduleFilter.today:
      return ScheduleRepository.instance.byDay(DateTime.now());
    case ScheduleFilter.thisWeek:
      return ScheduleRepository.instance.thisWeek();
    case ScheduleFilter.all:
      return ScheduleRepository.instance.all();
    case ScheduleFilter.upcoming:
      return ScheduleRepository.instance.all(onlyUpcoming: true);
  }
});

/// 通过 AI 工具调用创建日程
final createScheduleFromToolCallProvider =
    FutureProvider.family<Schedule?, Map<String, dynamic>>((ref, args) async {
  final s = scheduleFromToolArgs(args);
  if (s == null) return null;
  final created = await ScheduleRepository.instance.create(s);
  // 刷新列表
  ref.invalidate(scheduleListProvider);
  return created;
});
