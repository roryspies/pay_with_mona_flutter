import 'package:flutter/material.dart';

class FlowingProgressBar extends StatelessWidget {
  const FlowingProgressBar({
    super.key,
    required this.flowAnimation,
    required this.baseColor,
    required this.flowColor,
  });

  final Animation<double> flowAnimation;
  final Color baseColor;
  final Color flowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedBuilder(
            animation: flowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      baseColor,
                      flowColor,
                      flowColor,
                      baseColor,
                    ],
                    stops: [
                      0.0,
                      (flowAnimation.value - 0.2).clamp(0.0, 1.0),
                      (flowAnimation.value).clamp(0.0, 1.0),
                      (flowAnimation.value + 0.2).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
