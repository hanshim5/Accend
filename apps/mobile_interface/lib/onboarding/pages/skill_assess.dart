// skill_assess.dart
import 'package:flutter/material.dart';

void main() => runApp(const SkillAssessApp());

class SkillAssessApp extends StatelessWidget {
  const SkillAssessApp({super.key});

  // Color palette
  static const Color primBg = Color(0xFF0F172A);
  static const Color primAccent = Color(0xFF06B6D4);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color actionHighlight = Color(0xFFF6B17A);
  static const Color secText = Color(0xFF94A3B8);
  static const Color primText = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Assessment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: primBg,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: primText,
              displayColor: primText,
            ),
      ),
      home: const Scaffold(
        body: SafeArea(child: SkillAssessPage()),
      ),
    );
  }
}

class SkillAssessPage extends StatelessWidget {
  const SkillAssessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      children: [
        // Top row: step + title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'STEP 1 OF 5',
              style: TextStyle(
                color: SkillAssessApp.primAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Skill Assessment',
              style: TextStyle(
                color: SkillAssessApp.secText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Simple progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: SkillAssessApp.cardBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.2, // 20% (STEP 1 of 5)
            child: Container(
              decoration: BoxDecoration(
                color: SkillAssessApp.primAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Heading + subtitle
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'What is your ',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: SkillAssessApp.primText,
                ),
              ),
              TextSpan(
                text: 'current level?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: SkillAssessApp.primAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This helps us customize your learning path.',
          style: TextStyle(
            color: SkillAssessApp.secText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 28),

        // Level cards
        const LevelCard(
          tag: 'BEGINNER',
          title: 'Newbie',
          description: 'I know a few words or I am starting from scratch.',
          isSelected: false,
        ),
        const SizedBox(height: 16),
        const LevelCard(
          tag: 'INTERMEDIATE',
          title: 'Conversationalist',
          description:
              'I can hold basic conversations and understand common topics.',
          isSelected: false,
        ),
        const SizedBox(height: 16),
        const LevelCard(
          tag: 'ADVANCED',
          title: 'Fluent Speaker',
          description:
              'I can speak fluently and understand complex topics.',
          isSelected: true,
        ),

        const SizedBox(height: 28),

        // Continue button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // navigation or callback here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SkillAssessApp.actionHighlight,
              foregroundColor: SkillAssessApp.primBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Continue'),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class LevelCard extends StatelessWidget {
  final String tag;
  final String title;
  final String description;
  final bool isSelected;

  const LevelCard({
    super.key,
    required this.tag,
    required this.title,
    required this.description,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SkillAssessApp.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? SkillAssessApp.primAccent : const Color(0x7F334155),
          width: isSelected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // left column: tag + texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // small tag pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SkillAssessApp.primAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: SkillAssessApp.primBg,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: SkillAssessApp.primText,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: SkillAssessApp.secText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // optional right icon / selection circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? SkillAssessApp.primAccent : SkillAssessApp.cardBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x7F334155)),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: SkillAssessApp.primBg, size: 20)
                : null,
          ),
        ],
      ),
    );
  }
}