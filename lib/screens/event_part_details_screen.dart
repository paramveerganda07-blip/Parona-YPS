// lib/screens/event_part_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_theme.dart';
import 'glass_card.dart';
import '../constants.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';

class EventPartDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final String partName;
  final String? schoolName;

  const EventPartDetailsScreen({
    super.key,
    required this.event,
    required this.partName,
    this.schoolName,
  });

  @override
  State<EventPartDetailsScreen> createState() => _EventPartDetailsScreenState();
}

class _EventPartDetailsScreenState extends State<EventPartDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPhotosForPart() {
    final List<dynamic> allPhotos = widget.event['example_photos'] is List
        ? widget.event['example_photos']
        : [];

    final target = widget.partName.trim().toLowerCase();

    // 1. First, search for exact or partial part match
    final matched = allPhotos.where((p) {
      if (p is! Map) return false;
      final part = (p['part'] ?? '').toString().trim().toLowerCase();
      if (part.isEmpty || part == 'general') return false;
      return part == target || target.contains(part) || part.contains(target);
    }).map((p) => Map<String, dynamic>.from(p as Map)).toList();

    if (matched.isNotEmpty) return matched;

    // 2. If no specific photos match, return general or all photos for the event
    return allPhotos.whereType<Map>().map((p) => Map<String, dynamic>.from(p)).toList();
  }

  List<Map<String, dynamic>> _getParticipantsForPart() {
    final List<Map<String, dynamic>> participants = [];
    final target = widget.partName.trim().toLowerCase();

    if (widget.event['classified_participants'] is List) {
      for (var p in widget.event['classified_participants']) {
        if (p is Map) {
          final part = (p['part'] ?? '').toString().trim().toLowerCase();
          if (part == target || target.contains(part) || part.contains(target) || part.isEmpty || part == 'general') {
            participants.add(Map<String, dynamic>.from(p));
          }
        }
      }
    } else if (widget.event['participants_list'] != null &&
        widget.event['participants_list'].toString().isNotEmpty) {
      // Parse plain text participant list
      final rawLines = widget.event['participants_list'].toString().split(RegExp(r'\r?\n'));
      String currentPart = 'General';
      for (var line in rawLines) {
        var cleanLine = line.trim();
        if (cleanLine.isEmpty) continue;
        if (cleanLine.contains(':') && !cleanLine.startsWith('http')) {
          final spl = cleanLine.split(':');
          if (spl[0].trim().split(' ').length <= 6) {
            currentPart = spl[0].trim();
            cleanLine = spl.sublist(1).join(':').trim();
            if (cleanLine.isEmpty) continue;
          }
        }

        final cpLower = currentPart.toLowerCase();
        final isPartMatch = cpLower == target || target.contains(cpLower) || cpLower.contains(target);

        if (isPartMatch) {
          final names = cleanLine.split(',');
          for (var name in names) {
            final clean = name.trim();
            if (clean.isNotEmpty) {
              participants.add({
                'name': clean,
                'role': 'Participant',
                'house': '',
                'part': currentPart,
              });
            }
          }
        }
      }
    }

    if (_searchQuery.trim().isEmpty) return participants;

    final q = _searchQuery.trim().toLowerCase();
    return participants.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final role = (p['role'] ?? '').toString().toLowerCase();
      final house = (p['house'] ?? '').toString().toLowerCase();
      return name.contains(q) || role.contains(q) || house.contains(q);
    }).toList();
  }

  void _showPhotoPreviewDialog(BuildContext context, String imageUrl, String caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("Could not display image", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = widget.schoolName ?? "Yadavindra Public School";
    final eventTitle = widget.event['title'] ?? 'School Event';
    final photos = _getPhotosForPart();
    final participants = _getParticipantsForPart();
    final eventIdStr = widget.event['id']?.toString() ?? '1';

    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. TOP APP BAR: ONLY School Crest / Symbol and School Name
          SliverAppBar(
            expandedHeight: 110.0,
            backgroundColor: YPSColors.primaryMaroon,
            pinned: true,
            elevation: 4,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

          // 2. CEREMONY PART HEADER CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            "CEREMONY PART",
                            style: TextStyle(
                              color: YPSColors.primaryMaroon,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eventTitle,
                            style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.partName,
                      style: YPSTypography.cinematicHeader.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 16),

                    // TAB NAVIGATION BAR (Photos vs Participants)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: YPSColors.primaryMaroon,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: YPSColors.textSecondary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            text: "Photos (${photos.length})",
                          ),
                          Tab(
                            icon: const Icon(Icons.groups_outlined, size: 18),
                            text: "Participants (${participants.length})",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. TAB VIEWS CONTENT
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildPhotosSection(photos);
                } else {
                  return _buildParticipantsSection(participants);
                }
              },
            ),
          ),

          // 4. BOTTOM QUICK ACTIONS (Requested on all screens)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 20, 60),
              child: QuickActionsBottomBar(
                eventId: eventIdStr,
                currentScreen: 'events',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "No photos uploaded for \"${widget.partName}\" yet.",
                  style: const TextStyle(color: YPSColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  "Photos from this ceremony part will appear here as they are published.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final photoUrl = photo['url'] ?? photo['image'] ?? '';
          final caption = photo['caption'] ?? '';
          final photoPart = (photo['part'] ?? '').toString();

          final fullUrl = photoUrl.toString().startsWith('http')
              ? photoUrl.toString()
              : '${ApiConstants.baseUrl}$photoUrl';

          return GestureDetector(
            onTap: () => _showPhotoPreviewDialog(
              context,
              fullUrl,
              caption.isNotEmpty ? caption : widget.partName,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 36),
                      ),
                    ),
                    if (photoPart.isNotEmpty && photoPart != 'General')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: YPSColors.primaryMaroon.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            photoPart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (caption.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Text(
                            caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ).animate().fade(delay: (100 * index).ms).scale(begin: const Offset(0.95, 0.95));
        },
      ),
    );
  }

  Widget _buildParticipantsSection(List<Map<String, dynamic>> participants) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: YPSColors.primaryMaroon, size: 20),
                hintText: "Search student or role...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 14),

          if (participants.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? "No participants match '$_searchQuery'."
                          : "No participants listed for \"${widget.partName}\" yet.",
                      style: const TextStyle(color: YPSColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = participants[index];
                final name = (p['name'] ?? 'Student').toString();
                final role = (p['role'] ?? 'Participant').toString();
                final house = (p['house'] ?? '').toString();

                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: YPSColors.primaryMaroon.withValues(alpha: 0.12),
                          border: Border.all(color: YPSColors.heritageGold, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: YPSColors.primaryMaroon,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: YPSColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  role,
                                  style: const TextStyle(
                                    color: YPSColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (house.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: YPSColors.heritageGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      house,
                                      style: const TextStyle(
                                        color: YPSColors.heritageGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
