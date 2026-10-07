import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta visual de app-clinica; no administra datos ni sesión.
class ClinicCard extends StatelessWidget {
  const ClinicCard({super.key, required this.child, this.featured = false});
  final Widget child;
  final bool featured;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: featured ? null : Colors.white,
          gradient: featured
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryBlue, AppTheme.primaryDarkBlue],
                )
              : null,
          borderRadius: BorderRadius.circular(featured ? 24 : 20),
          boxShadow: featured ? AppTheme.buttonShadow : AppTheme.softShadow,
          border: featured ? null : Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: child,
      );
}

class ClinicBadge extends StatelessWidget {
  const ClinicBadge({super.key, required this.label, this.inverse = false});
  final String label;
  final bool inverse;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: inverse ? const Color(0x33FFFFFF) : AppTheme.successBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inverse ? Colors.white : AppTheme.successGreen)),
      );
}
