// lib/widgets/quick_actions_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../screens/app_theme.dart';
import '../screens/glass_card.dart';
import '../screens/home_dashboard.dart';
import '../screens/events_screen.dart';
import '../screens/achievers_screen.dart';
import '../screens/parking_screen.dart';
import '../screens/schedules_screen.dart';
import '../screens/medical_screen.dart';
import '../screens/feedback_screen.dart';

class QuickActionsBottomBar extends StatelessWidget {
  final String? eventId;
  final String? currentScreen; // 'events', 'achievers', 'parking', 'schedules', 'medical', 'feedback', 'home'

  const QuickActionsBottomBar({
    super.key,
    this.eventId,
    this.currentScreen,
  });

  @override
  Widget build(BuildContext context) {
    final currentEventId = (eventId != null && eventId!.isNotEmpty && eventId != "0")
        ? eventId!
        : "1";

    final actions = [
      {
        'id': 'events',
        'icon': Icons.event_available_outlined,
        'label': 'Events Page',
        'subtitle': 'Details & Photos',
      },
      {
        'id': 'achievers',
        'icon': Icons.emoji_events_outlined,
        'label': 'Achievers',
        'subtitle': 'Hall of Fame',
      },
      {
        'id': 'parking',
        'icon': Icons.local_parking_outlined,
        'label': 'Parking Map',
        'subtitle': 'Campus Layout',
      },
      {
        'id': 'schedules',
        'icon': Icons.schedule_outlined,
        'label': 'Schedules',
        'subtitle': 'Daily Routine',
      },
      {
        'id': 'medical',
        'icon': Icons.medical_services_outlined,
        'label': 'Medical',
        'subtitle': 'SOS & Care',
      },
      {
        'id': 'feedback',
        'icon': Icons.rate_review_outlined,
        'label': 'Feedback',
        'subtitle': 'Parent Voice',
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 550 ? 3 : 2);
    final double childAspectRatio = screenWidth > 900 ? 2.4 : (screenWidth > 550 ? 2.0 : 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded, color: YPSColors.primaryMaroon, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "Quick Actions",
              style: YPSTypography.cinematicHeader,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            final actionId = action['id'] as String;
            final isCurrent = currentScreen == actionId;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isCurrent) return; // Already on this screen

                  if (actionId == 'events') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventsScreen(eventId: currentEventId)),
                    );
                  } else if (actionId == 'achievers') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AchieversScreen(eventId: currentEventId)),
                    );
                  } else if (actionId == 'parking') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ParkingScreen(eventId: currentEventId)),
                    );
                  } else if (actionId == 'schedules') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchedulesScreen()),
                    );
                  } else if (actionId == 'medical') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicalScreen()),
                    );
                  } else if (actionId == 'feedback') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                splashColor: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(color: YPSColors.heritageGold, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? YPSColors.primaryMaroon
                                : YPSColors.primaryMaroon.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action['icon'] as IconData,
                            color: isCurrent ? Colors.white : YPSColors.primaryMaroon,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action['label'] as String,
                                style: TextStyle(
                                  color: isCurrent ? YPSColors.primaryMaroon : YPSColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                action['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: isCurrent ? YPSColors.heritageGold : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fade(delay: (200 + (index * 60)).ms).slideY(begin: 0.1);
          },
        ),

        // Prominent Return to Home Dashboard button on all sub-screens
        if (currentScreen != null && currentScreen != 'home') ...[
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeDashboard()),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: BoxDecoration(
                  color: YPSColors.primaryMaroon.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.25), width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: YPSColors.primaryMaroon,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Return to Home Dashboard",
                      style: TextStyle(
                        color: YPSColors.primaryMaroon,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fade(delay: 350.ms).slideY(begin: 0.1),
        ],
      ],
    );
  }
}
