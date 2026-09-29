import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'glass_card.dart';
import 'shimmer_text.dart';

/// 流光圆形主按钮（开始按钮 / 主要 CTA）
class LiquidGlassCircleButton extends StatefulWidget {
  const LiquidGlassCircleButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = 130,
    this.icon = Icons.play_arrow_rounded,
    this.color = AppColors.accent2,
    this.shimmer = false,
    this.durationMs = 800,
  });

  final String label;
  final VoidCallback onTap;
  final double size;
  final IconData icon;
  final Color color;
  final bool shimmer;
  final int durationMs;

  @override
  State<LiquidGlassCircleButton> createState() =>
      _LiquidGlassCircleButtonState();
}

class _LiquidGlassCircleButtonState extends State<LiquidGlassCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(begin: 0.45, end: 0.75)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: ScaleTransition(
        scale: _pressed ? const AlwaysStoppedAnimation(0.96) : _scaleAnim,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.92),
                    AppColors.accent3.withOpacity(0.85),
                    widget.color.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(_glowAnim.value),
                    blurRadius: widget.size * 0.35,
                    spreadRadius: widget.size * 0.06,
                  ),
                  BoxShadow(
                    color: AppColors.accent3.withOpacity(0.25),
                    blurRadius: widget.size * 0.6,
                    spreadRadius: widget.size * 0.02,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.4,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: widget.size * 0.30),
                        const SizedBox(height: 6),
                        widget.shimmer
                            ? ShimmerText(
                                text: widget.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.size * 0.115,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                                duration: const Duration(seconds: 3),
                                colors: const [
                                  Colors.white,
                                  AppColors.accent1,
                                  Colors.white,
                                ],
                              )
                            : Text(
                                widget.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.size * 0.115,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(0, 1.5),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
