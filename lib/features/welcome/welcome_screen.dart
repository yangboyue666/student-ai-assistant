import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/shimmer_text.dart';
import '../../shared/widgets/animated_indicators.dart';
import '../../shared/widgets/liquid_glass_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  final _welcomeFullText = '欢迎来到你的学生智能助手\n这里没有云端、没有 API\n所有思考都在你的手机里发生';
  String _typed = '';
  bool _showButton = false;
  bool _buttonAnimatingIn = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _startTyping();
  }

  Future<void> _startTyping() async {
    // 短暂延迟营造仪式感
    await Future.delayed(const Duration(milliseconds: 500));
    final full = _welcomeFullText;
    for (int i = 0; i <= full.length; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _typed = full.substring(0, i));
    }
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _buttonAnimatingIn = true;
      _showButton = true;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _onStart() async {
    // 标记首次启动完成
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 全局渐变背景
          Container(
            decoration: const BoxDecoration(gradient: appBackgroundGradient),
          ),
          // 动态光晕背景（多个浮动圆形）
          ..._buildFloatingOrbs(context),
          // 主内容
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // 顶部 icon
                  FadeTransition(
                    opacity: _fadeCtrl,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (ctx, _) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: _LogoBadge(),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 流光标题
                  FadeTransition(
                    opacity: _fadeCtrl,
                    child: const Center(
                      child: ShimmerText(
                        text: '学生智能助手',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _fadeCtrl,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          PulsingDot(size: 6, color: AppColors.accent1),
                          SizedBox(width: 6),
                          Text(
                            '本地优先 · 离线可用 · 免费',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // 打字效果文字
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 28,
                    backgroundOpacity: 0.10,
                    child: SizedBox(
                      height: 110,
                      child: Stack(
                        children: [
                          Text(
                            _typed,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              height: 1.65,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // 打字光标
                          Positioned(
                            bottom: 12,
                            right: 4,
                            child: _typed.length < _welcomeFullText.length
                                ? const PulsingDot(
                                    size: 8,
                                    color: AppColors.accent1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  // 圆形开始按钮
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutCubic,
                      child: _showButton
                          ? LiquidGlassCircleButton(
                              key: const ValueKey('start'),
                              label: '开始',
                              icon: Icons.play_arrow_rounded,
                              size: 130,
                              color: AppColors.accent2,
                              shimmer: true,
                              onTap: _onStart,
                            )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                duration: 700.ms,
                                curve: Curves.easeOutBack,
                              )
                          : const SizedBox(
                              key: ValueKey('placeholder'),
                              height: 130,
                            ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 动态光晕背景
  List<Widget> _buildFloatingOrbs(BuildContext context) {
    return [
      Positioned(
        top: -80,
        left: -60,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (ctx, _) {
            return Transform.translate(
              offset: Offset(_floatAnim.value * 3, 0),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent2.withOpacity(0.35),
                      AppColors.accent2.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: -100,
        right: -80,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (ctx, _) {
            return Transform.translate(
              offset: Offset(-_floatAnim.value * 4, 0),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent1.withOpacity(0.30),
                      AppColors.accent1.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        top: 200,
        right: -50,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (ctx, _) {
            return Transform.translate(
              offset: Offset(0, _floatAnim.value * 2.5),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent3.withOpacity(0.22),
                      AppColors.accent3.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.accent1, AppColors.accent2, AppColors.accent3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent2.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 50,
          ),
        ],
      ),
    );
  }
}
