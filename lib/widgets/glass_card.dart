import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

/// Modern glass card widget dengan glassmorphism effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final LinearGradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16.0,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.borderColor,
    this.borderWidth = 1.5,
    this.padding,
    this.margin,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GlassmorphicContainer(
        width: width,
        height: height,
        borderRadius: borderRadius,
        blur: blur,
        alignment: Alignment.center,
        border: borderWidth,
        linearGradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(opacity * 0.5),
              ],
            ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            borderColor?.withOpacity(0.5) ?? Colors.white.withOpacity(0.5),
            borderColor?.withOpacity(0.2) ?? Colors.white.withOpacity(0.2),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}

/// Glass card dengan custom gradient
class GlassCardGradient extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final List<Color> gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCardGradient({
    super.key,
    required this.child,
    required this.gradientColors,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      height: height,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      child: child,
    );
  }
}

/// Glass card dengan blur effect yang lebih kuat
class GlassCardBlur extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCardBlur({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      height: height,
      borderRadius: borderRadius,
      blur: 40.0,
      opacity: 0.15,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}

/// Glass card untuk dark theme
class GlassCardDark extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCardDark({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GlassmorphicContainer(
        width: width,
        height: height,
        borderRadius: borderRadius,
        blur: 20.0,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.15),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}

/// Glass card dengan hover effect
class GlassCardHover extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCardHover({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  State<GlassCardHover> createState() => _GlassCardHoverState();
}

class _GlassCardHoverState extends State<GlassCardHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          child: GlassCard(
            width: widget.width,
            height: widget.height,
            borderRadius: widget.borderRadius,
            padding: widget.padding,
            margin: widget.margin,
            opacity: _isHovered ? 0.15 : 0.1,
            blur: _isHovered ? 25.0 : 20.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
