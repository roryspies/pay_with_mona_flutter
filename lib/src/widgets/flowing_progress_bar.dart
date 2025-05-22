import 'package:flutter/material.dart';

class FlowingProgressBar extends StatefulWidget {
  const FlowingProgressBar({
    super.key,
    required this.baseColor,
    required this.flowColor,
    this.duration = const Duration(milliseconds: 1500),
    this.stripeWidth = 0.3,
    this.height = 8.0,
    this.borderRadius = 4.0,
  });

  final Color baseColor;
  final Color flowColor;
  final Duration duration;
  final double stripeWidth;
  final double height;
  final double borderRadius;

  @override
  State<FlowingProgressBar> createState() => _FlowingProgressBarState();
}

class _FlowingProgressBarState extends State<FlowingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth * 2;
          final stripeW = fullWidth * widget.stripeWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                Container(color: widget.baseColor),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final dx =
                        (_animation.value * (fullWidth + stripeW)) - stripeW;

                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Container(
                        width: stripeW,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: widget.flowColor,
                          borderRadius: BorderRadius.circular(
                            32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
