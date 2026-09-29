enum AssignmentStatus {
  notStarted('not_started', '未开始', 0),
  inProgress('in_progress', '进行中', 1),
  completed('completed', '已完成', 2);

  const AssignmentStatus(this.code, this.label, this.order);
  final String code;
  final String label;
  final int order;

  static AssignmentStatus fromCode(String code) {
    return AssignmentStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AssignmentStatus.notStarted,
    );
  }
}

class Assignment {
  final String id;
  final String course;
  final String title;
  final DateTime dueDate;
  final AssignmentStatus status;
  final int progress; // 0-100
  final String? notes;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.course,
    required this.title,
    required this.dueDate,
    required this.status,
    this.progress = 0,
    this.notes,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.create({
    required String id,
    required String course,
    required String title,
    required DateTime dueDate,
    AssignmentStatus status = AssignmentStatus.notStarted,
    int progress = 0,
    String? notes,
  }) {
    final now = DateTime.now();
    return Assignment(
      id: id,
      course: course,
      title: title,
      dueDate: dueDate,
      status: status,
      progress: progress,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Assignment copyWith({
    String? course,
    String? title,
    DateTime? dueDate,
    AssignmentStatus? status,
    int? progress,
    String? notes,
    int? priority,
  }) {
    return Assignment(
      id: id,
      course: course ?? this.course,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'course': course,
        'title': title,
        'due_date': dueDate.millisecondsSinceEpoch,
        'status': status.code,
        'progress': progress,
        'notes': notes,
        'priority': priority,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Assignment.fromMap(Map<String, dynamic> m) {
    return Assignment(
      id: m['id'] as String,
      course: m['course'] as String,
      title: m['title'] as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
      status: AssignmentStatus.fromCode(m['status'] as String? ?? 'not_started'),
      progress: m['progress'] as int? ?? 0,
      notes: m['notes'] as String?,
      priority: m['priority'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != AssignmentStatus.completed;

  String get dueLabel {
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    if (status == AssignmentStatus.completed) return '已完成';
    if (diff.isNegative) {
      if (diff.inHours == 0) return '逾期 ${-diff.inMinutes} 分钟';
      if (diff.inDays == 0) return '逾期 ${-diff.inHours} 小时';
      return '逾期 ${-diff.inDays} 天';
    }
    if (diff.inHours < 24) return '${diff.inHours} 小时后';
    if (diff.inDays == 0) return '今天截止';
    if (diff.inDays == 1) return '明天截止';
    return '${diff.inDays} 天后截止';
  }
}

Assignment? assignmentFromToolArgs(Map<String, dynamic> args) {
  try {
    final course = args['course']?.toString();
    final title = args['title']?.toString();
    final dueStr = args['due_date']?.toString();
    if (course == null || title == null || dueStr == null) return null;
    final due = DateTime.parse(dueStr);
    final statusStr = args['status']?.toString() ?? 'not_started';
    final progress = args['progress'] as int? ?? 0;
    return Assignment.create(
      id: '',
      course: course,
      title: title,
      dueDate: due,
      status: AssignmentStatus.fromCode(statusStr),
      progress: progress,
    );
  } catch (_) {
    return null;
  }
}
