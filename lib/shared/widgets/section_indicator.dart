import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// 模块标题前的渐变小圆角矩形指示条（截图中的 "| 模块名"）
class SectionIndicator extends StatelessWidget {
  const SectionIndicator({
    super.key,
    required this.label,
    this.colors = const [
      AppColors.accent1,
      AppColors.accent2,
    ],
    this.width = 5,
    this.height = 22,
    this.radius = 3,
    this.style,
  });

  final String label;
  final List<Color> colors;
  final double width;
  final double height;
  final double radius;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: style ??
              const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }
}
