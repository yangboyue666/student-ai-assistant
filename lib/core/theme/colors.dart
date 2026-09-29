import 'package:flutter/material.dart';

/// 全局色系：参考截图，深紫蓝渐变底色 + 流光高光
class AppColors {
  AppColors._();

  // 主渐变色（背景使用）
  static const Color bgStart = Color(0xFF1A0B3D);   // 深紫
  static const Color bgMid = Color(0xFF2D1B5E);    // 中紫
  static const Color bgEnd = Color(0xFF0F1A4A);    // 深蓝

  // 流光色（标题、进度条、特效）
  static const Color accent1 = Color(0xFF7DD3FC);  // 浅蓝
  static const Color accent2 = Color(0xFFA78BFA);  // 紫
  static const Color accent3 = Color(0xFFF0ABFC);  // 粉紫
  static const Color accent4 = Color(0xFF5EEAD4);  // 薄荷

  // 玻璃卡片基础色（半透明白）
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color glassLight = Color(0x33FFFFFF);  // 20% 白
  static const Color glassBorder = Color(0x55FFFFFF);  // ~33% 白
  static const Color glassShadow = Color(0x33000000);

  // 文本
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

  // 状态
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFACC15);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // 模块强调色（4 个入口）
  static const Color moduleChat = Color(0xFF7DD3FC);    // 对话框
  static const Color moduleSchedule = Color(0xFFA78BFA); // 日程
  static const Color moduleAssignment = Color(0xFFF0ABFC); // 作业
  static const Color moduleCourse = Color(0xFF5EEAD4);  // 课程表
}

/// 全局线性渐变（背景使用）
const LinearGradient appBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppColors.bgStart,
    AppColors.bgMid,
    AppColors.bgEnd,
  ],
);

/// 流光强调色渐变（标题、按钮）
const LinearGradient accentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppColors.accent1,
    AppColors.accent2,
    AppColors.accent3,
  ],
);

/// 横向流光扫过渐变（流光文字特效使用）
LinearGradient shimmerGradient({
  double progress = 0.0,
  double width = 0.4,
}) {
  final start = (progress - width).clamp(0.0, 1.0);
  final end = (progress + width).clamp(0.0, 1.0);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
    colors: [
      AppColors.textPrimary,
      AppColors.accent1,
      AppColors.accent3,
      AppColors.textPrimary,
    ],
    stops: [
      (start - 0.1).clamp(0.0, 1.0),
      start,
      end,
      (end + 0.1).clamp(0.0, 1.0),
    ],
  );
}
