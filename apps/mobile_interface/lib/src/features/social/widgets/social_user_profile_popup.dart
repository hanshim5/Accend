import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/common/utils/metric_formatters.dart';

import '../models/social_user.dart';

Future<void> showSocialUserProfilePopup({
  required BuildContext context,
  required SocialUser user,
  required VoidCallback onPrimaryAction,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SocialUserProfilePopup(
      user: user,
      onPrimaryAction: onPrimaryAction,
    ),
  );
}

class _SocialUserProfilePopup extends StatelessWidget {
  const _SocialUserProfilePopup({
    required this.user,
    required this.onPrimaryAction,
  });

  final SocialUser user;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final isFollowing = user.iFollow;
    final nativeLanguage = (user.nativeLanguage?.trim().isNotEmpty ?? false)
        ? user.nativeLanguage!.trim()
        : 'not set';
    final goalsText = _goalsLabel(user.learningGoalCsv);
    final focusAreas = _parseFocusAreas(user.focusAreasCsv);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 384,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 50,
              offset: Offset(0, 25),
              spreadRadius: -12,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1)),
                  splashRadius: 20,
                ),
              ),
              _PopupAvatar(initials: _initialsFromName(user.displayName)),
              const SizedBox(height: 10),
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: GoogleFonts.montserrat(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x3307B6D5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x4C07B6D5)),
                ),
                child: Text(
                  (user.levelLabel?.trim().isNotEmpty ?? false)
                      ? user.levelLabel!.toUpperCase()
                      : 'LEVEL ##',
                  style: GoogleFonts.montserrat(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF243248),
                  borderRadius: BorderRadius.circular(12),
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
                      const TextSpan(
                        text: 'English',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '. My native language is '),
                      TextSpan(
                        text: nativeLanguage,
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '. I am doing this for '),
                      TextSpan(
                        text: goalsText,
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Focus Areas',
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: focusAreas
                      .map(
                        (area) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0x1906B6D4),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x3306B6D4)),
                          ),
                          child: Text(
                            area,
                            style: GoogleFonts.montserrat(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.72,
                children: [
                  _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Color(0xFFF97316),
                    label: 'STREAK',
                    value: '${user.currentStreak} Days',
                  ),
                  _MetricCard(
                    icon: Icons.insights_rounded,
                    iconColor: AppColors.accent,
                    label: 'ACCURACY',
                    value: user.overallAccuracy <= 0
                        ? '--'
                        : '${user.overallAccuracy.toStringAsFixed(0)}%',
                  ),
                  _MetricCard(
                    icon: Icons.translate_rounded,
                    iconColor: Color(0xFFCBD5E1),
                    label: 'LESSONS COMPLETED',
                    value: '${user.lessonsCompleted}',
                  ),
                  _MetricCard(
                    icon: Icons.military_tech_rounded,
                    iconColor: Color(0xFFFACC15),
                    label: 'METERS CLIMBED',
                    value: formatMetersClimbed(user.metersClimbed),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onPrimaryAction();
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    isFollowing ? Icons.person_remove_rounded : Icons.person_add_rounded,
                    size: 18,
                  ),
                  label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isFollowing ? Colors.transparent : AppColors.action,
                    foregroundColor: isFollowing ? const Color(0xFFCBD5E1) : AppColors.primaryBg,
                    side: isFollowing
                        ? const BorderSide(color: Color(0x7F64748B), width: 1)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  List<String> _parseFocusAreas(String? csv) {
    if (csv == null || csv.trim().isEmpty) {
      return const ['None'];
    }

    final labels = <String>[];
    final seen = <String>{};

    for (final raw in csv.split(RegExp(r'[,;/]'))) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) {
        continue;
      }

      final normalized = cleaned.toLowerCase();
      if (!seen.add(normalized)) {
        continue;
      }

      labels.add(
        cleaned
            .split(RegExp(r'[_\s]+'))
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
            .join(' '),
      );
    }

    return labels.isEmpty ? const ['None'] : labels;
  }

  String _goalsLabel(String? csv) {
    if (csv == null || csv.trim().isEmpty) {
      return 'continuous improvement';
    }

    final labels = <String>[];
    final seen = <String>{};

    for (final raw in csv.split(RegExp(r'[,;/]'))) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) {
        continue;
      }

      final normalized = cleaned.toLowerCase();
      if (!seen.add(normalized)) {
        continue;
      }

      labels.add(
        cleaned
            .split(RegExp(r'[_\s]+'))
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
            .join(' '),
      );
    }

    return labels.isEmpty ? 'continuous improvement' : labels.join(', ');
  }
}

class _PopupAvatar extends StatelessWidget {
  const _PopupAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6607B6D5),
            blurRadius: 15,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF23324A),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
