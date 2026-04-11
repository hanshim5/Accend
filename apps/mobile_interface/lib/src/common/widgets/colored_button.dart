import 'package:flutter/material.dart';

class ColoredButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final dynamic firstColor;
  final dynamic secondColor;
  final dynamic shadow;
  final double? height;

  const ColoredButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.firstColor,
    required this.secondColor,
    required this.shadow,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? 180;
    final isCompact = resolvedHeight < 160;
    final titleSize = isCompact ? 20.0 : 22.0;
    final subtitleSize = isCompact ? 14.0 : 16.0;
    final circleSize = isCompact ? 78.0 : 100.0;
    final iconSize = isCompact ? 46.0 : 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: resolvedHeight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 22 : 25),
          gradient: LinearGradient(
            colors: [
              Color(firstColor),
              Color(secondColor),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(shadow).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: subtitleSize,
                    ),
                  ),
                ],
              ),
            ),

            /// Icon circle
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}