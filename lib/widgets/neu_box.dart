import 'package:flutter/material.dart';

class NeuColors {
  static Color background(bool isDark) =>
      isDark ? const Color(0xFF1E2228) : const Color(0xFFE8EDF2);
  static Color shadowDark(bool isDark) =>
      isDark ? const Color(0xFF13161C) : const Color(0xFFA8B8CA);
  static Color shadowLight(bool isDark) =>
      isDark ? const Color(0xFF2D3442) : const Color(0xFFFFFFFF);
  static const primary = Color(0xFF6C63FF);
  static const success = Color(0xFF48BB78);
  static Color textPrimary(bool isDark) =>
      isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748);
  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF718096);
}

enum NeuStyle { raised, pressed }

class NeuBox extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final BorderRadius? customRadius;
  final NeuStyle style;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final double depth;

  const NeuBox({
    super.key,
    this.child,
    this.borderRadius = 16,
    this.customRadius,
    this.style = NeuStyle.raised,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.depth = 6,
  });

  BorderRadius get _radius =>
      customRadius ?? BorderRadius.circular(borderRadius);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? NeuColors.background(isDark);
    final dk = NeuColors.shadowDark(isDark);
    final lt = NeuColors.shadowLight(isDark);

    final BoxDecoration decoration;
    if (style == NeuStyle.raised) {
      decoration = BoxDecoration(
        color: bg,
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
              color: dk,
              offset: Offset(depth, depth),
              blurRadius: depth * 2),
          BoxShadow(
              color: lt,
              offset: Offset(-depth, -depth),
              blurRadius: depth * 2),
        ],
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: _radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dk.withValues(alpha: isDark ? 0.6 : 0.4),
            bg,
            lt.withValues(alpha: isDark ? 0.12 : 0.9),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
              color: dk.withValues(alpha: 0.8),
              offset: Offset(depth * 0.5, depth * 0.5),
              blurRadius: depth,
              spreadRadius: -(depth * 0.3)),
          BoxShadow(
              color: lt,
              offset: Offset(-depth * 0.5, -depth * 0.5),
              blurRadius: depth,
              spreadRadius: -(depth * 0.3)),
        ],
      );
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool isActive;
  final double depth;

  const NeuButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.isActive = false,
    this.depth = 5,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDown = _pressed || widget.isActive;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: NeuBox(
        style: isDown ? NeuStyle.pressed : NeuStyle.raised,
        borderRadius: widget.borderRadius,
        padding: widget.padding,
        color: widget.color,
        depth: widget.depth,
        child: widget.child,
      ),
    );
  }
}
