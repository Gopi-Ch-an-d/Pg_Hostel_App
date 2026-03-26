import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final Color? iconColor;

  const AppLogo({
    super.key,
    this.size = 56,
    this.showText = false,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color ?? AppTheme.primary,
                borderRadius: BorderRadius.circular(size * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? AppTheme.primary).withOpacity(0.3),
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.1),
                  ),
                ],
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: iconColor ?? Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 12),
            const Text(
              'PG Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
