import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'glass_card.dart';

/// 玻璃拟态顶部导航栏
/// 返回按钮为带边框的圆形按钮（参考截图）
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions = const [],
    this.leading,
    this.centerTitle = true,
    this.height = 70,
    this.showBack = true,
    this.backgroundColor,
    this.titleWidget,
  });

  final String? title;
  final List<Widget> actions;
  final Widget? leading;
  final bool centerTitle;
  final double height;
  final bool showBack;
  final Color? backgroundColor;
  final Widget? titleWidget;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final modalRoute = ModalRoute.of(context);
    final canPop = modalRoute?.canPop ?? false;
    final hasLeading = leading != null || (showBack && canPop);

    Widget? leadingWidget = leading;
    if (hasLeading && leadingWidget == null) {
      leadingWidget = _GlassBackButton(onTap: () {
        if (canPop) {
          Navigator.maybePop(context);
        }
      });
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          borderRadius: 24,
          blurSigma: 18,
          backgroundOpacity: 0.08,
          borderOpacity: 0.18,
          child: SizedBox(
            height: height - 16,
            child: NavigationToolbar(
              leading: leadingWidget,
              middle: titleWidget ??
                  (title == null
                      ? null
                      : Text(
                          title!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        )),
              centerMiddle: centerTitle,
              trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassIconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      onTap: onTap,
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.backgroundOpacity = 0.06,
    this.borderOpacity = 0.18,
    this.iconColor,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final double backgroundOpacity;
  final double borderOpacity;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return _GlassIconButton(
      icon: icon,
      onTap: onTap,
      size: size,
      backgroundOpacity: backgroundOpacity,
      borderOpacity: borderOpacity,
      iconColor: iconColor,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    this.onTap,
    this.size = 42,
    this.backgroundOpacity = 0.06,
    this.borderOpacity = 0.18,
    this.iconColor,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final double backgroundOpacity;
  final double borderOpacity;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(backgroundOpacity),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(
              color: iconColor ?? AppColors.textPrimary,
              size: size * 0.5,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
