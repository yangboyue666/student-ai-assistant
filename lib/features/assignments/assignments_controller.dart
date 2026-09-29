import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'assignments_models.dart';
import 'assignments_repository.dart';

final assignmentFilterProvider =
    StateProvider<String>((ref) => 'all'); // all / not_started / in_progress / completed

final assignmentCourseFilterProvider = StateProvider<String?>((ref) => null);

final assignmentListProvider =
    FutureProvider<List<Assignment>>((ref) async {
  final statusFilter = ref.watch(assignmentFilterProvider);
  final courseFilter = ref.watch(assignmentCourseFilterProvider);
  return AssignmentRepository.instance.all(
    statusFilter: statusFilter,
    courseFilter: courseFilter,
  );
});

final assignmentCoursesProvider =
    FutureProvider<List<String>>((ref) async {
  ref.watch(assignmentListProvider);
  return AssignmentRepository.instance.courses();
});
