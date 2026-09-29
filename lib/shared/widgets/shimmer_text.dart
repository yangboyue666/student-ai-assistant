import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import '../../core/theme/colors.dart';

/// 流光文字特效：标题或重要文本上的渐变扫光动画
class ShimmerText extends StatefulWidget {
  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 4),
    this.colors = const [
      AppColors.textPrimary,
      AppColors.accent1,
      AppColors.accent3,
      AppColors.textPrimary,
    ],
    this.bleed = 0.55,
  });

  final String text;
  final TextStyle? style;
  final Duration duration;
  final List<Color> colors;
  final double bleed;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // 平滑来回扫光
        final sweep01 = Curves.easeInOutCubic.transform(t);
        return ShaderMask(
          shaderCallback: (bounds) {
            final w = bounds.width;
            final sweep = w * (1 + widget.bleed * 2);
            final dx = -sweep / 2 + sweep01 * (w + sweep);
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: widget.colors,
              stops: const [0.0, 0.35, 0.65, 1.0],
              transform: GradientTranslation(dx),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            widget.text,
            style: defaultStyle.copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        );
      },
    );
  }
}

/// 渐变平移变换：把渐变在 x 轴上平移
class GradientTranslation extends GradientTransform {
  const GradientTranslation(this.dx);
  final double dx;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// 渐变文字（静态渐变）
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = accentGradient,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ??
        const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: defaultStyle.copyWith(color: Colors.white),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
