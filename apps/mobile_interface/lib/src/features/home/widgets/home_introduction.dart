import 'package:flutter/material.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final int currentMinutes;
  final int totalMinutes;
  final int streak;
  final double progress;
  final VoidCallback? onKeepGoing;
  final bool isLoading;

  const GoalCard({
    super.key,
    required this.title,
    required this.currentMinutes,
    required this.totalMinutes,
    required this.streak,
    required this.progress,
    this.onKeepGoing,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16), // 🔽 smaller padding
      decoration: BoxDecoration(
        color: const Color(0xFF1B2942),
        borderRadius: BorderRadius.circular(20), // slightly smaller
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY’S GOAL",
                style: TextStyle(
                  color: Color(0xFF16C6F3),
                  fontSize: 12, // 🔽 smaller
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Text("🔥", style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    "$streak Day Streak",
                    style: const TextStyle(
                      color: Color(0xFF98A2B3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // 🔽 smaller title
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Progress row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$currentMinutes/$totalMinutes minutes",
                style: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 12,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8, // 🔽 thinner bar
              backgroundColor: const Color(0xFF25324A),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF16C6F3)),
            ),
          ),

          const SizedBox(height: 16),

          // Button
          Center(
            child: SizedBox(
              width: 160, // 🔽 smaller width
              height: 44, // 🔽 smaller height
              child: ElevatedButton(
                onPressed: isLoading ? null : onKeepGoing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0AD72),
                  foregroundColor: const Color(0xFF0B1730),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  "Keep Going",
                  style: TextStyle(
                    fontSize: 14, // 🔽 smaller text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}