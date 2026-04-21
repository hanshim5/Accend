import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../common/services/auth_service.dart';
import '../../social/controllers/social_controller.dart';
import '../models/private_lobby.dart';

class GroupPostSessionPage extends StatefulWidget {
  const GroupPostSessionPage({super.key, required this.participants});

  final List<PrivateLobby> participants;

  @override
  State<GroupPostSessionPage> createState() => _GroupPostSessionPageState();
}

class _GroupPostSessionPageState extends State<GroupPostSessionPage> {
  late final List<PrivateLobby> _participants;

  @override
  void initState() {
    super.initState();
    // Filter and load are deferred to didChangeDependencies where context is safe.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only runs once because _participants is late final.
    if (!_isInitialized) {
      _isInitialized = true;
      final currentUserId = context.read<AuthService>().currentUser?.id;
      _participants = widget.participants
          .where((p) => p.userId != currentUserId)
          .toList();
      // Ensure the following list is up to date so initial button states are correct.
      context.read<SocialController>().load();
    }
  }

  bool _isInitialized = false;

  Future<void> _toggleFollow(
    BuildContext context,
    String userId,
    bool currentlyFollowing,
  ) async {
    final social = context.read<SocialController>();
    if (currentlyFollowing) {
      await social.unfollow(userId);
    } else {
      await social.follow(userId);
    }
  }

  Future<void> _toggleBlock(
    BuildContext context,
    String userId,
    bool currentlyBlocked,
  ) async {
    final social = context.read<SocialController>();
    if (currentlyBlocked) {
      await social.unblock(userId);
    } else {
      await social.block(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final social = context.watch<SocialController>();

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants:',
                style: GoogleFonts.montserrat(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _participants.isEmpty
                    ? Center(
                        child: Text(
                          'No other participants in this session.',
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _participants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = _participants[index];
                        final isFollowing = social.following
                              .any((u) => u.id == p.userId);
                          final isBlocked = social.blockedIds.contains(p.userId);
                          return _ParticipantCard(
                            username: p.username,
                            isFollowing: isFollowing,
                            isBlocked: isBlocked,
                            onFollowTap: () =>
                                _toggleFollow(context, p.userId, isFollowing),
                            onAvoidTap: () =>
                                _toggleBlock(context, p.userId, isBlocked),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (_) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Quit to Sessions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.username,
    required this.isFollowing,
    required this.isBlocked,
    required this.onFollowTap,
    required this.onAvoidTap,
  });

  final String username;
  final bool isFollowing;
  final bool isBlocked;
  final VoidCallback onFollowTap;
  final VoidCallback onAvoidTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _Avatar(username: username),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              style: t.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onFollowTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isFollowing ? Colors.transparent : AppColors.accent,
                foregroundColor:
                    isFollowing ? AppColors.textSecondary : AppColors.primaryBg,
                side: isFollowing
                    ? const BorderSide(color: Color(0x7F64748B), width: 1)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(96, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                textStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(isFollowing ? 'Following' : 'Follow'),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onAvoidTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isBlocked ? AppColors.failure : Colors.transparent,
                foregroundColor:
                    isBlocked ? Colors.white : AppColors.failure,
                side: isBlocked
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.failure, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(96, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                textStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(isBlocked ? 'Avoided' : 'Avoid'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final initial =
        username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.montserrat(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
