import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mood_models.dart';
import 'mood_repository.dart';

final moodListProvider = FutureProvider<List<Mood>>((ref) async {
  return MoodRepository.instance.all();
});
