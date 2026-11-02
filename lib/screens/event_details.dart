import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:merit/utils/http_client.dart' as http;
import 'dart:async'; 

import '../screens/app_theme.dart';
import '../screens/glass_card.dart';
import '../constants.dart';
import 'achievers_screen.dart';
import 'parking_screen.dart';

final singleEventProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final url = ApiConstants.buildUri('events/$id/');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    return ApiConstants.parseResponse(response.body);
  } else {
    throw Exception('Failed to load event details');
  }
});

final detailsTickProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

class EventDetailsScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  String _formatDate(DateTime dt) {
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    String ampm = dt.hour >= 12 ? "PM" : "AM";
    // FIX: Changed 'eventTime.hour' to 'dt.hour'
    int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour); 
    String minute = dt.minute.toString().padLeft(2, '0');
    return "${months[dt.month - 1]} ${dt.day} • ${hour12.toString().padLeft(2, '0')}:$minute $ampm";
  }

  String _formatTimeOnly(DateTime dt) {
    String ampm = dt.hour >= 12 ? "PM" : "AM";
    int hour12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String minute = dt.minute.toString().padLeft(2, '0');
    return "${hour12.toString().padLeft(2, '0')}:$minute $ampm";
  }

  DateTime _parseItineraryTime(String timeStr, DateTime baseDate) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts.length > 1) {
        if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
        if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
      }
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (e) {
      return baseDate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(singleEventProvider(eventId));
    final currentTime = ref.watch(detailsTickProvider).value ?? DateTime.now();

    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: YPSColors.primaryMaroon)),
        error: (err, stack) => const Center(child: Text("Failed to load event.", style: YPSTypography.bodyElegant)),
        data: (eventData) {
          final title = eventData['title'] ?? 'Event Details';
          final description = eventData['description'] ?? 'No description provided.';
          final venue = eventData['venue'] ?? 'TBA';
          final gate = eventData['entry_gate'] ?? 'Main Gate';
          final organiser = eventData['organiser'] ?? 'School Admin';
          final medical = eventData['medical_contact'] ?? 'Contact Helpdesk';
          
          String bannerImage = eventData['banner_image_url'] ?? eventData['banner_image'] ?? '';
          String? imageUrl;
          if (bannerImage.isNotEmpty) {
            imageUrl = bannerImage.startsWith('http') ? bannerImage : '${ApiConstants.baseUrl}$bannerImage';
          }

          final eventTime = eventData['event_time'] != null ? DateTime.parse(eventData['event_time']).toLocal() : DateTime.now();
          final timeString = _formatDate(eventTime);
          
          final gateOpenTimeObj = eventTime.subtract(const Duration(minutes: 30));
          final isMainEventLive = currentTime.isAfter(gateOpenTimeObj) && currentTime.isBefore(eventTime.add(const Duration(hours: 12)));

          final List<dynamic> itinerary = eventData['itinerary'] is List ? eventData['itinerary'] : [];
          int activeIndex = -1;
          
          if (itinerary.isNotEmpty) {
            for (int i = 0; i < itinerary.length; i++) {
              DateTime itemTime = _parseItineraryTime(itinerary[i]['time']?.toString() ?? '', eventTime);
              if (currentTime.isAfter(itemTime) || currentTime.isAtSameMomentAs(itemTime)) {
                activeIndex = i;
              }
            }
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 400.0,
                stretch: true,
                pinned: true,
                backgroundColor: YPSColors.backgroundLight,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholderHeader(title))
                          : _buildPlaceholderHeader(title),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5), YPSColors.backgroundLight],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: YPSColors.primaryMaroon, size: 18), onPressed: () => Navigator.pop(context)),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final bool isSmallPhone = screenWidth < 360;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          if (isMainEventLive)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: YPSColors.alertRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: YPSColors.alertRed)),
                              child: const Text("HAPPENING NOW", style: TextStyle(color: YPSColors.alertRed, fontSize: 12, fontWeight: FontWeight.bold)),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
                            
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title, 
                              style: YPSTypography.cinematicHeader.copyWith(
                                fontSize: isSmallPhone ? 22 : 28,
                              ),
                            ),
                          ).animate().fade(delay: 100.ms),
                          const SizedBox(height: 8),
                          Text(
                            "$timeString\n$venue • Gate: $gate", 
                            style: TextStyle(
                              color: YPSColors.primaryMaroon, 
                              fontWeight: FontWeight.bold, 
                              fontSize: isSmallPhone ? 13 : 15, 
                              height: 1.5,
                            ),
                          ).animate().fade(delay: 200.ms),
                          const SizedBox(height: 20),

                          // Quick Action Row for Parents: Parking Map & Achievers
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: YPSColors.primaryMaroon,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 10 : 14, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ParkingScreen(eventId: eventId)),
                                  ),
                                  icon: const Icon(Icons.local_parking, size: 18, color: YPSColors.heritageGold),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text("Parking & Map", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: YPSColors.primaryMaroon,
                                    side: const BorderSide(color: YPSColors.primaryMaroon, width: 1.5),
                                    padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 10 : 14, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AchieversScreen(eventId: eventId, eventTitle: title)),
                                  ),
                                  icon: const Icon(Icons.emoji_events, size: 18, color: YPSColors.heritageGold),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: const Text("Achievers", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fade(delay: 250.ms),
                          const SizedBox(height: 24),
                      
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: YPSColors.primaryMaroon, size: 20),
                                const SizedBox(width: 8),
                                Text("Event Overview", style: YPSTypography.cinematicHeader.copyWith(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(description, style: YPSTypography.bodyElegant),
                          ],
                        ),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),

                      // Example Photos Section
                      _buildExamplePhotosSection(context, eventData['example_photos'] is List ? eventData['example_photos'] : []),
                      const SizedBox(height: 24),

                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: YPSColors.primaryMaroon, size: 20),
                                const SizedBox(width: 8),
                                Text("Operations & Support", style: YPSTypography.cinematicHeader.copyWith(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildContactRow(Icons.person_outline, "Organiser", organiser),
                            const SizedBox(height: 12),
                            _buildContactRow(Icons.medical_services_outlined, "Medical Contact", medical, iconColor: YPSColors.alertRed),
                          ],
                        ),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      
                      Text("Interactive Itinerary", style: YPSTypography.cinematicHeader.copyWith(fontSize: 22)).animate().fade(delay: 500.ms),
                      const SizedBox(height: 24),
                      
                      if (itinerary.isNotEmpty)
                        ...List.generate(itinerary.length, (index) {
                          final item = itinerary[index];
                          return _buildTimelineItem(
                            item['time']?.toString() ?? 'TBA', 
                            item['title']?.toString() ?? 'Event Segment', 
                            item['subtitle']?.toString() ?? '', 
                            isLive: (index == activeIndex),
                            isPast: (index < activeIndex),
                          ).animate().fade().slideX();
                        })
                      else ...[
                        _buildTimelineItem(_formatTimeOnly(gateOpenTimeObj), "Gate Opens", "Entry from $gate", isLive: currentTime.isAfter(gateOpenTimeObj) && currentTime.isBefore(eventTime), isPast: currentTime.isAfter(eventTime)).animate().fade(delay: 600.ms),
                        _buildTimelineItem(_formatTimeOnly(eventTime), "Event Commences", venue, isLive: currentTime.isAfter(eventTime), isPast: false).animate().fade(delay: 700.ms),
                      ],
                      const SizedBox(height: 60), 
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  ),
);
}

  Widget _buildContactRow(IconData icon, String title, String value, {Color iconColor = YPSColors.primaryMaroon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: YPSColors.textSecondary)),
              Text(value, style: const TextStyle(color: YPSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String time, String title, String subtitle, {required bool isLive, required bool isPast}) {
    Color activeColor = isLive ? YPSColors.primaryMaroon : (isPast ? Colors.grey.shade400 : Colors.grey.shade300);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              time,
              style: TextStyle(
                color: isPast ? Colors.grey.shade400 : (isLive ? YPSColors.primaryMaroon : YPSColors.textPrimary),
                fontWeight: isLive ? FontWeight.bold : FontWeight.w600,
                decoration: isPast ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: isLive ? YPSColors.primaryMaroon.withValues(alpha: 0.2) : (isPast ? Colors.grey.shade300 : Colors.transparent),
                  border: Border.all(color: activeColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: isLive ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: YPSColors.primaryMaroon, shape: BoxShape.circle))) : (isPast ? const Icon(Icons.check, size: 10, color: Colors.white) : null),
              ),
              Container(width: 2, height: 40, color: isPast ? Colors.grey.shade300 : Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isPast ? Colors.grey.shade400 : YPSColors.textPrimary, fontSize: 18, fontWeight: isLive ? FontWeight.bold : FontWeight.w600)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: isPast ? Colors.grey.shade400 : YPSColors.textSecondary, fontSize: 14)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [YPSColors.primaryMaroon, Color(0xFF38000A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, color: YPSColors.heritageGold, size: 64),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplePhotosSection(BuildContext context, List<dynamic> photos) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, String>> displayPhotos = photos.map<Map<String, String>>((p) {
      String url = p['url']?.toString() ?? p['image']?.toString() ?? '';
      if (url.isNotEmpty && !url.startsWith('http')) {
        url = '${ApiConstants.baseUrl}$url';
      }
      return {
        'url': url,
        'caption': p['caption']?.toString() ?? 'Event Photo',
      };
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_camera_back_outlined, color: YPSColors.primaryMaroon, size: 20),
                  const SizedBox(width: 8),
                  Text("Example & Highlight Photos", style: YPSTypography.cinematicHeader.copyWith(fontSize: 18)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: YPSColors.heritageGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${displayPhotos.length} Photos",
                  style: const TextStyle(color: YPSColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Sample glimpses and key moments of this event submitted by the school admin.",
            style: TextStyle(color: YPSColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayPhotos.length,
              itemBuilder: (ctx, index) {
                final photo = displayPhotos[index];
                final photoUrl = photo['url'] ?? '';
                final caption = photo['caption'] ?? '';

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dCtx) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: Colors.black,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  backgroundColor: Colors.black,
                                  title: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  leading: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => Navigator.pop(dCtx),
                                  ),
                                ),
                                InteractiveViewer(
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (eCtx, err, stack) => const Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Text(
                              caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
      ),
    ).animate().fade(delay: 350.ms).slideY(begin: 0.1);
  }
}