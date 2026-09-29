/// 心情记录
class Mood {
  final String id;
  final String emoji;
  final String? content;
  final DateTime date; // 记录的日期（精确到天）
  final DateTime createdAt;

  Mood({
    required this.id,
    required this.emoji,
    this.content,
    required this.date,
    required this.createdAt,
  });

  Mood.create({
    required String id,
    required String emoji,
    String? content,
    required DateTime date,
  })  : id = id,
        emoji = emoji,
        content = content,
        date = date,
        createdAt = DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'emoji': emoji,
        'content': content,
        'date': DateTime(date.year, date.month, date.day)
            .millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Mood.fromMap(Map<String, dynamic> m) {
    return Mood(
      id: m['id'] as String,
      emoji: m['emoji'] as String,
      content: m['content'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  String get dayLabel => '${date.day}日';
}

/// 可选的心情 emoji 列表
class MoodEmojis {
  MoodEmojis._();
  static const List<String> all = [
    '😄', '😊', '🥰', '😎', '🤔',
    '😴', '😢', '😡', '😱', '🥳',
    '😇', '🤗', '😋', '🤯', '💪',
  ];
}
