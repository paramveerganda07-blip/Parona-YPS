// lib/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../screens/app_theme.dart'; // Adjust import path if needed

class GlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = wrapContent,
    this.padding = const EdgeInsets.all(20.0),
  });

  static const double wrapContent = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height == wrapContent ? null : height,
      padding: padding,
      decoration: BoxDecoration(
        color: YPSColors.surfaceWhite, // Solid white background
        borderRadius: BorderRadius.circular(16.0), // Cleaner, tighter radius
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: YPSColors.primaryMaroon.withValues(alpha: 0.06), // Soft maroon drop shadow
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}