import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// 呼吸/脉动圆点（Pulsing Dot）
/// AnimationController + ScaleTransition 实现
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    this.size = 12,
    this.color = AppColors.accent1,
    this.duration = const Duration(milliseconds: 1400),
    this.minScale = 0.7,
    this.maxScale = 1.3,
    this.glow = true,
  });

  final double size;
  final Color color;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool glow;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        final scale =
            widget.minScale + (widget.maxScale - widget.minScale) * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: widget.glow
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.6 * (1 - t * 0.6)),
                        blurRadius: widget.size * 1.4,
                        spreadRadius: widget.size * 0.4,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// 环形进度条（带动画扫过效果）—— SweepGradient + 旋转
class AnimatedCircularProgress extends StatefulWidget {
  const AnimatedCircularProgress({
    super.key,
    this.size = 48,
    this.strokeWidth = 4.5,
    this.progress = 0.65,
    this.color = AppColors.accent1,
    this.secondaryColor = AppColors.accent3,
    this.duration = const Duration(seconds: 2),
    this.spin = true,
    this.child,
  });

  final double size;
  final double strokeWidth;
  final double progress;
  final Color color;
  final Color secondaryColor;
  final Duration duration;
  final bool spin;
  final Widget? child;

  @override
  State<AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _spinController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressAnim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ))..addListener(() => setState(() {}));
    _progressController.forward();

    if (widget.spin) {
      _spinController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      )..repeat();
    } else {
      _spinController = AnimationController(vsync: this, duration: Duration.zero);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 底环
          CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(
              progress: 1.0,
              strokeWidth: widget.strokeWidth,
              color: Colors.white.withOpacity(0.08),
              startAngle: -math.pi / 2,
            ),
          ),
          // 进度环（带旋转扫光）
          AnimatedBuilder(
            animation: Listenable.merge([_progressAnim, _spinController]),
            builder: (context, child) {
              return Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _SweepRingPainter(
                    progress: _progressAnim.value,
                    strokeWidth: widget.strokeWidth,
                    color: widget.color,
                    secondaryColor: widget.secondaryColor,
                  ),
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.startAngle,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _SweepRingPainter extends CustomPainter {
  const _SweepRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.secondaryColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          color.withOpacity(0.0),
          color,
          secondaryColor,
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 0.85, 1.0],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepRingPainter old) =>
      old.progress != progress;
}

/// 波形/条形动效（Wave / Bar，类似音频频谱）
class WaveIndicator extends StatefulWidget {
  const WaveIndicator({
    super.key,
    this.barCount = 5,
    this.height = 28,
    this.barWidth = 4,
    this.spacing = 3,
    this.color = AppColors.accent1,
    this.secondaryColor = AppColors.accent3,
    this.duration = const Duration(milliseconds: 900),
    this.amplitude = 1.0,
  });

  final int barCount;
  final double height;
  final double barWidth;
  final double spacing;
  final Color color;
  final Color secondaryColor;
  final Duration duration;
  final double amplitude;

  @override
  State<WaveIndicator> createState() => _WaveIndicatorState();
}

class _WaveIndicatorState extends State<WaveIndicator>
    with TickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(
            widget.barCount * (widget.barWidth + widget.spacing) -
                widget.spacing,
            widget.height,
          ),
          painter: _WavePainter(
            progress: _controller.value,
            barCount: widget.barCount,
            barWidth: widget.barWidth,
            spacing: widget.spacing,
            color: widget.color,
            secondaryColor: widget.secondaryColor,
            amplitude: widget.amplitude,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.barCount,
    required this.barWidth,
    required this.spacing,
    required this.color,
    required this.secondaryColor,
    required this.amplitude,
  });

  final double progress;
  final int barCount;
  final double barWidth;
  final double spacing;
  final Color color;
  final Color secondaryColor;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final totalWidth = barCount * (barWidth + spacing) - spacing;
    final startX = (size.width - totalWidth) / 2;
    for (int i = 0; i < barCount; i++) {
      // 每根 bar 不同相位
      final phase = i / barCount * 2 * math.pi;
      final t = (math.sin(progress * 2 * math.pi + phase) + 1) / 2;
      final eased = Curves.easeInOutCubic.transform(t);
      final barH = (size.height * 0.25 + size.height * 0.75 * eased * amplitude)
          .clamp(barWidth * 1.5, size.height);
      final x = startX + i * (barWidth + spacing);
      final y = (size.height - barH) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        Radius.circular(barWidth / 2),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, secondaryColor],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => true;
}
