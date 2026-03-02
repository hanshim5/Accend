// learning_goal.dart
import 'package:flutter/material.dart';

void main() => runApp(const LearningGoalApp());

class LearningGoalApp extends StatelessWidget {
  const LearningGoalApp({super.key});

  // Palette
  static const Color primBg = Color(0xFF0F172A);
  static const Color primAccent = Color(0xFF06B6D4);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color cardStroke = Color(0x7F334155);
  static const Color actionHighlight = Color(0xFFF6B17A);
  static const Color secText = Color(0xFF94A3B8);
  static const Color primText = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Goal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: primBg,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: primText,
              displayColor: primText,
            ),
      ),
      home: const Scaffold(
        body: SafeArea(child: LearningGoalPage()),
      ),
    );
  }
}

class LearningGoalPage extends StatefulWidget {
  const LearningGoalPage({super.key});

  @override
  State<LearningGoalPage> createState() => _LearningGoalPageState();
}

class _LearningGoalPageState extends State<LearningGoalPage> {
  int? _selectedIndex;

  final List<_GoalOption> _options = const [
    _GoalOption(title: 'Travel', subtitle: 'Speak while traveling'),
    _GoalOption(title: 'Career', subtitle: 'Advance my job prospects'),
    _GoalOption(title: 'Culture', subtitle: 'Connect with people & media'),
    _GoalOption(title: 'Brain Training', subtitle: 'Improve memory & thinking'),
  ];

  void _onSelect(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    // Overall padding used throughout
    const horizontalPadding = 20.0;
    const verticalPadding = 18.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        children: [
          // Top row: step + title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'STEP 2 OF 5',
                style: TextStyle(
                  color: LearningGoalApp.primAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Learning Goal',
                style: TextStyle(
                  color: LearningGoalApp.secText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar (STEP 2)
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: LearningGoalApp.cardBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.4, // 2 of 5 = 40%
              child: Container(
                decoration: BoxDecoration(
                  color: LearningGoalApp.primAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Heading + subtitle
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Why',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: LearningGoalApp.primAccent,
                  ),
                ),
                TextSpan(
                  text: ' are you learning?',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: LearningGoalApp.primText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This will help the AI determine your coursework.',
            style: TextStyle(
              color: LearningGoalApp.secText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // Expanded region for the 2x2 grid — it will fill the remaining space
          // and we compute the grid childAspectRatio to keep cards from overflowing.
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              // constraints.maxWidth = available width inside padding
              // constraints.maxHeight = available height for the grid
              // We'll use 2 columns and 2 rows (4 items). We want each card to be
              // roughly half the width and half the height of the grid area.
              final gridWidth = constraints.maxWidth;
              final gridHeight = constraints.maxHeight;
              // width per card (2 columns)
              final cardWidth = (gridWidth - 16) / 2; // 16 is horizontal spacing between columns
              // height per card (2 rows)
              final cardHeight = (gridHeight - 12) / 2; // 12 is vertical spacing between rows
              final childAspectRatio = cardWidth / cardHeight;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio > 0 ? childAspectRatio : 1,
                ),
                itemBuilder: (context, idx) {
                  final opt = _options[idx];
                  final selected = _selectedIndex == idx;
                  return GestureDetector(
                    onTap: () => _onSelect(idx),
                    child: OptionCard(
                      title: opt.title,
                      subtitle: opt.subtitle,
                      selected: selected,
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 12),

          // Continue button (fixed size)
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedIndex == null
                  ? null
                  : () {
                      // handle continue
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedIndex == null ? LearningGoalApp.cardBg : LearningGoalApp.actionHighlight,
                foregroundColor: LearningGoalApp.primBg,
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

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;

  const OptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LearningGoalApp.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? LearningGoalApp.primAccent : LearningGoalApp.cardStroke,
          width: selected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // circular icon placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: selected ? LearningGoalApp.primAccent.withOpacity(0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.star,
              size: 32,
              color: selected ? LearningGoalApp.primAccent : LearningGoalApp.secText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LearningGoalApp.primText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LearningGoalApp.secText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  final String title;
  final String subtitle;
  const _GoalOption({required this.title, required this.subtitle});
}