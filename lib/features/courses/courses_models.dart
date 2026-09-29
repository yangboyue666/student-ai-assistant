import 'package:flutter/material.dart';

class Course {
  final String id;
  final String name;
  final int weekday; // 1..7
  final int period; // 第几节
  final int weekStart;
  final int weekEnd;
  final String? weekPattern;
  final String? location;
  final String? teacher;
  final int? color;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.name,
    required this.weekday,
    required this.period,
    this.weekStart = 1,
    this.weekEnd = 20,
    this.weekPattern,
    this.location,
    this.teacher,
    this.color,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.create({
    required String id,
    required String name,
    required int weekday,
    required int period,
    int weekStart = 1,
    int weekEnd = 20,
    String? location,
    String? teacher,
    int? color,
    String? note,
  }) {
    final now = DateTime.now();
    return Course(
      id: id,
      name: name,
      weekday: weekday,
      period: period,
      weekStart: weekStart,
      weekEnd: weekEnd,
      location: location,
      teacher: teacher,
      color: color ?? _defaultColorFor(weekday),
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  static int _defaultColorFor(int weekday) {
    // 用 weekday 决定颜色
    const colors = [0xFF7DD3FC, 0xFFA78BFA, 0xFFF0ABFC, 0xFF5EEAD4, 0xFFFBBF24, 0xFFF87171, 0xFF60A5FA];
    return colors[(weekday - 1) % colors.length];
  }

  Course copyWith({
    String? name,
    int? weekday,
    int? period,
    int? weekStart,
    int? weekEnd,
    String? location,
    String? teacher,
    int? color,
    String? note,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      weekday: weekday ?? this.weekday,
      period: period ?? this.period,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      weekPattern: weekPattern ?? this.weekPattern,
      location: location ?? this.location,
      teacher: teacher ?? this.teacher,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'weekday': weekday,
        'period': period,
        'week_start': weekStart,
        'week_end': weekEnd,
        'week_pattern': weekPattern,
        'location': location,
        'teacher': teacher,
        'color': color,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Course.fromMap(Map<String, dynamic> m) {
    return Course(
      id: m['id'] as String,
      name: m['name'] as String,
      weekday: m['weekday'] as int,
      period: m['period'] as int,
      weekStart: m['week_start'] as int? ?? 1,
      weekEnd: m['week_end'] as int? ?? 20,
      weekPattern: m['week_pattern'] as String?,
      location: m['location'] as String?,
      teacher: m['teacher'] as String?,
      color: m['color'] as int?,
      note: m['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
    );
  }

  Color get colorValue => Color(color ?? 0xFF7DD3FC);

  static const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  String get weekdayLabel => weekdayNames[(weekday - 1) % 7];
}

Course? courseFromToolArgs(Map<String, dynamic> args) {
  try {
    final name = args['name']?.toString();
    if (name == null || name.isEmpty) return null;
    final weekday = args['weekday'] as int?;
    final period = args['period'] as int?;
    if (weekday == null || period == null) return null;
    return Course.create(
      id: '',
      name: name,
      weekday: weekday,
      period: period,
      location: args['location']?.toString(),
      teacher: args['teacher']?.toString(),
    );
  } catch (_) {
    return null;
  }
}
