// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_dashboard.dart';
import 'app_theme.dart';
import '../widgets/yps_crest_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 5-second splash transition to HomeDashboard
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeDashboard(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.25,
            colors: [
              Color(0xFF4A000A), // Rich Royal Maroon
              Color(0xFF260005), // Deep Velvet Wine
              Color(0xFF0F0002), // Dark Obsidian
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient Decorative Rings in Background
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: YPSColors.heritageGold.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: YPSColors.primaryMaroon.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Center Branding Column
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official YPS Crest with Golden Ambient Glow
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: YPSColors.heritageGold.withValues(alpha: 0.45),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: YPSColors.heritageGold.withValues(alpha: 0.25),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const YpsCrestWidget(size: 105),
                    )
                        .animate()
                        .fade(duration: 900.ms, curve: Curves.easeOut)
                        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0), duration: 900.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 32),

                    // "Parona X YPS" Headline
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Parona",
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: YPSColors.heritageGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: YPSColors.heritageGold.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              "X",
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: YPSColors.heritageGold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "YPS",
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: YPSColors.heritageGold,
                            shadows: [
                              Shadow(
                                color: YPSColors.heritageGold.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fade(delay: 300.ms, duration: 800.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
                        .shimmer(delay: 1100.ms, duration: 1800.ms, color: Colors.amber.withValues(alpha: 0.35)),

                    const SizedBox(height: 12),

                    // Institution Subtext
                    Text(
                      "Yadavindra Public School",
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.6,
                      ),
                    ).animate().fade(delay: 500.ms, duration: 700.ms),

                    const SizedBox(height: 4),

                    Text(
                      "Patiala",
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: YPSColors.heritageGold.withValues(alpha: 0.9),
                        letterSpacing: 2.4,
                      ),
                    ).animate().fade(delay: 600.ms, duration: 700.ms),

                    const SizedBox(height: 14),

                    // Event Portal Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        "78th Annual Sports Day & Events Portal",
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ).animate().fade(delay: 750.ms, duration: 700.ms),
                  ],
                ),
              ),

              // Bottom 5-second Progress Indicator
              Positioned(
                bottom: 40,
                child: Column(
                  children: [
                    SizedBox(
                      width: 130,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 5),
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 2.5,
                              backgroundColor: Colors.white.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                YPSColors.heritageGold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Preparing Event Experience...",
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ).animate().fade(delay: 900.ms, duration: 600.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
