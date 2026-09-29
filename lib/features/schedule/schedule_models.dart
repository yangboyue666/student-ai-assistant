import 'dart:convert';

class Schedule {
  final String id;
  final String title;
  final DateTime datetime;
  final int remindBefore; // 提前多少秒提醒
  final String? note;
  final bool isDone;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.title,
    required this.datetime,
    this.remindBefore = 600,
    this.note,
    this.isDone = false,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.create({
    required String id,
    required String title,
    required DateTime datetime,
    int remindBefore = 600,
    String? note,
    String? source,
  }) {
    final now = DateTime.now();
    return Schedule(
      id: id,
      title: title,
      datetime: datetime,
      remindBefore: remindBefore,
      note: note,
      source: source,
      createdAt: now,
      updatedAt: now,
    );
  }

  Schedule copyWith({
    String? title,
    DateTime? datetime,
    int? remindBefore,
    String? note,
    bool? isDone,
    String? source,
  }) {
    return Schedule(
      id: id,
      title: title ?? this.title,
      datetime: datetime ?? this.datetime,
      remindBefore: remindBefore ?? this.remindBefore,
      note: note ?? this.note,
      isDone: isDone ?? this.isDone,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'datetime': datetime.millisecondsSinceEpoch,
        'remind_before': remindBefore,
        'note': note,
        'is_done': isDone ? 1 : 0,
        'source': source,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Schedule.fromMap(Map<String, dynamic> m) {
    return Schedule(
      id: m['id'] as String,
      title: m['title'] as String,
      datetime: DateTime.fromMillisecondsSinceEpoch(m['datetime'] as int),
      remindBefore: m['remind_before'] as int? ?? 600,
      note: m['note'] as String?,
      isDone: (m['is_done'] as int?) == 1,
      source: m['source'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }

  String get shortTime {
    final h = datetime.hour.toString().padLeft(2, '0');
    final m = datetime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get relativeDescription {
    final now = DateTime.now();
    final diff = datetime.difference(now);
    if (diff.isNegative) {
      return '已过 ${_formatDuration(-diff)}';
    }
    if (datetime.day == now.day && datetime.month == now.month && datetime.year == now.year) {
      return '今天 $shortTime';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (datetime.day == tomorrow.day && datetime.month == tomorrow.month) {
      return '明天 $shortTime';
    }
    return '${datetime.month}/${datetime.day} $shortTime';
  }

  String _formatDuration(Duration d) {
    if (d.inHours < 1) return '${d.inMinutes} 分钟';
    if (d.inDays < 1) return '${d.inHours} 小时';
    return '${d.inDays} 天';
  }
}

/// 工具调用结果转 Schedule（用于 AI 函数调用）
Schedule? scheduleFromToolArgs(Map<String, dynamic> args) {
  try {
    final title = args['title']?.toString();
    final dtStr = args['datetime']?.toString();
    if (title == null || dtStr == null) return null;
    final dt = DateTime.parse(dtStr);
    final remind = args['remind_before'] as int? ?? 600;
    final note = args['note']?.toString();
    return Schedule.create(
      id: '',
      title: title,
      datetime: dt,
      remindBefore: remind,
      note: note,
      source: 'ai',
    );
  } catch (_) {
    return null;
  }
}

// 防止 json_decode 警告
final _unusedJson = jsonEncode({});
