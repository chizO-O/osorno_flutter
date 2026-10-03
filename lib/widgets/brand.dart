import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared SkinWais brand mark so the login screen and in-app app bar
/// always use the exact same visual identity.
class SkinWaisLogo extends StatelessWidget {
  final double size;
  const SkinWaisLogo({super.key, this.size = 76});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.green.withOpacity(0.14)),
      ),
      child: Icon(
        Icons.spa_outlined,
        size: size * 0.47,
        color: AppColors.green,
      ),
    );
  }
}

class SkinWaisWordmark extends StatelessWidget {
  final double fontSize;
  const SkinWaisWordmark({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Text(
      'SkinWais',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: AppColors.greenDark,
        letterSpacing: -0.9,
        height: 1,
      ),
    );
  }
}
