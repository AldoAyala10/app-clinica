import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
          colors: [
            AppTheme.bgGradientTop,
            AppTheme.bgGradientMiddle,
            AppTheme.bgGradientBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: child,
      ),
    );
  }
}
