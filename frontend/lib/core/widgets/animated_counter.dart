import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.count,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: count),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$value',
          style: style ?? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
