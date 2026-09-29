import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// 液态玻璃卡片：
/// - BackdropFilter + ImageFilter.blur(20) 实现毛玻璃
/// - 半透明渐变层
/// - 白色高光边框
/// - 大圆角（24~32）
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 28,
    this.blurSigma = 20,
    this.borderOpacity = 0.22,
    this.backgroundOpacity = 0.10,
    this.gradient,
    this.onTap,
    this.shadow = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final double borderOpacity;
  final double backgroundOpacity;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool shadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(borderRadius);
    final border = Border.all(
      color: Colors.white.withOpacity(borderOpacity),
      width: 1.2,
    );
    final cardBoxShadow = shadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, -1),
              spreadRadius: 0,
            ),
          ]
        : null;

    Widget inner = Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(radius),
        border: border,
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(backgroundOpacity),
                Colors.white.withOpacity(backgroundOpacity * 0.55),
              ],
            ),
        boxShadow: cardBoxShadow,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    // 顶层叠加毛玻璃模糊层
    inner = ClipRRect(
      borderRadius: BorderRadius.all(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: inner,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: inner,
      );
    }
    return inner;
  }
}
