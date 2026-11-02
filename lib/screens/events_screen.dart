// lib/screens/events_screen.dart
import 'package:flutter/material.dart';
import 'package:merit/utils/http_client.dart' as http;

import 'app_theme.dart';
import 'glass_card.dart';
import '../constants.dart';
import 'package:merit/services/auth_storage.dart';
import 'package:merit/utils/logger.dart';
import 'event_part_details_screen.dart';
import 'home_dashboard.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';

class EventsScreen extends StatefulWidget {
  final String? eventId;
  final String? schoolId;

  const EventsScreen({
    super.key,
    this.eventId,
    this.schoolId,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _selectedEvent;
  Map<String, Color> _houseColors = {};
  String _schoolName = "Yadavindra Public School";

  // Filters for Ceremony Parts / Segments (e.g. Starting of Ceremony, March Past)
  String _selectedPhotoPart = 'All Parts';
  String _selectedParticipantPart = 'All Parts';


  List<String> _getAvailableParts(Map<String, dynamic>? event) {
    if (event == null) return [];
    final Set<String> parts = {};

    // ONLY include events/parts whose pictures have been submitted
    if (event['example_photos'] is List) {
      for (var ph in event['example_photos']) {
        if (ph is Map && ph['part'] != null) {
          final partName = ph['part'].toString().trim();
          if (partName.isNotEmpty &&
              partName.toLowerCase() != 'general' &&
              partName.toLowerCase() != 'all parts') {
            parts.add(partName);
          }
        }
      }
    }

    return parts.toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchSchoolMetadataAndEvents();
  }

  Future<void> _fetchSchoolMetadataAndEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();
      final headers = token != null ? {'Authorization': 'Token $token'} : <String, String>{};

      // 1. Fetch Houses & Colors from backend
      try {
        final metaUrl = Uri.parse('${ApiConstants.baseUrl}/api/school-metadata/');
        final metaRes = await http.get(metaUrl, headers: headers);
        if (metaRes.statusCode == 200) {
          final metaData = ApiConstants.parseResponse(metaRes.body);
          if (metaData is Map) {
            if (metaData['name'] != null && metaData['name'].toString().trim().isNotEmpty) {
              _schoolName = metaData['name'].toString().trim();
            }
            if (metaData['houses'] is List) {
              final Map<String, Color> loadedHouseColors = {};
              for (var h in metaData['houses']) {
                if (h is Map) {
                  final name = (h['name'] ?? '').toString();
                  final hex = (h['color_hex'] ?? h['color'] ?? '#D4AF37').toString();
                  loadedHouseColors[name.toLowerCase()] = _parseHexColor(hex);
                }
              }
              if (mounted) {
                setState(() {
                  _houseColors = loadedHouseColors;
                });
              }
            }
          }
        }
      } catch (e) {
        logger.d("Could not load house colors: $e");
      }

      // 2. Fetch Events from backend
      final eventsUrl = Uri.parse('${ApiConstants.baseUrl}/api/events/');
      final res = await http.get(eventsUrl, headers: headers);

      if (res.statusCode == 200) {
        final parsed = ApiConstants.parseResponse(res.body);
        if (parsed is List && parsed.isNotEmpty) {
          // ONLY include events that have submitted pictures!
          final eventList = parsed
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((e) {
                final photos = e['example_photos'];
                return photos is List && photos.isNotEmpty;
              })
              .toList();

          if (eventList.isEmpty) {
            if (mounted) {
              setState(() {
                _events = [];
                _selectedEvent = null;
                _isLoading = false;
              });
            }
            return;
          }

          Map<String, dynamic>? initialSelected;
          if (widget.eventId != null && widget.eventId != "0") {
            initialSelected = eventList.firstWhere(
              (e) => e['id'].toString() == widget.eventId.toString(),
              orElse: () => eventList.first,
            );
          } else {
            initialSelected = eventList.first;
          }

          if (mounted) {
            setState(() {
              _events = eventList;
              _selectedEvent = initialSelected;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _events = [];
          _selectedEvent = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Unable to connect to events service. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  Color _parseHexColor(String hex) {
    try {
      String cleanHex = hex.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return YPSColors.heritageGold;
    }
  }

  Color _getHouseColor(dynamic houseName) {
    if (houseName == null) return YPSColors.heritageGold;
    final str = houseName.toString().trim();
    if (str.isEmpty) return YPSColors.heritageGold;
    final lower = str.toLowerCase();
    for (var entry in _houseColors.entries) {
      final keyLower = entry.key.toLowerCase();
      if (lower.contains(keyLower) || keyLower.contains(lower)) {
        return entry.value;
      }
    }
    return YPSColors.heritageGold;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. THEMATIC SLIVER APPBAR
          _buildSliverAppBar(),

          // 2. LOADING OR ERROR STATES
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: YPSColors.primaryMaroon),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: YPSTypography.bodyElegant),
                    ],
                  ),
                ),
              ),
            )
          else if (_events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_busy, size: 64, color: YPSColors.primaryMaroon),
                      ),
                      const SizedBox(height: 20),
                      const Text("No Events Published Yet", style: YPSTypography.cinematicHeader),
                      const SizedBox(height: 8),
                      const Text(
                        "Events, itinerary sequence, example photos, and participant rosters will be announced here.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: YPSColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // 3. HORIZONTAL EVENT SWITCHER (If multiple events exist)
            if (_events.length > 1)
              SliverToBoxAdapter(
                child: _buildEventSelector(),
              ),

            // 4. ACTIVE EVENT CONTENT (Cleared of timeline clutter)
            if (_selectedEvent != null)
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final bool isSmallPhone = screenWidth < 360;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 14.0 : 20.0, 
                        vertical: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CLEAN EVENT HERO CARD (Header, Stadium photo, Title, Date, Venue, Description)
                          _buildCleanEventHeroCard(_selectedEvent!),

                          const SizedBox(height: 10),

                          // SECTION: CEREMONY PARTS & HIGHLIGHTS (Only events with submitted pictures!)
                          _buildCeremonyPartsSection(_selectedEvent!),

                          const SizedBox(height: 24),

                          // SECTION: EXAMPLE PHOTOS FOR THIS EVENT
                          _buildExamplePhotosSection(_selectedEvent!),

                          const SizedBox(height: 24),

                          // SECTION: CLASSIFIED PARTICIPANTS LIST
                          _buildClassifiedParticipantsSection(_selectedEvent!),

                          const SizedBox(height: 28),

                          // OFFICIAL YPS PATIALA CONTACT INFO CARD
                          _buildYpsContactInfoCard(),

                          const SizedBox(height: 28),

                          // ALL QUICK ACTION BUTTONS AT BOTTOM
                          QuickActionsBottomBar(
                            eventId: _selectedEvent?['id']?.toString() ?? '1',
                            currentScreen: 'events',
                          ),

                          const SizedBox(height: 60),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 110.0,
      backgroundColor: YPSColors.primaryMaroon,
      pinned: true,
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
          tooltip: 'Home Dashboard',
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeDashboard()),
            (route) => false,
          ),
        ),
        const SizedBox(width: 8),
      ],
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
                    _schoolName,
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
    );
  }

  Widget _buildEventSelector() {
    if (_events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DROPDOWN TO SELECT THE EVENT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: YPSColors.heritageGold.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: YPSColors.primaryMaroon.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedEvent?['id']?.toString(),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: YPSColors.primaryMaroon, size: 26),
                items: _events.map((event) {
                  final isLive = event['is_live'] == true;
                  return DropdownMenuItem<String>(
                    value: event['id'].toString(),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available, color: YPSColors.primaryMaroon, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event['title'] ?? 'Event',
                            style: const TextStyle(
                              color: YPSColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                            child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null) {
                    final found = _events.firstWhere((e) => e['id'].toString() == newId, orElse: () => _events.first);
                    setState(() {
                      _selectedEvent = found;
                      _selectedPhotoPart = 'All Parts';
                      _selectedParticipantPart = 'All Parts';
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Quick Pill Bar
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _events.length,
              separatorBuilder: (ctx, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final event = _events[index];
                final isSelected = _selectedEvent?['id'] == event['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEvent = event;
                      _selectedPhotoPart = 'All Parts';
                      _selectedParticipantPart = 'All Parts';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? YPSColors.primaryMaroon : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? YPSColors.primaryMaroon : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      event['title'] ?? 'Event',
                      style: TextStyle(
                        color: isSelected ? Colors.white : YPSColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanEventHeroCard(Map<String, dynamic> event) {
    String? banner = event['banner_image_url'] ?? event['banner_image'];
    if (banner != null && banner.isNotEmpty && !banner.startsWith('http')) {
      banner = '${ApiConstants.baseUrl}$banner';
    }

    final String title = event['title'] ?? '78th Annual Sports Day';
    final String venue = event['venue'] ?? 'School Stadium';
    final String description = event['description'] ?? '';
    final String formattedDate = _formatEventDate(event['event_time']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YPSColors.heritageGold.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: YPSColors.primaryMaroon.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner != null && banner.isNotEmpty)
            Image.network(
              banner,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: YPSColors.primaryMaroon.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (event['category'] ?? 'GENERAL').toString().toUpperCase(),
                        style: const TextStyle(
                          color: YPSColors.primaryMaroon,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (event['is_live'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: YPSColors.alertRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                            SizedBox(width: 4),
                            Text("LIVE NOW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: YPSTypography.cinematicHeader.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: YPSColors.primaryMaroon),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: YPSColors.primaryMaroon),
                    const SizedBox(width: 6),
                    Text(
                      venue,
                      style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(color: YPSColors.textPrimary, fontSize: 13, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(dynamic eventTime) {
    if (eventTime == null) return "Upcoming Event";
    try {
      DateTime dt = DateTime.parse(eventTime.toString()).toLocal();
      List<String> months = const ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String ampm = dt.hour >= 12 ? "PM" : "AM";
      int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      String minute = dt.minute.toString().padLeft(2, '0');
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year} • ${hour12.toString().padLeft(2, '0')}:$minute $ampm";
    } catch (_) {
      return eventTime.toString();
    }
  }

  // ==========================================
  // SECTION: CEREMONY PARTS & HIGHLIGHTS
  // ==========================================
  Widget _buildCeremonyPartsSection(Map<String, dynamic> event) {
    final parts = _getAvailableParts(event);
    if (parts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.auto_awesome,
          title: "Events (${parts.length})",
          subtitle: "Tap any event to view its photos & participants",
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: parts.map((part) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventPartDetailsScreen(
                        event: event,
                        partName: part,
                        schoolName: _schoolName,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.25), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: YPSColors.primaryMaroon.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag_outlined, color: YPSColors.primaryMaroon, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        part,
                        style: const TextStyle(
                          color: YPSColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: YPSColors.primaryMaroon),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2: EXAMPLE PHOTOS FOR THIS EVENT
  // ==========================================
  Widget _buildExamplePhotosSection(Map<String, dynamic> event) {
    final List<dynamic> allPhotos = event['example_photos'] is List ? event['example_photos'] : [];
    final availableParts = ['All Parts', ..._getAvailableParts(event)];

    final photos = allPhotos.where((p) {
      if (_selectedPhotoPart == 'All Parts') return true;
      final partName = (p['part'] ?? '').toString().trim();
      return partName.toLowerCase() == _selectedPhotoPart.toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.photo_library_outlined,
          title: "Example Photos (${photos.length})",
          subtitle: "Sample photos and highlights for this event",
        ),
        const SizedBox(height: 12),

        // Ceremony Part Dropdown Selector for Photos
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_filter, size: 18, color: YPSColors.primaryMaroon),
              const SizedBox(width: 8),
              const Text(
                "Filter by Part:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: YPSColors.textPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: availableParts.contains(_selectedPhotoPart) ? _selectedPhotoPart : 'All Parts',
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: YPSColors.primaryMaroon),
                    items: availableParts.map((String part) {
                      return DropdownMenuItem<String>(
                        value: part,
                        child: Text(
                          part,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: part == _selectedPhotoPart ? FontWeight.bold : FontWeight.normal,
                            color: YPSColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newPart) {
                      if (newPart != null) {
                        setState(() => _selectedPhotoPart = newPart);
                      }
                    },
                  ),
                ),
              ),
              if (_selectedPhotoPart != 'All Parts')
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  tooltip: "Show all photos",
                  onPressed: () => setState(() => _selectedPhotoPart = 'All Parts'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (photos.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPhotoPart == 'All Parts'
                            ? "No example photos submitted for this event yet."
                            : "No example photos submitted for \"$_selectedPhotoPart\" yet.",
                        style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13),
                      ),
                      if (_selectedPhotoPart != 'All Parts' && allPhotos.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedPhotoPart = 'All Parts'),
                          child: Text(
                            "View all event photos (${allPhotos.length})",
                            style: const TextStyle(color: YPSColors.primaryMaroon, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (ctx, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = photos[index] is Map ? photos[index] : <String, dynamic>{};
                final photoUrl = photo['url'] ?? photo['image'] ?? '';
                final caption = photo['caption'] ?? '';
                final photoPart = (photo['part'] ?? '').toString();

                final fullUrl = photoUrl.toString().startsWith('http')
                    ? photoUrl.toString()
                    : '${ApiConstants.baseUrl}$photoUrl';

                return GestureDetector(
                  onTap: () => _showPhotoPreviewDialog(context, fullUrl, caption.isNotEmpty ? caption : photoPart),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 220,
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
                          // Part badge at top-left
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
                );
              },
            ),
          ),
      ],
    );
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
                    child: Text("Could not display image", style: TextStyle(color: Colors.white)),
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

  // ==========================================
  // SECTION 3: CLASSIFIED PARTICIPANTS LIST
  // ==========================================
  Widget _buildClassifiedParticipantsSection(Map<String, dynamic> event) {
    List<Map<String, dynamic>> participants = [];
    if (event['classified_participants'] is List) {
      participants = List<Map<String, dynamic>>.from(
        (event['classified_participants'] as List).map((p) => Map<String, dynamic>.from(p as Map)),
      );
    } else if (event['participants_list'] != null && event['participants_list'].toString().isNotEmpty) {
      // Parse plain text participant list (supporting "Part: Student 1, Student 2" format)
      final rawLines = event['participants_list'].toString().split(RegExp(r'\r?\n'));
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
        final names = cleanLine.split(',');
        for (var name in names) {
          final clean = name.trim();
          if (clean.isNotEmpty) {
            participants.add({
              'name': clean,
              'role': 'Participant',
              'house': '',
              'house_color': '#D4AF37',
              'part': currentPart,
            });
          }
        }
      }
    }

    final availableParts = ['All Parts', ..._getAvailableParts(event)];

    // Extract unique houses and roles for classification tabs
    final Set<String> houses = {};
    for (var p in participants) {
      final h = (p['house'] ?? '').toString().trim();
      if (h.isNotEmpty && h != 'Unassigned') houses.add(h);
    }

    // Filter participants based on selected ceremony part
    final filtered = participants.where((p) {
      if (_selectedParticipantPart == 'All Parts') return true;
      final part = (p['part'] ?? '').toString().toLowerCase();
      return part == _selectedParticipantPart.toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.groups_outlined,
          title: "Event Participants (${filtered.length})",
          subtitle: "Classified roster of students participating in this event",
        ),
        const SizedBox(height: 12),

        // Ceremony Part Dropdown Selector for Participants
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: YPSColors.primaryMaroon),
              const SizedBox(width: 8),
              const Text(
                "Filter by Part:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: YPSColors.textPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: availableParts.contains(_selectedParticipantPart) ? _selectedParticipantPart : 'All Parts',
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: YPSColors.primaryMaroon),
                    items: availableParts.map((String part) {
                      return DropdownMenuItem<String>(
                        value: part,
                        child: Text(
                          part,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: part == _selectedParticipantPart ? FontWeight.bold : FontWeight.normal,
                            color: YPSColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newPart) {
                      if (newPart != null) {
                        setState(() => _selectedParticipantPart = newPart);
                      }
                    },
                  ),
                ),
              ),
              if (_selectedParticipantPart != 'All Parts')
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  tooltip: "Show all participants",
                  onPressed: () => setState(() => _selectedParticipantPart = 'All Parts'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (participants.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined, color: Colors.grey.shade400, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Participants roster has not been published yet for this event.",
                    style: TextStyle(color: YPSColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Text(
                    "No participants listed for '$_selectedParticipantPart'.",
                    style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _selectedParticipantPart = 'All Parts'),
                    child: Text(
                      "Show all participants (${participants.length})",
                      style: const TextStyle(color: YPSColors.primaryMaroon, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
                final p = filtered[index];
                final name = p['name'] ?? 'Student';
                final house = p['house'] ?? '';
                final role = p['role'] ?? 'Participant';
                final part = (p['part'] ?? '').toString();
                final houseColor = _getHouseColor(house);

                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Avatar with House Color Ring
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: houseColor.withValues(alpha: 0.15),
                          border: Border.all(color: houseColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: TextStyle(
                              color: houseColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Name & Details
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
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (part.isNotEmpty && part != 'General')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: YPSColors.primaryMaroon.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      part,
                                      style: const TextStyle(
                                        color: YPSColors.primaryMaroon,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (house.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: houseColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      house,
                                      style: TextStyle(
                                        color: houseColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Text(
                                  role,
                                  style: const TextStyle(
                                    color: YPSColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
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
    );
  }


  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: YPSColors.primaryMaroon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: YPSTypography.cinematicHeader.copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle, 
                style: const TextStyle(color: YPSColors.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildContactRow(IconData icon, String label, String value) {
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