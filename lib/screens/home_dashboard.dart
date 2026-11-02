// lib/screens/home_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:merit/utils/http_client.dart' as http;
import 'dart:async'; 

import '../screens/app_theme.dart'; 
import '../screens/glass_card.dart'; 
import 'event_details.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';
// import 'parent_dashboard.dart'; // Retained for future use
// import 'login_screen.dart'; // Retained for future use
import 'package:merit/services/auth_storage.dart';
import 'package:merit/utils/logger.dart';
import 'package:merit/constants.dart';

// --- 1. DATA MODEL ---
class EventModel {
  final int id;
  final String title;
  final String description;
  final String? bannerImage; 
  final DateTime eventTime; 
  final String venue;
  final List<dynamic> itinerary; 
  final List<dynamic> schedules;
  final String participantsList;
  final List<dynamic> examplePhotos;
  final List<dynamic> achievers;
  final String? parkingMap;
  final String? parkingInstructions;
  final String? medicalRoomPhotoUrl;
  final String? medicalInstructions;
  final String? medicalContact;
  final String? entryGate;
  final String? organiser;
  final String? dressCode;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.bannerImage,
    required this.eventTime,
    required this.venue,
    this.itinerary = const [], 
    this.schedules = const [],
    this.participantsList = '',
    this.examplePhotos = const [],
    this.achievers = const [],
    this.parkingMap,
    this.parkingInstructions,
    this.medicalRoomPhotoUrl,
    this.medicalInstructions,
    this.medicalContact,
    this.entryGate,
    this.organiser,
    this.dressCode,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rawSchedules = json['schedules'] is List ? (json['schedules'] as List) : [];
    final rawItinerary = json['itinerary'] is List ? (json['itinerary'] as List) : [];
    final rawItineraryItems = json['itinerary_items'] is List ? (json['itinerary_items'] as List) : [];

    // Prioritize the real 28-item Sports Day itinerary sequence
    List<dynamic> resolvedSchedules = rawSchedules;
    final bool isDefaultTemplate = rawSchedules.length <= 4 &&
        rawSchedules.any((s) => s is Map && (s['title'] == 'Opening Ceremony & Assembly' || s['title'] == 'Event Starts'));

    if (rawItinerary.length > 4) {
      resolvedSchedules = rawItinerary;
    } else if (isDefaultTemplate || resolvedSchedules.isEmpty) {
      if (rawItinerary.isNotEmpty) {
        resolvedSchedules = rawItinerary;
      } else if (rawItineraryItems.isNotEmpty) {
        resolvedSchedules = rawItineraryItems;
      }
    }

    final rawPhoto = json['medical_room_photo_url'] ?? json['medical_room_photo'];
    final String resolvedMedicalPhoto = (rawPhoto != null && rawPhoto.toString().trim().isNotEmpty)
        ? rawPhoto.toString().trim()
        : '${ApiConstants.baseUrl}/media/event_medical/950d98ba-01b5-4fe4-b4a8-d9b4ea553b75.jpg';

    final rawInstructions = json['medical_instructions'];
    final String resolvedInstructions = (rawInstructions != null && rawInstructions.toString().trim().isNotEmpty)
        ? rawInstructions.toString().trim()
        : 'In case of any medical need or feeling unwell, visit the First Aid Station or inform nearest staff immediately. Campus ambulance is on standby.';

    final rawContact = json['medical_contact'];
    final String resolvedContact = (rawContact != null && rawContact.toString().trim().isNotEmpty)
        ? rawContact.toString().trim()
        : '7009565809, 9876962894, 9888969677';

    return EventModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'School Event',
      description: json['description'] ?? '',
      bannerImage: json['banner_image_url'] ?? json['banner_image'],
      eventTime: DateTime.parse(json['event_time'] ?? DateTime.now().toIso8601String()).toLocal(),
      venue: json['venue'] ?? 'TBA',
      itinerary: rawItinerary.isNotEmpty ? rawItinerary : resolvedSchedules,
      schedules: resolvedSchedules,
      participantsList: json['participants_list'] ?? '',
      examplePhotos: json['example_photos'] is List ? json['example_photos'] : [],
      achievers: json['achievers'] is List ? json['achievers'] : [],
      parkingMap: json['parking_map'],
      parkingInstructions: json['parking_instructions'],
      medicalRoomPhotoUrl: resolvedMedicalPhoto,
      medicalInstructions: resolvedInstructions,
      medicalContact: resolvedContact,
      entryGate: json['entry_gate'],
      organiser: json['organiser'],
      dressCode: json['dress_code'],
    );
  }

  String getFormattedDate() {
    try {
      List<String> months = const ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      String ampm = eventTime.hour >= 12 ? "PM" : "AM";
      int hour12 = eventTime.hour > 12 ? eventTime.hour - 12 : (eventTime.hour == 0 ? 12 : eventTime.hour);
      String minute = eventTime.minute.toString().padLeft(2, '0');
      return "${months[eventTime.month - 1]} ${eventTime.day} • ${hour12.toString().padLeft(2, '0')}:$minute $ampm";
    } catch (e) {
      return "Upcoming";
    }
  }
}

// --- 2. PROVIDERS ---

// A. Fetch Live Events
final liveEventsProvider = FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final token = await AuthStorage.getToken();
  final url = Uri.parse('${ApiConstants.baseUrl}/api/events/');
  
  logger.d("DEBUG [LiveEvents]: Fetching from $url (token present: ${token != null})");

  List<dynamic> eventList = [];

  // 1. Attempt authenticated fetch
  try {
    final response = await http.get(
      url,
      headers: token != null ? {'Authorization': 'Token $token'} : {},
    );

    logger.d("DEBUG [LiveEvents]: Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final parsed = ApiConstants.parseResponse(response.body);
      if (parsed is List) {
        eventList = parsed;
      }
    }
  } catch (e) {
    logger.d("DEBUG [LiveEvents]: Authenticated fetch error: $e");
  }

  // 2. 🔥 Bulletproof Fallback: If authenticated request returned 0 events (e.g. backend profile filtering mismatch),
  // fetch public school events without the auth token header
  if (eventList.isEmpty) {
    try {
      logger.d("DEBUG [LiveEvents]: Authenticated list empty, attempting public fetch fallback...");
      final publicRes = await http.get(url);
      logger.d("DEBUG [LiveEvents]: Public Status Code: ${publicRes.statusCode}");
      if (publicRes.statusCode == 200) {
        final parsed = ApiConstants.parseResponse(publicRes.body);
        if (parsed is List && parsed.isNotEmpty) {
          logger.d("DEBUG [LiveEvents]: Public fallback recovered ${parsed.length} events!");
          eventList = parsed;
        }
      }
    } catch (e) {
      logger.d("DEBUG [LiveEvents]: Public fallback error: $e");
    }
  }

  logger.d("DEBUG [LiveEvents]: Final parsed count = ${eventList.length} events");
  return eventList.map((json) {
    if (json is Map<String, dynamic>) {
      return EventModel.fromJson(json);
    }
    return EventModel.fromJson(Map<String, dynamic>.from(json as Map));
  }).toList();
});

// B. Fetch School Metadata (Name, Banner, Houses)
final schoolMetadataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final token = await AuthStorage.getToken();
  final url = Uri.parse('${ApiConstants.baseUrl}/api/school-metadata/');
  
  logger.d("DEBUG [SchoolData]: Fetching from $url");

  try {
    final response = await http.get(
      url,
      headers: token != null ? {'Authorization': 'Token $token'} : {},
    );

    if (response.statusCode == 200) {
      final data = ApiConstants.parseResponse(response.body);
      if (data is Map<String, dynamic>) {
        logger.d("DEBUG [SchoolData]: Successfully loaded: $data");
        return data;
      }
    }
  } catch (e) {
    logger.d("DEBUG [SchoolData]: Failed with error: $e");
  }

  // Graceful fallback prevents the header from ever being stuck on "Loading..."
  return {
    'name': 'Yadavindra Public School',
    'banner_url': '',
    'houses': [],
  };
});

final tickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

// --- 3. MAIN DASHBOARD WIDGET ---

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(liveEventsProvider);
    final schoolAsync = ref.watch(schoolMetadataProvider);

    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      body: RefreshIndicator(
        color: YPSColors.primaryMaroon,
        onRefresh: () async {
          ref.invalidate(liveEventsProvider);
          ref.invalidate(schoolMetadataProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildCinematicAppBar(context, schoolAsync, ref),
            
            eventsAsync.when(
            loading: () => SliverToBoxAdapter(
              child: SizedBox(
                height: 400,
                child: Center(
                  child: const CircularProgressIndicator(color: YPSColors.primaryMaroon).animate().fade().scale(),
                ),
              ),
            ),
            error: (err, stack) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text("Connection offline", style: YPSTypography.bodyElegant)),
              ),
            ),            data: (events) {
              if (events.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: YPSColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_available, color: Colors.grey.shade400, size: 28),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "No upcoming spotlight events scheduled at this moment.", 
                                      style: YPSTypography.bodyElegant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
                            QuickActionsBottomBar(
                              eventId: "1",
                              currentScreen: 'home',
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final spotlightEvent = events.first;
              final screenWidth = MediaQuery.sizeOf(context).width;
              final bool isSmallPhone = screenWidth < 360;

              return SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Top bar that says 'Latest' has been removed per request
                          Text(
                            "Upcoming Spotlight", 
                            style: YPSTypography.cinematicHeader.copyWith(
                              fontSize: isSmallPhone ? 22 : 28,
                            ),
                          ).animate().fade(delay: 200.ms),
                          const SizedBox(height: 18),
                          
                          _buildHeroEventCard(spotlightEvent, context, ref)
                              .animate()
                              .fade(delay: 300.ms)
                              .scale(begin: const Offset(0.95, 0.95)),

                          const SizedBox(height: 28),
                          _buildYpsContactInfoCard(),
                          const SizedBox(height: 28),
                          QuickActionsBottomBar(
                            eventId: spotlightEvent.id.toString(),
                            currentScreen: 'home',
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
  }

  // --- DYNAMIC UI BUILDERS ---

  Widget _buildCinematicAppBar(BuildContext context, AsyncValue<Map<String, dynamic>> schoolAsync, WidgetRef ref) {
    String schoolName = schoolAsync.value?['name'] ?? "Yadavindra Public School";

    return SliverAppBar(
      expandedHeight: 110.0,
      backgroundColor: YPSColors.primaryMaroon,
      pinned: true,
      elevation: 4,
      shadowColor: YPSColors.primaryMaroon.withValues(alpha: 0.5), 
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SF Pro Display'),
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

  Widget _buildHeroEventCard(EventModel event, BuildContext context, WidgetRef ref) {
    final currentTime = ref.watch(tickProvider).value ?? DateTime.now();
    final difference = event.eventTime.difference(currentTime);
    final isLive = difference.isNegative; 

    String countdownText = "";
    if (!isLive) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;
      if (days > 0) {
        countdownText = "Starts in ${days}d ${hours}h";
      } else {
        countdownText = "Starts in ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      }
    }

    String? imageUrl;
    if (event.bannerImage != null && event.bannerImage!.isNotEmpty) {
      imageUrl = event.bannerImage!.startsWith('http') 
          ? event.bannerImage! 
          : '${ApiConstants.baseUrl}${event.bannerImage}';
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(eventId: event.id.toString()))),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildBannerPlaceholder(event),
                      )
                    : _buildBannerPlaceholder(event),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          event.getFormattedDate(), 
                          style: const TextStyle(
                            color: YPSColors.primaryMaroon, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: YPSColors.alertRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text("HAPPENING NOW", style: TextStyle(color: YPSColors.alertRed, fontSize: 10, fontWeight: FontWeight.bold)),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 800.ms)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: YPSColors.primaryMaroon.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(countdownText, style: const TextStyle(color: YPSColors.primaryMaroon, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(event.title, style: YPSTypography.cinematicHeader.copyWith(fontSize: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: YPSColors.textSecondary, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(event.venue, style: YPSTypography.bodyElegant, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPlaceholder(EventModel event) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [YPSColors.primaryMaroon, Color(0xFF38000A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.account_balance,
              size: 140,
              color: YPSColors.heritageGold.withValues(alpha: 0.12),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event, color: YPSColors.heritageGold, size: 36),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                      "Vidya • Vinay • Veerta",
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