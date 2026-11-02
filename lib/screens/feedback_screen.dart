// lib/screens/feedback_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:merit/utils/http_client.dart' as http;
import '../constants.dart';
import '../screens/app_theme.dart';
import '../screens/glass_card.dart';
import '../widgets/quick_actions_bottom_bar.dart';
import '../widgets/yps_crest_widget.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedRating = 5;
  final String _selectedCategory = 'EVENT'; // Only events feedback
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your parent name"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your parent email address"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/feedback/submit/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'parent_name': name,
          'parent_email': email,
          'category': _selectedCategory,
          'rating': _selectedRating,
          'comments': _commentsController.text.trim(),
          'is_anonymous': _isAnonymous,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _isSuccess = true;
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Submission failed (${response.statusCode}). Please check connection."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
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
          // 1. TOP APP BAR: ONLY School Crest / Symbol and School Name
          SliverAppBar(
            expandedHeight: 110.0,
            backgroundColor: YPSColors.primaryMaroon,
            pinned: true,
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
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Yadavindra Public School",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        Text(
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: _isSuccess ? _buildSuccessState() : _buildFeedbackForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Feedback Badge Header (Only Event Feedback)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: YPSColors.primaryMaroon.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YPSColors.primaryMaroon.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: YPSColors.primaryMaroon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rate_review, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Events Feedback",
                      style: TextStyle(
                        color: YPSColors.primaryMaroon,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "Share your feedback and thoughts on school events",
                      style: TextStyle(color: YPSColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fade(delay: 50.ms),

        const SizedBox(height: 24),

        const Text(
          "Parent Details",
          style: TextStyle(color: YPSColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
        ).animate().fade(delay: 100.ms),
        const SizedBox(height: 12),

        // Parent Name Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(color: YPSColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: YPSColors.primaryMaroon),
              hintText: "Parent Full Name",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ).animate().fade(delay: 150.ms),

        const SizedBox(height: 12),

        // Parent Email Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: YPSColors.textPrimary),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.alternate_email, color: YPSColors.primaryMaroon),
              hintText: "Parent Email Address (e.g. parent@example.com)",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ).animate().fade(delay: 200.ms),

        const SizedBox(height: 28),

        const Text("Rate your event experience", style: TextStyle(color: YPSColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)).animate().fade(delay: 250.ms),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: index < _selectedRating ? YPSColors.heritageGold : Colors.grey.shade400,
                  size: 36,
                ),
                onPressed: () => setState(() => _selectedRating = index + 1),
              ).animate(target: index < _selectedRating ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1));
            }),
          ),
        ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

        const SizedBox(height: 24),

        const Text("Comments & Suggestions", style: TextStyle(color: YPSColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)).animate().fade(delay: 350.ms),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: TextField(
            controller: _commentsController,
            maxLines: 5,
            style: const TextStyle(color: YPSColors.textPrimary),
            decoration: const InputDecoration(
              hintText: "Type your event comments or suggestions here...",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ).animate().fade(delay: 400.ms),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Submit Anonymously", style: TextStyle(color: YPSColors.textPrimary, fontWeight: FontWeight.bold)),
            Switch(value: _isAnonymous, onChanged: (val) => setState(() => _isAnonymous = val), activeThumbColor: YPSColors.primaryMaroon),
          ],
        ).animate().fade(delay: 450.ms),

        const SizedBox(height: 32),
        GestureDetector(
          onTap: _isSubmitting ? null : _submitFeedback,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: YPSColors.primaryMaroon,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: YPSColors.primaryMaroon.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Center(
              child: _isSubmitting 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text("Submit Event Feedback", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
        ).animate().fade(delay: 500.ms).slideY(begin: 0.2),

        const SizedBox(height: 48),

        // Bottom Quick Action Buttons
        const QuickActionsBottomBar(
          currentScreen: 'feedback',
        ),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
          ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 24),
          Text("Thank You!", style: YPSTypography.cinematicHeader.copyWith(fontSize: 32)).animate().fade(delay: 300.ms),
          const SizedBox(height: 12),
          const Text("Your event feedback has been submitted\nto the school administration.", textAlign: TextAlign.center, style: TextStyle(color: YPSColors.textSecondary, fontSize: 16)).animate().fade(delay: 400.ms),
          const SizedBox(height: 48),
          const QuickActionsBottomBar(
            currentScreen: 'feedback',
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}