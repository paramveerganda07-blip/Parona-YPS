// lib/screens/parking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:merit/utils/http_client.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import 'app_theme.dart';
import 'glass_card.dart';
import '../constants.dart';
import 'package:merit/services/auth_storage.dart';
import 'package:merit/utils/logger.dart';
import 'home_dashboard.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';

class ParkingScreen extends StatefulWidget {
  final String? eventId;
  const ParkingScreen({super.key, this.eventId});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  bool _isLoading = true;
  String? _mapUrl;
  String _instructions = "Please enter through Gate 1 for Parent & Visitor Parking. Follow campus security marshals for designated bays.";
  String _schoolName = "Yadavindra Public School";
  List<Map<String, dynamic>> _zones = [];

  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _fetchParkingDetails();
  }

  Future<void> _fetchParkingDetails() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthStorage.getToken();
      String urlStr = '${ApiConstants.baseUrl}/api/parking/';
      if (widget.eventId != null && widget.eventId != "0") {
        urlStr += '?event_id=${widget.eventId}';
      }

      final response = await http.get(
        Uri.parse(urlStr),
        headers: token != null ? {'Authorization': 'Token $token'} : {},
      );

      if (response.statusCode == 200) {
        final data = ApiConstants.parseResponse(response.body);
        if (data is Map<String, dynamic>) {
          setState(() {
            _mapUrl = data['parking_map_url'];
            if (data['parking_instructions'] != null && data['parking_instructions'].toString().trim().isNotEmpty) {
              _instructions = data['parking_instructions'];
            }
            if (data['school_name'] != null) {
              _schoolName = data['school_name'];
            }
            if (data['zones'] is List && (data['zones'] as List).isNotEmpty) {
              _zones = List<Map<String, dynamic>>.from(
                (data['zones'] as List).map((z) => Map<String, dynamic>.from(z as Map)),
              );
            } else {
              _zones = [];
            }
          });
        }
      }
    } catch (e) {
      logger.d("Parking info fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
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
                    const YpsCrestWidget(size: 26),
                    const SizedBox(width: 8),
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
          ),

          // INTRO & INTERACTIVE MAP HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) ...[
                    const LinearProgressIndicator(
                      color: YPSColors.heritageGold,
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // TITLE & RESET ZOOM ACTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Campus Parking Map",
                        style: YPSTypography.cinematicHeader,
                      ),
                      if (_mapUrl != null && _mapUrl!.isNotEmpty)
                        TextButton.icon(
                          onPressed: _resetZoom,
                          icon: const Icon(Icons.refresh, size: 16, color: YPSColors.primaryMaroon),
                          label: const Text(
                            "Reset Zoom",
                            style: TextStyle(color: YPSColors.primaryMaroon, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            backgroundColor: YPSColors.primaryMaroon.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // PINCH-TO-ZOOM / PAN MAP CONTAINER
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          if (_mapUrl != null && _mapUrl!.isNotEmpty)
                            InteractiveViewer(
                              transformationController: _transformController,
                              minScale: 0.8,
                              maxScale: 4.5,
                              child: SizedBox(
                                width: double.infinity,
                                height: 280,
                                child: Image.network(
                                  _mapUrl!,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator(color: YPSColors.heritageGold));
                                  },
                                  errorBuilder: (ctx, err, stack) => _buildMapFallback(),
                                ),
                              ),
                            )
                          else
                            _buildMapFallback(),

                          // Pinch to Zoom hint badge (only if map is present)
                          if (_mapUrl != null && _mapUrl!.isNotEmpty)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.pinch, color: Colors.white, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      "Pinch to Zoom Map",
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fade().scale(begin: const Offset(0.97, 0.97)),
                  const SizedBox(height: 24),

                  // OFFICIAL INSTRUCTIONS CARD
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline, color: YPSColors.primaryMaroon, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Parent Parking Guidelines",
                                style: TextStyle(
                                  color: YPSColors.primaryMaroon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _instructions,
                                style: const TextStyle(
                                  color: YPSColors.textPrimary,
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Only show header if zones actually exist
                  if (_zones.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text("Designated Parking Zones", style: YPSTypography.cinematicHeader),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),

          // PARKING ZONES LIST (Empty box with 'P' completely removed as requested)
          if (_zones.isEmpty)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final zone = _zones[index];
                    final Color zoneColor = zone['color'] is Color ? zone['color'] as Color : YPSColors.primaryMaroon;
                    final String title = zone['title'] ?? zone['name'] ?? 'Parking Zone';
                    final String type = zone['type'] ?? 'General Parking';
                    final String capacity = zone['capacity'] ?? '';
                    final String gate = (zone['gate'] ?? zone['badge'] ?? 'Gate 1').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: zoneColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.directions_car, color: zoneColor, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: YPSColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    type,
                                    style: const TextStyle(color: YPSColors.textSecondary, fontSize: 13),
                                  ),
                                  if (capacity.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          capacity,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (gate.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: zoneColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: zoneColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  gate,
                                  style: TextStyle(color: zoneColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: (100 + (index * 80)).ms).slideX(begin: 0.1);
                  },
                  childCount: _zones.length,
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              child: QuickActionsBottomBar(
                eventId: widget.eventId,
                currentScreen: 'parking',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFallback() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            YPSColors.primaryMaroon.withValues(alpha: 0.08),
            YPSColors.heritageGold.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 48,
                color: YPSColors.primaryMaroon,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Official Campus Parking Map",
              style: TextStyle(
                color: YPSColors.primaryMaroon,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Map will be updated by administration. Follow directional signage at Main Campus Gate 1 & 2.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: YPSColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// RETAINED TICKET SCREEN (Kept safely so legacy references compile)
// =========================================================================
class TicketScreen extends StatefulWidget {
  final String eventId;
  const TicketScreen({super.key, required this.eventId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _isLoading = true;
  String? _qrString;
  bool _isUsed = false;
  String _eventTitle = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    try {
      final token = await AuthStorage.getToken();
      final response = await http.get(
        ApiConstants.buildUri('events/${widget.eventId}/ticket/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = ApiConstants.parseResponse(response.body);
        setState(() {
          _qrString = data['qr_string'];
          _isUsed = data['is_used'];
          _eventTitle = data['event_title'];
        });
      }
    } catch (e) {
      logger.d("Error fetching ticket: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YPSColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: YPSColors.primaryMaroon,
        title: const Text("Event Pass", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: YPSColors.primaryMaroon)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "YPS Digital Pass",
                        style: TextStyle(color: YPSColors.heritageGold, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_eventTitle, style: YPSTypography.cinematicHeader, textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      if (_isUsed)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Column(
                            children: [
                              Icon(Icons.cancel_outlined, color: Colors.red, size: 60),
                              SizedBox(height: 16),
                              Text("TICKET ALREADY SCANNED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ).animate().fade().scale()
                      else if (_qrString != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: QrImageView(
                            data: _qrString!,
                            version: QrVersions.auto,
                            size: 250.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: YPSColors.primaryMaroon,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: YPSColors.primaryMaroon,
                            ),
                          ),
                        ).animate().fade().scale()
                      else
                        const Text("Could not generate ticket. Please contact admin.", style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 32),
                      const Text(
                        "Present this code to Gate Security upon arrival. Single use only.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
