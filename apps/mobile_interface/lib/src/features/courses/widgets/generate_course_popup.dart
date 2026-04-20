import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants.dart';

class GenerateCoursePopup extends StatefulWidget {
  const GenerateCoursePopup({
    super.key,
    required this.onSubmitPrompt,
    required this.onSubmitMetrics,
  });

  final void Function(String prompt) onSubmitPrompt;
  final VoidCallback onSubmitMetrics;

  @override
  State<GenerateCoursePopup> createState() => _GenerateCoursePopupState();
}

class _GenerateCoursePopupState extends State<GenerateCoursePopup>
    with TickerProviderStateMixin {
  // Icon pops in after the dialog entrance settles — same pattern as _TimeUpDialog.
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

  // Tab controller for By Topic / By Phonemes.
  late final TabController _tabCtrl;

  final _promptCtrl = TextEditingController();
  String? _promptError;

  @override
  void initState() {
    super.initState();

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOutQuart),
    );
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _iconCtrl.forward();
    });

    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _tabCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _promptError = 'Please enter a topic.');
      return;
    }
    setState(() => _promptError = null);
    Navigator.of(context).pop();
    widget.onSubmitPrompt(prompt);
  }

  void _submitMetrics() {
    Navigator.of(context).pop();
    widget.onSubmitMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      // Animated icon — identical pattern to _TimeUpDialog.
      icon: ScaleTransition(
        scale: _iconScale,
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.accent,
          size: 32,
        ),
      ),
      title: Text(
        'Generate New Course?',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      // Tighter than the AlertDialog default (fromLTRB(24,20,24,24)) to prevent
      // the content from overflowing on smaller screens.
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab bar — underline indicator, no background container.
          TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            dividerColor: AppColors.border,
            // Remove the default 16px per-side padding so the Row content
            // never overflows the tab slot on narrow screens.
            labelPadding: EdgeInsets.zero,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('By Topic'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq_rounded, size: 15),
                    SizedBox(width: 5),
                    Text('By Phonemes'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // IndexedStack lays out both tabs at once and sizes itself to the
          // tallest child (the topic tab), so the dialog never resizes when
          // the user switches tabs.
          IndexedStack(
            index: _tabCtrl.index,
            children: [
              _buildTopicTab(),
              _buildPhonemeTab(),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              'MAYBE LATER',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicTab() {
    return Column(
      key: const ValueKey('topic'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter a topic and our AI will craft a course for you.',
          style: GoogleFonts.publicSans(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptCtrl,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitPrompt(),
          style: GoogleFonts.publicSans(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: const InputDecoration(
            hintText: 'Enter a topic (e.g. Conversations)',
          ),
        ),
        if (_promptError != null) ...[
          const SizedBox(height: 8),
          Text(
            _promptError!,
            style: GoogleFonts.inter(
              color: AppColors.failure,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _submitPrompt,
          child: const Text("Yes, Let's Go!"),
        ),
      ],
    );
  }

  Widget _buildPhonemeTab() {
    return Column(
      key: const ValueKey('phonemes'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.insights_rounded,
              size: 15,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Our AI will analyse your weakest phonemes and build a course designed to target them.',
                style: GoogleFonts.publicSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: AppColors.action,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Requires at least one completed pronunciation session.',
                style: GoogleFonts.publicSans(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _submitMetrics,
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate'),
        ),
      ],
    );
  }
}
