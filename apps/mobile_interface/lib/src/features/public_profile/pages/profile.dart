import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../app/routes.dart';
import '../controllers/public_profile_controller.dart';
import '../models/profile_page_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _fullNameCtrl = TextEditingController();
  String? _fullNameError;
  String? _goalsError;

  bool _detailsExpanded = true;
  bool _preferencesExpanded = false;

  final List<String> _languageOptions = const [
    'English',
    'Spanish',
    'French',
    'Japanese',
    'Korean',
    'Mandarin',
    'Cantonese',
    'Wu',
    'Vietnamese',
    'Ilocano',
    'Tagalog',
    'Russian',
    'Arabic',
    'Georgian',
    'German',
    'Latin',
    'Bulgarian',
    'Scandanavian',
    'Sinhala',
    'Hindi',
    'Portuguese',
    'Nepali',
    'Signese',
    'Braille',
    'Hausa',
    'Yoruba',
    'Igbo',
    'Swedish',
    'Italian',
    'Greek',
    'Pidgin',
  ];
  final Map<String, String> _accentOptions = const {
    'californian': 'Californian',
    'british': 'British',
    'southern': 'Southern',
    'australian': 'Australian',
  };
  final Map<String, String> _dailyPaceOptions = const {
    'hiker': 'Hiker',
    'climber': 'Climber',
    'summiter': 'Summiter',
    'mountaineer': 'Mountaineer',
  };
  final Map<String, String> _toneOptions = const {
    'passionate': 'Passionate',
    'supportive': 'Supportive',
    'neutral': 'Neutral',
    'strict': 'Strict',
  };
  String? _selectedTone;
  String? _selectedNativeLanguage;
  String? _selectedAccent;
  String? _selectedDailyPace;
  final List<String> _selectedGoals = [];
  final List<String> _selectedFocusAreas = [];

  String? _hydratedProfileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PublicProfileController>().load();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.social);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 2:
        break; // already here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PublicProfileController>(
      builder: (context, profileCtrl, _) {
        if (profileCtrl.isLoading && profileCtrl.data == null) {
          return const Scaffold(
            backgroundColor: AppColors.primaryBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profileCtrl.error != null && profileCtrl.data == null) {
          return Scaffold(
            backgroundColor: AppColors.primaryBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load profile',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profileCtrl.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => profileCtrl.load(force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = profileCtrl.data;
        if (data == null) {
          return const Scaffold(
            backgroundColor: AppColors.primaryBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _hydrateFormIfNeeded(data);

        return _buildLoaded(
          context,
          data,
          profileCtrl.isLoading,
          profileCtrl.isSaving,
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    ProfilePageData data,
    bool isRefreshing,
    bool isSaving,
  ) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (isRefreshing) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 10),
                  ],
                  _ProfileHero(
                    data: data,
                    nativeLanguage: _selectedNativeLanguage ?? '',
                    goals: _selectedGoals,
                  ),
                  const SizedBox(height: 18),
                  const _StatsPanel(),
                  const SizedBox(height: 18),
                  _SpecializedFocusSection(
                    selected: _selectedFocusAreas,
                    onToggle: (area) {
                      final alreadySelected = _selectedFocusAreas.contains(area);
                      if (!alreadySelected && _selectedFocusAreas.length >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You can select up to 3 focus areas.')),
                        );
                        return;
                      }

                      setState(() {
                        if (alreadySelected) {
                          _selectedFocusAreas.remove(area);
                        } else {
                          _selectedFocusAreas.add(area);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  _CollapsibleCard(
                    title: 'Profile Details',
                    expanded: _detailsExpanded,
                    onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
                    child: Column(
                      children: [
                        _EditableField(
                          label: 'Full Name',
                          controller: _fullNameCtrl,
                          errorText: _fullNameError,
                          onChanged: (value) => setState(() => _fullNameError = _validateFullName(value)),
                        ),
                        const SizedBox(height: 14),
                        _DetailField(label: 'Email Address', value: data.email),
                        const SizedBox(height: 14),
                        _SelectableField(
                          label: 'Native Language',
                          child: _OptionDropdown(
                            hint: 'Select native language',
                            options: {
                              for (final language in _languageOptions) language: language,
                            },
                            value: _selectedNativeLanguage,
                            onChanged: (value) => setState(() => _selectedNativeLanguage = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CollapsibleCard(
                    title: 'Preferences',
                    expanded: _preferencesExpanded,
                    onToggle: () => setState(() => _preferencesExpanded = !_preferencesExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _InfoLabel('Teaching Tone'),
                        const SizedBox(height: 8),
                        _ToneDropdown(
                          options: _toneOptions,
                          value: _selectedTone,
                          onChanged: (value) => setState(() => _selectedTone = value),
                        ),
                        const SizedBox(height: 16),
                        const _InfoLabel('Goals'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._selectedGoals.map(
                              (goal) => _GoalChip(
                                label: goal,
                                onRemove: () => _removeGoal(goal),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openAddGoalPopup,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Add Goal',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: Color(0xFF334155)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                            ),
                          ],
                        ),
                        if (_goalsError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _goalsError!,
                            style: GoogleFonts.manrope(
                              color: AppColors.failure,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _SelectableField(
                          label: 'Accent',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OptionDropdown(
                                hint: 'Select accent',
                                options: _accentOptions,
                                value: _selectedAccent,
                                disabledOptions: const {
                                  'british',
                                  'southern',
                                  'australian',
                                },
                                unavailableLabelSuffix: ' (coming soon)',
                                onChanged: (value) => setState(() => _selectedAccent = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SelectableField(
                          label: 'Daily Pace',
                          child: _OptionDropdown(
                            hint: 'Select daily pace',
                            options: _dailyPaceOptions,
                            value: _selectedDailyPace,
                            onChanged: (value) => setState(() => _selectedDailyPace = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PrimaryAction(
                    label: isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: isSaving
                        ? null
                        : () => _saveChanges(context, context.read<PublicProfileController>()),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SecondaryAction(label: 'Log Out', onPressed: () {}),
                          const SizedBox(height: 10),
                          _DangerAction(label: 'Delete Account', onPressed: () {}),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onDestinationSelected: (i) => _onNavTap(context, i),
      ),
    );
  }

  void _hydrateFormIfNeeded(ProfilePageData data) {
    if (_hydratedProfileId == data.id) {
      return;
    }
    _hydratedProfileId = data.id;
    _fullNameCtrl.text = data.fullName ?? '';
    _selectedNativeLanguage = _matchLanguage(data.nativeLanguage);
    _selectedTone = _matchKey(_toneOptions, data.feedbackTone);
    _selectedGoals
      ..clear()
      ..addAll(_splitGoals(data.learningGoal));
    _selectedAccent = _matchKey(_accentOptions, data.accent);
    _selectedDailyPace = _matchKey(_dailyPaceOptions, data.dailyPace);
    _selectedFocusAreas
      ..clear()
      ..addAll(_splitFocusAreas(data.focusAreas));
  }

  List<String> _splitGoals(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    final goals = <String>[];
    final seen = <String>{};
    for (final part in raw.split(RegExp(r'[,;/]'))) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final normalized = _normalizeGoal(trimmed);
      if (seen.add(normalized)) {
        goals.add(_canonicalGoalLabel(trimmed));
      }
    }
    return goals;
  }

  String _normalizeGoal(String value) => value.trim().toLowerCase();

  String _canonicalGoalLabel(String value) {
    final trimmed = value.trim();
    const canonical = {
      'hobby': 'Hobby',
      'school': 'School',
      'brain training': 'Brain Training',
      'brain_training': 'Brain Training',
      'culture': 'Culture',
      'travel': 'Travel',
      'career': 'Career',
    };
    return canonical[_normalizeGoal(trimmed)] ?? trimmed;
  }

  String _goalToBackendValue(String value) {
    final normalized = _normalizeGoal(value);
    const backend = {
      'hobby': 'hobby',
      'school': 'school',
      'brain training': 'brain_training',
      'brain_training': 'brain_training',
      'culture': 'culture',
      'travel': 'travel',
      'career': 'career',
    };
    return backend[normalized] ?? normalized.replaceAll(' ', '_');
  }

  String? _validateGoals() {
    if (_selectedGoals.isEmpty) {
      return 'Select at least 1 goal.';
    }
    return null;
  }

  String? _matchLanguage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    for (final option in _languageOptions) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }
    return value.trim();
  }

  String? _matchKey(Map<String, String> options, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    for (final entry in options.entries) {
      if (entry.key.toLowerCase() == normalized || entry.value.toLowerCase() == normalized) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _openAddGoalPopup() async {
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _AddGoalPopup(),
    );

    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }

    setState(() {
      final normalized = _normalizeGoal(selected);
      if (_selectedGoals.every((goal) => _normalizeGoal(goal) != normalized)) {
        _selectedGoals.add(_canonicalGoalLabel(selected));
      }
      _goalsError = null;
    });
  }

  void _removeGoal(String goal) {
    if (_selectedGoals.length <= 1) {
      setState(() => _goalsError = 'Select at least 1 goal.');
      return;
    }

    setState(() {
      _selectedGoals.remove(goal);
      _goalsError = null;
    });
  }

  List<String> _splitFocusAreas(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => _canonicalFocusLabel(s))
        .toSet()
        .toList();
  }

  String _canonicalFocusLabel(String value) {
    const canonical = {
      'vocabulary': 'Vocabulary',
      'grammar': 'Grammar',
      'slang': 'Slang',
      'pronunciation': 'Pronunciation',
      'listening': 'Listening',
      'conversation': 'Conversation',
    };
    return canonical[value.trim().toLowerCase()] ?? value.trim();
  }

  String? _validateFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Full name is required.';
    }
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters.';
    }
    if (!RegExp(r"^[A-Za-z][A-Za-z '.-]*$").hasMatch(trimmed)) {
      return 'Enter a valid name.';
    }
    return null;
  }

  Future<void> _saveChanges(BuildContext context, PublicProfileController controller) async {
    final fullNameError = _validateFullName(_fullNameCtrl.text);
    final goalsError = _validateGoals();

    if (fullNameError != null) {
      setState(() {
        _fullNameError = fullNameError;
        _goalsError = goalsError;
      });
      return;
    }

    if (goalsError != null) {
      setState(() {
        _fullNameError = null;
        _goalsError = goalsError;
      });
      return;
    }

    setState(() {
      _fullNameError = null;
      _goalsError = null;
    });

    try {
      await controller.saveProfileDetails(
        fullName: _fullNameCtrl.text,
        nativeLanguage: _selectedNativeLanguage ?? '',
        learningGoal: _selectedGoals.map(_goalToBackendValue).join(', '),
        feedbackTone: _selectedTone ?? '',
        accent: _selectedAccent ?? '',
        dailyPace: _selectedDailyPace ?? '',
        focusAreas: _selectedFocusAreas.map((s) => s.toLowerCase()).join(', '),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Failed to update profile.'),
          backgroundColor: AppColors.failure,
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 69,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'Profile',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.45,
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.data,
    required this.nativeLanguage,
    required this.goals,
  });

  final ProfilePageData data;
  final String nativeLanguage;
  final List<String> goals;

  String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4C06B6D4),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E293B),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsFor(data.displayName),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1906F9F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x3306F9F9)),
              ),
              child: Text(
                data.levelLabel.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF06F9F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.displayName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${data.username}',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.action, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '## Day Streak',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: 'I am learning '),
                      const TextSpan(text: 'English', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                      const TextSpan(text: '. My native language is '),
                      TextSpan(
                        text: nativeLanguage.trim().isNotEmpty ? nativeLanguage.trim() : 'not set',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '. I am doing this for '),
                      TextSpan(
                        text: goals.isEmpty ? 'continuous improvement' : goals.join(', '),
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;

    return Container(
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatsSummary(),
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 12),
                const _ActivityBars(),
              ],
            )
          : Row(
              children: [
                const Expanded(flex: 6, child: _StatsSummary()),
                Container(
                  width: 1,
                  height: 96,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                const Expanded(flex: 4, child: _ActivityBars()),
              ],
            ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x1906B6D4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.track_changes_rounded, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '##',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.33,
                  ),
                ),
                Text(
                  'OVERALL\nACCURACY',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '##',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.56,
                    ),
                  ),
                  Text(
                    'LESSONS COMPLETED',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '##',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.56,
                    ),
                  ),
                  Text(
                    'METERS CLIMBED',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars();

  @override
  Widget build(BuildContext context) {
    final heights = [28.0, 42.0, 38.0, 48.0, 58.0];
    final colors = const [
      Color(0x1AFFFFFF),
      Color(0x4C06B6D4),
      Color(0x7F06B6D4),
      Color(0xB206B6D4),
      Color(0xFF06B6D4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ACTIVITY',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 84,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final totalGap = gap * (heights.length - 1);
              final rawBarWidth = (constraints.maxWidth - totalGap) / heights.length;
              final barWidth = rawBarWidth.clamp(8.0, 24.0);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  heights.length,
                  (index) => Container(
                    width: barWidth,
                    height: heights[index],
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'LAST 5 DAYS',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
class _CollapsibleCard extends StatelessWidget {
  const _CollapsibleCard({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: child,
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLabel(label),
        const SizedBox(height: 8),
        _FieldShell(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLabel(label),
        const SizedBox(height: 8),
        _FieldShell(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isCollapsed: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: GoogleFonts.manrope(
              color: AppColors.failure,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class _SelectableField extends StatelessWidget {
  const _SelectableField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLabel(label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.disabledOptions = const <String>{},
    this.unavailableLabelSuffix = '',
  });

  final String hint;
  final Map<String, String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final Set<String> disabledOptions;
  final String unavailableLabelSuffix;

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.containsKey(value) && !disabledOptions.contains(value) ? value : null;

    return _FieldShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textSecondary,
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          hint: Text(
            hint,
            style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 16),
          ),
          items: options.entries
              .map(
                (entry) {
                  final isDisabled = disabledOptions.contains(entry.key);
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    enabled: !isDisabled,
                    child: Text(
                      isDisabled ? '${entry.value}$unavailableLabelSuffix' : entry.value,
                      style: GoogleFonts.manrope(
                        color: isDisabled ? AppColors.textSecondary : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: AppColors.primaryBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: const Color(0x19F6B17A),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(45),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
      ),
    );
  }
}

class _DangerAction extends StatelessWidget {
  const _DangerAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFEF4444)),
        foregroundColor: const Color(0xFFEF4444),
        minimumSize: const Size.fromHeight(45),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
      ),
    );
  }
}

class _ToneDropdown extends StatelessWidget {
  const _ToneDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Map<String, String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = (value != null && options.containsKey(value)) ? value : null;
    return _FieldShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textSecondary,
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          hint: Text(
            'Select tone',
            style: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 16),
          ),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12),
      ),
      backgroundColor: const Color(0x1906B6D4),
      side: BorderSide.none,
      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
      onDeleted: onRemove,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _AddGoalPopup extends StatefulWidget {
  const _AddGoalPopup();

  @override
  State<_AddGoalPopup> createState() => _AddGoalPopupState();
}

class _AddGoalPopupState extends State<_AddGoalPopup> {
  static const _goalOptions = <_GoalOption>[
    _GoalOption('Hobby', Icons.palette_outlined),
    _GoalOption('School', Icons.school_outlined),
    _GoalOption('Brain Training', Icons.psychology_outlined),
    _GoalOption('Culture', Icons.public_outlined),
    _GoalOption('Travel', Icons.flight_takeoff_outlined),
    _GoalOption('Career', Icons.work_outline_rounded),
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Goal',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'What is the focus of your ascent?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _goalOptions
                  .map(
                    (goal) => _GoalOptionTile(
                      option: goal,
                      selected: _selected == goal.label,
                      onTap: () => setState(() => _selected = goal.label),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBg,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Add Goal',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFAEB4C1),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SpecializedFocusSection extends StatelessWidget {
  const _SpecializedFocusSection({
    required this.selected,
    required this.onToggle,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;

  static const _areas = [
    'Vocabulary',
    'Grammar',
    'Slang',
    'Pronunciation',
    'Listening',
    'Conversation',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Specialized Focus',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Select up to 3)',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < _areas.length; i++) ...[
                _FocusAreaCard(
                  label: _areas[i],
                  selected: selected.contains(_areas[i]),
                  onTap: () => onToggle(_areas[i]),
                ),
                if (i < _areas.length - 1) const SizedBox(width: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FocusAreaCard extends StatelessWidget {
  const _FocusAreaCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: AppColors.accent, width: 1.5)
              : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x660F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.accent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalOptionTile extends StatelessWidget {
  const _GoalOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _GoalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 84,
        height: 98,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF334155) : const Color(0xFF2D3250),
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: AppColors.accent) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x1906B6D4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(option.icon, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: option.label.length > 11 ? 10 : 12,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}