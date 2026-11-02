// lib/screens/achievers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:merit/utils/http_client.dart' as http;

import 'app_theme.dart';
import 'glass_card.dart';
import '../constants.dart';
import 'home_dashboard.dart';
import 'package:merit/services/auth_storage.dart';
import 'package:merit/utils/logger.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';

class AchieversScreen extends StatefulWidget {
  final String? eventId;
  final String? eventTitle;

  const AchieversScreen({
    super.key,
    this.eventId,
    this.eventTitle,
  });

  @override
  State<AchieversScreen> createState() => _AchieversScreenState();
}

class _AchieversScreenState extends State<AchieversScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _achievers = [];
  String _searchQuery = "";
  String _selectedFilter = "All";
  String _schoolName = "Yadavindra Public School";
  Map<String, Color> _houseColors = {};

  @override
  void initState() {
    super.initState();
    _fetchAchieversAndHouses();
  }

  Future<void> _fetchAchieversAndHouses() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthStorage.getToken();
      final headers = token != null ? {'Authorization': 'Token $token'} : <String, String>{};

      // 1. Dynamically import Houses and Colors from backend
      try {
        final metaRes = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/school-metadata/'),
          headers: headers,
        );
        if (metaRes.statusCode == 200) {
          final metaData = ApiConstants.parseResponse(metaRes.body);
          if (metaData is Map) {
            if (metaData['name'] != null) {
              _schoolName = metaData['name'].toString();
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
                setState(() => _houseColors = loadedHouseColors);
              }
            }
          }
        }
      } catch (e) {
        logger.d("Could not load house colors: $e");
      }

      // 2. Fetch Achievers for this event or school
      Uri url;
      if (widget.eventId != null && widget.eventId != "0") {
        url = Uri.parse('${ApiConstants.baseUrl}/api/events/${widget.eventId}/achievers/');
      } else {
        url = Uri.parse('${ApiConstants.baseUrl}/api/achievers/');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final parsed = ApiConstants.parseResponse(response.body);
        if (parsed is List) {
          setState(() {
            _achievers = List<Map<String, dynamic>>.from(
              parsed.map((item) => Map<String, dynamic>.from(item as Map))
            );
          });
        } else {
          setState(() => _achievers = []);
        }
      } else {
        setState(() => _achievers = []);
      }
    } catch (e) {
      logger.d("Achievers fetch error: $e");
      setState(() => _achievers = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Color _getHouseColor(String? house) {
    if (house == null || house.isEmpty) return YPSColors.heritageGold;
    final h = house.toLowerCase();
    for (var entry in _houseColors.entries) {
      if (h.contains(entry.key) || entry.key.contains(h)) {
        return entry.value;
      }
    }
    return YPSColors.heritageGold;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _achievers.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          (a['student_name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (a['award_title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (a['house']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesFilter = _selectedFilter == "All" ||
          (a['category']?.toString().toLowerCase() == _selectedFilter.toLowerCase());

      return matchesSearch && matchesFilter;
    }).toList();

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
          ),

          // SEARCH & FILTER BAR
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search by student name, award, or house...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: YPSColors.primaryMaroon),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['All', 'Sports', 'Cultural', 'Academics', 'Arts'].map((cat) {
                        final isSelected = _selectedFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedFilter = cat);
                            },
                            selectedColor: YPSColors.primaryMaroon,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : YPSColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? YPSColors.primaryMaroon : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Honoring Excellence (${filteredList.length})",
                        style: YPSTypography.cinematicHeader.copyWith(fontSize: 16),
                      ),
                      const Text(
                        "Vidya • Vinay • Veerta",
                        style: TextStyle(
                          color: YPSColors.heritageGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ACHIEVERS LIST
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80.0),
                child: Center(
                  child: CircularProgressIndicator(color: YPSColors.primaryMaroon),
                ),
              ),
            )
          else if (_achievers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0, left: 24, right: 24),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: YPSColors.heritageGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_outlined, size: 56, color: YPSColors.heritageGold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No Achievers Announced Yet",
                        style: YPSTypography.cinematicHeader,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Honorees and award winners will be published here upon conclusion of the event.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: YPSColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filteredList.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        "No achievers match your search query.",
                        style: TextStyle(color: YPSColors.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final achiever = filteredList[index];
                    final houseColor = _getHouseColor(achiever['house']?.toString());
                    final photoUrl = achiever['photo_url'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Avatar / Photo
                            Stack(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: houseColor, width: 2.5),
                                    color: houseColor.withValues(alpha: 0.1),
                                  ),
                                  child: ClipOval(
                                    child: photoUrl != null && photoUrl.toString().isNotEmpty
                                        ? Image.network(
                                            photoUrl.toString(),
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => Icon(
                                              Icons.person,
                                              size: 34,
                                              color: houseColor,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 34,
                                            color: houseColor,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: YPSColors.heritageGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.star, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          achiever['student_name'] ?? 'Achiever Student',
                                          style: const TextStyle(
                                            color: YPSColors.textPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (achiever['house'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: houseColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: houseColor.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            achiever['house'] ?? '',
                                            style: TextStyle(
                                              color: houseColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Award Title Badge
                                  Row(
                                    children: [
                                      const Icon(Icons.military_tech, color: YPSColors.heritageGold, size: 18),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          achiever['award_title'] ?? 'Excellence Award',
                                          style: const TextStyle(
                                            color: YPSColors.primaryMaroon,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (achiever['event_title'] != null && achiever['event_title'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Event: ${achiever['event_title']}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],

                                  if (achiever['description'] != null && achiever['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      achiever['description']!,
                                      style: const TextStyle(
                                        color: YPSColors.textSecondary,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: (100 + (index * 60)).ms).slideY(begin: 0.1);
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              child: QuickActionsBottomBar(
                eventId: widget.eventId,
                currentScreen: 'achievers',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
