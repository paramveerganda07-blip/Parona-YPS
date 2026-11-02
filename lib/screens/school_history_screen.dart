// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/app_theme.dart';
import '../screens/glass_card.dart';

class SchoolHistoryScreen extends StatelessWidget {
  const SchoolHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 450.0,
            stretch: true,
            pinned: true,
            backgroundColor: YPSColors.primaryMaroon,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [YPSColors.primaryMaroon, Color(0xFF3B000B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.account_balance,
                        size: 100,
                        color: YPSColors.heritageGold.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          YPSColors.primaryMaroon,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    child: Hero(
                      tag: 'yps_legacy_logo',
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: YPSColors.heritageGold, width: 3),
                              ),
                              child: const Icon(Icons.account_balance, color: YPSColors.primaryMaroon, size: 40),
                            ),
                            const SizedBox(height: 16),
                            const Text("Yadavindra", style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text("Public School", style: TextStyle(fontFamily: 'SF Pro Display', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            const Text("PATIALA • EST. 1948", style: TextStyle(color: YPSColors.heritageGold, letterSpacing: 3, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GlassCard(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome, color: YPSColors.heritageGold, size: 30),
                        SizedBox(height: 12),
                        Text("Vidya • Vinay • Veerta", style: TextStyle(color: YPSColors.primaryMaroon, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                        SizedBox(height: 8),
                        Text("Knowledge • Humility • Valour", style: TextStyle(color: YPSColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 40),
                  Text("Our Royal Legacy", style: YPSTypography.cinematicHeader.copyWith(fontSize: 24)).animate().fade(delay: 300.ms),
                  const SizedBox(height: 16),
                  const Text(
                    "Founded in 1948 by the late H.H. Maharaja Yadavindra Singh of Patiala, YPS was established to provide a premier public school education to the youth of independent India. Over the decades, it has stood as a beacon of academic excellence, discipline, and holistic development.",
                    style: TextStyle(color: YPSColors.textPrimary, fontSize: 16, height: 1.6),
                  ).animate().fade(delay: 400.ms),

                  const SizedBox(height: 40),
                  Text("Historical Milestones", style: YPSTypography.cinematicHeader.copyWith(fontSize: 24)).animate().fade(delay: 500.ms),
                  const SizedBox(height: 24),

                  _buildHeritageTimeline("1948", "Foundation", "School inaugurated by Maharaja Yadavindra Singh.").animate().fade(delay: 600.ms),
                  _buildHeritageTimeline("1950", "First Batch", "The first batch of students graduates, setting the standard for excellence.").animate().fade(delay: 700.ms),
                  _buildHeritageTimeline("Present", "Modern Era", "Equipped with state-of-the-art facilities while maintaining rich heritage traditions.", isLast: true).animate().fade(delay: 800.ms),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeritageTimeline(String year, String title, String description, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: YPSColors.heritageGold, width: 3), shape: BoxShape.circle),
                child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: YPSColors.primaryMaroon, shape: BoxShape.circle))),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: YPSColors.heritageGold.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(year, style: const TextStyle(color: YPSColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(color: YPSColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(color: YPSColors.textSecondary, fontSize: 15)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}