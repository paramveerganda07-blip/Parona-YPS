// lib/screens/schedules_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/app_theme.dart';
import '../screens/glass_card.dart';
import 'home_dashboard.dart';
import '../widgets/quick_actions_bottom_bar.dart'; 
import '../widgets/yps_crest_widget.dart';
import '../constants.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(liveEventsProvider);
    final schoolAsync = ref.watch(schoolMetadataProvider);
    final String schoolName = schoolAsync.value?['name'] ?? "Yadavindra Public School";

    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 110.0,
            backgroundColor: YPSColors.primaryMaroon,
            pinned: true,
            elevation: 4,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 14),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const YpsCrestWidget(size: 28),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schoolName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const Text(
                          "Patiala",
                          style: TextStyle(
                            color: YPSColors.heritageGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          eventsAsync.when(
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator(color: YPSColors.primaryMaroon)))),
            error: (err, stack) => const SliverToBoxAdapter(child: Center(child: Text("Failed to load schedules.", style: YPSTypography.bodyElegant))),
            data: (events) {
              if (events.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text("No upcoming schedules.", style: YPSTypography.bodyElegant))));

              final screenWidth = MediaQuery.sizeOf(context).width;
              final bool isSmallPhone = screenWidth < 360;

              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallPhone ? 14.0 : 24.0, 
                  vertical: 20.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = events[index];
                      final isLast = index == events.length - 1;
                      return _ExpandableTimelineItem(event: event, isLast: isLast, index: index)
                          .animate()
                          .fade(delay: (200 + (index * 150)).ms)
                          .slideX(begin: 0.1);
                    },
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildYpsContactInfoCard(),
                  const SizedBox(height: 28),
                  const QuickActionsBottomBar(
                    currentScreen: 'schedules',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYpsContactInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YPSColors.heritageGold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: YPSColors.primaryMaroon.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const YpsCrestWidget(size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Yadavindra Public School",
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: YPSColors.primaryMaroon,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Patiala • Vidya Vichari Ta Parupkari",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: YPSColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
          _buildContactRow(
            Icons.location_on_outlined,
            "Address",
            "Stadium Road, New Lal Bagh Colony, Patiala, Punjab - 147001",
          ),
          const SizedBox(height: 10),
          _buildContactRow(
            Icons.phone_outlined,
            "Phone Numbers",
            "0175-2217631, 0175-2215634",
          ),
          const SizedBox(height: 10),
          _buildContactRow(
            Icons.email_outlined,
            "Email Address",
            "headmaster@ypspatiala.in",
          ),
          const SizedBox(height: 10),
          _buildContactRow(
            Icons.language_outlined,
            "Official Website",
            "www.ypspatiala.in",
          ),
        ],
      ),
    );
  }

  static Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: YPSColors.primaryMaroon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: YPSColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: YPSColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandableTimelineItem extends StatefulWidget {
  final EventModel event;
  final bool isLast;
  final int index;

  const _ExpandableTimelineItem({required this.event, required this.isLast, required this.index});

  @override
  State<_ExpandableTimelineItem> createState() => _ExpandableTimelineItemState();
}

class _ExpandableTimelineItemState extends State<_ExpandableTimelineItem> {
  bool _isExpanded = true;

  // HELPER: Generates consistent House colors based on the student's name length
  Map<String, dynamic> _getHouseData(String name) {
    final houses = [
      {'code': 'DRH', 'color': Colors.amber.shade700},
      {'code': 'PH', 'color': Colors.blue.shade700},
      {'code': 'MH', 'color': Colors.red.shade700},
      {'code': 'GH', 'color': Colors.green.shade700},
    ];
    int hash = name.trim().length % houses.length;
    return houses[hash];
  }

  // Resolves the true 28-item sports day timeline over the 4-item generic template
  List<dynamic> _resolveScheduleItems(EventModel event) {
    if (event.itinerary.length > 4) {
      return event.itinerary;
    }
    final isGeneric = event.schedules.length <= 4 &&
        event.schedules.any((s) => s is Map && (s['title'] == 'Opening Ceremony & Assembly' || s['title'] == 'Event Starts'));
    if (isGeneric && event.itinerary.isNotEmpty) {
      return event.itinerary;
    }
    return event.schedules.isNotEmpty ? event.schedules : event.itinerary;
  }

  @override
  Widget build(BuildContext context) {
    String timeOnly = "${widget.event.eventTime.hour > 12 ? widget.event.eventTime.hour - 12 : (widget.event.eventTime.hour == 0 ? 12 : widget.event.eventTime.hour).toString().padLeft(2, '0')}:${widget.event.eventTime.minute.toString().padLeft(2, '0')} ${widget.event.eventTime.hour >= 12 ? 'PM' : 'AM'}";
    
    DateTime endTime = widget.event.eventTime.add(const Duration(hours: 3));
    String endTimeStr = "${endTime.hour > 12 ? endTime.hour - 12 : (endTime.hour == 0 ? 12 : endTime.hour).toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')} ${endTime.hour >= 12 ? 'PM' : 'AM'}";

    bool isLive = DateTime.now().isAfter(widget.event.eventTime) && DateTime.now().isBefore(endTime);
    
    // --- MAGIC CHOPPER ---
    List<String> studentNames = widget.event.participantsList
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    int participantCount = studentNames.length;

    String? bannerUrl = widget.event.bannerImage;
    if (bannerUrl != null && bannerUrl.isNotEmpty && !bannerUrl.startsWith('http')) {
      bannerUrl = '${ApiConstants.baseUrl}$bannerUrl';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EVENT HERO BANNER (Stadium View)
            if (bannerUrl != null && bannerUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: Image.network(
                  bannerUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // HEADER SECTION with Integrated Time Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLive ? YPSColors.primaryMaroon.withValues(alpha: 0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLive ? YPSColors.primaryMaroon.withValues(alpha: 0.3) : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isLive ? YPSColors.primaryMaroon : YPSColors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    timeOnly,
                                    style: TextStyle(
                                      color: isLive ? YPSColors.primaryMaroon : YPSColors.textSecondary,
                                      fontWeight: isLive ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isLive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: YPSColors.alertRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: YPSColors.alertRed, width: 0.5),
                                ),
                                child: const Text("HAPPENING NOW", style: TextStyle(color: YPSColors.alertRed, fontSize: 9, fontWeight: FontWeight.bold)),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(widget.event.title, style: const TextStyle(color: YPSColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: YPSColors.primaryMaroon, size: 14),
                            const SizedBox(width: 4),
                            Expanded(child: Text(widget.event.venue, style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: YPSColors.textSecondary),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ],
              ),
                      
                      // EXPANDED DETAILS SECTION
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity, height: 0),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            
                            // Event Stats Row (Wraps cleanly on small screens)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatBadge(Icons.timer_outlined, "$timeOnly - $endTimeStr"),
                                _buildStatBadge(Icons.groups_outlined, "$participantCount Participants"),
                                if ((widget.event.entryGate ?? '').isNotEmpty)
                                  _buildStatBadge(Icons.meeting_room_outlined, "Gate: ${widget.event.entryGate}"),
                                if ((widget.event.organiser ?? '').isNotEmpty)
                                  _buildStatBadge(Icons.person_outline, "Organiser: ${widget.event.organiser}"),
                                if ((widget.event.dressCode ?? '').isNotEmpty)
                                  _buildStatBadge(Icons.checkroom_outlined, "Dress: ${widget.event.dressCode}"),
                                if ((widget.event.medicalContact ?? '').isNotEmpty)
                                  _buildStatBadge(Icons.medical_services_outlined, "SOS: ${widget.event.medicalContact}"),
                              ],
                            ),

                            if (widget.event.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.event.description,
                                style: const TextStyle(
                                  color: YPSColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],

                            // Event Medical Room Banner (Displayed in Schedules Screen with backend photo & emergency hotline)
                            Builder(
                              builder: (context) {
                                final String medicalPhoto = (widget.event.medicalRoomPhotoUrl != null && widget.event.medicalRoomPhotoUrl!.trim().isNotEmpty)
                                    ? widget.event.medicalRoomPhotoUrl!
                                    : '${ApiConstants.baseUrl}/media/event_medical/950d98ba-01b5-4fe4-b4a8-d9b4ea553b75.jpg';

                                final String medicalInstructions = (widget.event.medicalInstructions != null && widget.event.medicalInstructions!.trim().isNotEmpty)
                                    ? widget.event.medicalInstructions!
                                    : 'In case of any medical need or feeling unwell, visit the First Aid Station or inform nearest staff immediately. Campus ambulance is on standby.';

                                final String medicalContact = (widget.event.medicalContact != null && widget.event.medicalContact!.trim().isNotEmpty)
                                    ? widget.event.medicalContact!
                                    : '7009565809, 9876962894, 9888969677';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 14),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.2)),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Image.network(
                                            medicalPhoto.startsWith('http')
                                                ? medicalPhoto
                                                : '${ApiConstants.baseUrl}$medicalPhoto',
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            color: YPSColors.surfaceWhite,
                                            child: Row(
                                              children: [
                                                const Icon(Icons.local_hospital, color: YPSColors.alertRed, size: 16),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    "Event Medical Room / First Aid Station",
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: YPSColors.textPrimary),
                                                  ),
                                                ),
                                                Text(
                                                  medicalContact,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: YPSColors.alertRed),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: YPSColors.alertRed.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: YPSColors.alertRed.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.health_and_safety_outlined, color: YPSColors.alertRed, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Medical & First Aid Instructions:",
                                                  style: TextStyle(color: YPSColors.alertRed, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  medicalInstructions,
                                                  style: const TextStyle(color: YPSColors.textPrimary, fontSize: 12, height: 1.4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 20),
                            
                            // Schedules & Performance Timeline (Separate schedules field)
                            const Text(
                              "Schedule & Performance Sequence", 
                              style: TextStyle(
                                color: YPSColors.textPrimary, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final List<dynamic> scheduleItems = _resolveScheduleItems(widget.event);

                                if (scheduleItems.isNotEmpty) {
                                  return Column(
                                    children: scheduleItems.map((item) {
                                      final timeStr = item['time']?.toString() ?? '';
                                      final titleStr = item['title']?.toString() ?? '';
                                      final subtitleStr = item['subtitle']?.toString() ?? '';

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: YPSColors.primaryMaroon.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                timeStr, 
                                                style: const TextStyle(
                                                  color: YPSColors.primaryMaroon, 
                                                  fontWeight: FontWeight.bold, 
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    titleStr, 
                                                    style: const TextStyle(
                                                      color: YPSColors.textPrimary, 
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (subtitleStr.isNotEmpty)
                                                    Text(
                                                      subtitleStr, 
                                                      style: const TextStyle(
                                                        color: YPSColors.textSecondary, 
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }
                                return const Text(
                                  "Schedule timeline will be published shortly.", 
                                  style: TextStyle(
                                    color: YPSColors.textSecondary, 
                                    fontSize: 12, 
                                    fontStyle: FontStyle.italic,
                                  ),
                                );
                              },
                            ),
                            
                            // STUDENT ROSTER (Only displayed when participants list is populated)
                            if (studentNames.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text("Featured Participants", style: TextStyle(color: YPSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 12),
                              ...studentNames.map((name) {
                                final houseData = _getHouseData(name);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: (houseData['color'] as Color).withValues(alpha: 0.15),
                                        child: Text(houseData['code'], style: TextStyle(color: houseData['color'], fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(name, style: const TextStyle(color: YPSColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                      )
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                        crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                        sizeCurve: Curves.easeInOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: YPSColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: YPSColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}