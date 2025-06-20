import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainerWidget extends StatefulWidget {
  const GlassContainerWidget({
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.sigmaX,
    this.sigmaY,
    this.alpha = 0.16,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? sigmaX;
  final double? sigmaY;
  final double alpha;

  @override
  State<GlassContainerWidget> createState() => _GlassContainerWidgetState();
}

class _GlassContainerWidgetState extends State<GlassContainerWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.sigmaX ?? 10,
            sigmaY: widget.sigmaY ?? 5,
          ),
          blendMode: BlendMode.srcOver,
          child: Container(
            height: widget.height,
            padding: widget.padding,
            margin: widget.margin,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: widget.alpha,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                width: 1,
                color: Colors.grey.withValues(alpha: .5),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
