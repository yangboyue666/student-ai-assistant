import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'courses_models.dart';
import 'courses_repository.dart';
import '../images/image_service.dart';

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return CourseRepository.instance.all();
});

final scheduleImagesProvider =
    FutureProvider<List<ImageRecord>>((ref) async {
  return CourseRepository.instance.scheduleImages();
});
