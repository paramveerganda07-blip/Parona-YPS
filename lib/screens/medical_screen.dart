import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:merit/utils/http_client.dart' as http;
import 'package:url_launcher/url_launcher.dart'; 

import '../screens/app_theme.dart'; 
import '../screens/glass_card.dart';
import 'package:merit/services/auth_storage.dart';
import 'package:merit/utils/logger.dart';
import 'package:merit/constants.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';

class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  bool _isLoading = true;
  String _emergencyPhone = "+91-00000-00000"; // Fallback
  String _schoolName = "Yadavindra Public School";
  String? _medicalRoomPhotoUrl;
  String? _medicalInstructions;
  List<dynamic> _facilities = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicalData();
  }

  Future<void> _fetchMedicalData() async {
    logger.d("DEBUG [Medical]: Initiating fetch...");
    try {
      final token = await AuthStorage.getToken();
      
      // Ensure you create this endpoint in your Django views.py
      final url = Uri.parse('${ApiConstants.baseUrl}/api/medical-centers/');
      logger.d("DEBUG [Medical]: URL is $url");

      final response = await http.get(
        url,
        headers: token != null ? {'Authorization': 'Token $token'} : {},
      );

      logger.d("DEBUG [Medical]: Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = ApiConstants.parseResponse(response.body);
        logger.d("DEBUG [Medical]: Data received: $data");
        
        setState(() {
          final rawPhone = data['emergency_phone'];
          _emergencyPhone = (rawPhone != null && rawPhone.toString().trim().isNotEmpty)
              ? rawPhone.toString().trim()
              : "7009565809, 9876962894, 9888969677";

          final rawPhoto = data['medical_room_photo_url'];
          _medicalRoomPhotoUrl = (rawPhoto != null && rawPhoto.toString().trim().isNotEmpty)
              ? rawPhoto.toString().trim()
              : "${ApiConstants.baseUrl}/media/event_medical/950d98ba-01b5-4fe4-b4a8-d9b4ea553b75.jpg";

          final rawInst = data['medical_instructions'];
          _medicalInstructions = (rawInst != null && rawInst.toString().trim().isNotEmpty)
              ? rawInst.toString().trim()
              : "In case of any medical need or feeling unwell, visit the First Aid Station or inform nearest staff immediately. Campus ambulance is on standby.";

          _schoolName = data['school_name'] ?? _schoolName;
          _facilities = data['facilities'] ?? [
            {
              "title": "78th Annual Sports Day Medical Desk",
              "location": "School Stadium",
              "coordinator": "The School Committee",
              "phone": "7009565809, 9876962894, 9888969677"
            }
          ];
          _isLoading = false;
        });
      } else {
        logger.d("DEBUG [Medical]: Failed to fetch. Response: ${response.body}");
        setState(() {
          _emergencyPhone = "7009565809, 9876962894, 9888969677";
          _medicalRoomPhotoUrl = "${ApiConstants.baseUrl}/media/event_medical/950d98ba-01b5-4fe4-b4a8-d9b4ea553b75.jpg";
          _medicalInstructions = "In case of any medical need or feeling unwell, visit the First Aid Station or inform nearest staff immediately. Campus ambulance is on standby.";
          _facilities = [
            {
              "title": "78th Annual Sports Day Medical Desk",
              "location": "School Stadium",
              "coordinator": "The School Committee",
              "phone": "7009565809, 9876962894, 9888969677"
            }
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.d("DEBUG [Medical]: CRITICAL ERROR: $e");
      setState(() {
        _emergencyPhone = "7009565809, 9876962894, 9888969677";
        _medicalRoomPhotoUrl = "${ApiConstants.baseUrl}/media/event_medical/950d98ba-01b5-4fe4-b4a8-d9b4ea553b75.jpg";
        _medicalInstructions = "In case of any medical need or feeling unwell, visit the First Aid Station or inform nearest staff immediately. Campus ambulance is on standby.";
        _facilities = [
          {
            "title": "78th Annual Sports Day Medical Desk",
            "location": "School Stadium",
            "coordinator": "The School Committee",
            "phone": "7009565809, 9876962894, 9888969677"
          }
        ];
        _isLoading = false;
      });
    }
  }

  // Function to actually open the phone's dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    logger.d("DEBUG [Medical]: Attempting to dial $phoneNumber");
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      logger.d("DEBUG [Medical]: Cannot launch dialer for $phoneNumber");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open phone dialer."), backgroundColor: Colors.red),
        );
      }
    }
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
            shadowColor: YPSColors.primaryMaroon.withValues(alpha: 0.5),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 14),
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
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'SF Pro Display'),
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          if (_isLoading)
            SliverToBoxAdapter(
              child: Container(
                height: 300,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: YPSColors.primaryMaroon),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PULSING EMERGENCY BUTTON ---
                    GestureDetector(
                      onTap: () => _makePhoneCall(_emergencyPhone),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: YPSColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: YPSColors.alertRed.withValues(alpha: 0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: YPSColors.alertRed.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(color: YPSColors.alertRed, shape: BoxShape.circle),
                              child: const Icon(Icons.emergency, color: Colors.white),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Emergency SOS", style: YPSTypography.cinematicHeader.copyWith(fontSize: 22, color: YPSColors.alertRed)),
                                const SizedBox(height: 4),
                                const Text("Tap to call Campus Nurse", style: YPSTypography.bodyElegant),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.1),
                    
                    if (_medicalRoomPhotoUrl != null && _medicalRoomPhotoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text("Event Medical Room", style: YPSTypography.cinematicHeader.copyWith(fontSize: 22)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              _medicalRoomPhotoUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.local_hospital, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      "Campus Medical Station / MI Room",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: 0.05),
                    ],

                    if (_medicalInstructions != null && _medicalInstructions!.trim().isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text("Medical Instructions", style: YPSTypography.cinematicHeader.copyWith(fontSize: 22)),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: YPSColors.alertRed.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.health_and_safety_outlined, color: YPSColors.alertRed, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Instructions & Protocol",
                                    style: TextStyle(
                                      color: YPSColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _medicalInstructions!,
                                    style: const TextStyle(
                                      color: YPSColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: 0.05),
                    ],

                    const SizedBox(height: 36),
                    Text("First Aid Centers", style: YPSTypography.cinematicHeader.copyWith(fontSize: 24)).animate().fade(delay: 200.ms),
                    const SizedBox(height: 16),
                    
                    if (_facilities.isEmpty)
                      const Text("No medical facilities currently listed.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      // --- DYNAMIC FACILITIES LIST ---
                      ..._facilities.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var facility = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildMedicalFacilityCard(
                            facility['title'] ?? 'Clinic', 
                            facility['location'] ?? 'Campus', 
                            facility['coordinator'] ?? 'Staff', 
                            facility['phone'] ?? 'N/A'
                          ).animate().fade(delay: (300 + (idx * 100)).ms).slideX(),
                        );
                      }),
                    const SizedBox(height: 36),

                    const QuickActionsBottomBar(
                      currentScreen: 'medical',
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildMedicalFacilityCard(String title, String location, String contact, String phone) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: YPSColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Icon(Icons.directions, color: YPSColors.primaryMaroon),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: YPSColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(location, style: YPSTypography.bodyElegant)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Coordinator", style: TextStyle(color: YPSColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(contact, style: const TextStyle(color: YPSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              GestureDetector(
                onTap: () => _makePhoneCall(phone), // Make the facility pill clickable too
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: YPSColors.primaryMaroon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.call, color: YPSColors.primaryMaroon, size: 16),
                      const SizedBox(width: 8),
                      Text(phone, style: const TextStyle(color: YPSColors.primaryMaroon, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}