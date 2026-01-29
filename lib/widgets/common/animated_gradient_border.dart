import 'package:flutter/material.dart';

class SimpleGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color innerColor;

  const SimpleGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.borderWidth = 2.5,
    this.innerColor = const Color(0xFF1A2235),
  });

  @override
  State<SimpleGradientBorder> createState() => _SimpleGradientBorderState();
}

class _SimpleGradientBorderState extends State<SimpleGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        final offset = _controller.value;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + offset * 2, -1.0),
              end: Alignment(1.0 + offset * 2, 1.0),
              colors: const [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
                Color(0xFF6366F1),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              tileMode: TileMode.mirror,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: Container(
            decoration: BoxDecoration(
              color: widget.innerColor,
              borderRadius: BorderRadius.circular(
                widget.borderRadius - widget.borderWidth,
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Keep GlowingGradientBorder for compatibility
class GlowingGradientBorder extends SimpleGradientBorder {
  const GlowingGradientBorder({
    super.key,
    required super.child,
    super.borderRadius = 30,
    super.borderWidth = 2.5,
    super.innerColor = const Color(0xFF1A2235),
  });
}