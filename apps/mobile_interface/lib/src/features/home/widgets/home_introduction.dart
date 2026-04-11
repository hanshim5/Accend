import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/constants.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final int currentMinutes;
  final int totalMinutes;
  final int streak;
  final double progress;
  final VoidCallback? onKeepGoing;
  final bool isLoading;
  final bool compact;

  const GoalCard({
    super.key,
    required this.title,
    required this.currentMinutes,
    required this.totalMinutes,
    required this.streak,
    required this.progress,
    this.onKeepGoing,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final baseScale = compact ? 0.9 : 1.0;
          final heightScale = (constraints.maxHeight / 150).clamp(0.72, 1.0);
          final scale = baseScale * heightScale;

          final padding = 16.0 * scale;
          final titleSize = 18.0 * scale;
          final topLabelSize = 12.0 * scale;
          final bodySize = 12.0 * scale;
          final streakEmojiSize = 12.0 * scale;
          final progressBarHeight = (8.0 * scale).clamp(4.0, 8.0);
          final keepGoingWidth = (160.0 * scale).clamp(110.0, 160.0);
          final keepGoingHeight = (44.0 * scale).clamp(30.0, 44.0);
          final keepGoingTextSize = (14.0 * scale).clamp(10.0, 14.0);

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TODAY’S GOAL",
                      style: TextStyle(
                        color: const Color(0xFF16C6F3),
                        fontSize: topLabelSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("🔥", style: TextStyle(fontSize: streakEmojiSize)),
                          SizedBox(width: 4 * scale),
                          Flexible(
                            child: Text(
                              "$streak Day Streak",
                              style: TextStyle(
                                color: const Color(0xFF98A2B3),
                                fontSize: bodySize,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$currentMinutes/$totalMinutes minutes",
                      style: TextStyle(
                        color: const Color(0xFF98A2B3),
                        fontSize: bodySize,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        color: const Color(0xFF98A2B3),
                        fontSize: bodySize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5 * scale),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: progressBarHeight,
                    backgroundColor: const Color(0xFF25324A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16C6F3)),
                  ),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: keepGoingWidth,
                    height: keepGoingHeight,
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
                      child: Text(
                        "Keep Going",
                        style: TextStyle(
                          fontSize: keepGoingTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}