import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../common/services/auth_service.dart';
import '../../social/controllers/social_controller.dart';
import '../models/private_lobby.dart';

enum _VoteState { none, upvoted, downvoted }

class GroupPostSessionPage extends StatefulWidget {
  const GroupPostSessionPage({super.key, required this.participants});

  final List<PrivateLobby> participants;

  @override
  State<GroupPostSessionPage> createState() => _GroupPostSessionPageState();
}

class _GroupPostSessionPageState extends State<GroupPostSessionPage> {
  late final List<PrivateLobby> _participants;
  // Tracks vote state per participant userId for this session.
  final Map<String, _VoteState> _votes = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final currentUserId = context.read<AuthService>().currentUser?.id;
      _participants = widget.participants
          .where((p) => p.userId != currentUserId)
          .toList();
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

  Future<void> _handleVote(String userId, bool isUpvote) async {
    final social = context.read<SocialController>();
    final current = _votes[userId] ?? _VoteState.none;

    int delta;
    _VoteState next;

    if (isUpvote) {
      switch (current) {
        case _VoteState.none:
          delta = 1;
          next = _VoteState.upvoted;
        case _VoteState.upvoted:
          // Toggle off
          delta = -1;
          next = _VoteState.none;
        case _VoteState.downvoted:
          // Flip from down to up: cancel -1 and add +1 = net +2
          delta = 2;
          next = _VoteState.upvoted;
      }
    } else {
      switch (current) {
        case _VoteState.none:
          delta = -1;
          next = _VoteState.downvoted;
        case _VoteState.downvoted:
          // Toggle off
          delta = 1;
          next = _VoteState.none;
        case _VoteState.upvoted:
          // Flip from up to down: cancel +1 and add -1 = net -2
          delta = -2;
          next = _VoteState.downvoted;
      }
    }

    setState(() => _votes[userId] = next);

    try {
      await social.vote(userId, delta);
    } catch (_) {
      // Revert optimistic update on failure
      setState(() => _votes[userId] = current);
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
              // Header row: title + member count badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Expedition Squad',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_participants.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_participants.length} CLIMBERS',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = _participants[index];
                          final isFollowing = social.following
                              .any((u) => u.id == p.userId);
                          final isBlocked = social.blockedIds.contains(p.userId);
                          final voteState = _votes[p.userId] ?? _VoteState.none;
                          final knownUser = [
                            ...social.followers,
                            ...social.following,
                          ].where((u) => u.id == p.userId).firstOrNull;
                          return _ParticipantCard(
                            username: p.username,
                            profileImageUrl: knownUser?.profileImageUrl,
                            level: knownUser?.level,
                            isFollowing: isFollowing,
                            isBlocked: isBlocked,
                            voteState: voteState,
                            onFollowTap: () =>
                                _toggleFollow(context, p.userId, isFollowing),
                            onAvoidTap: () =>
                                _toggleBlock(context, p.userId, isBlocked),
                            onUpvoteTap: () => _handleVote(p.userId, true),
                            onDownvoteTap: () => _handleVote(p.userId, false),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.action.withValues(alpha: 0.38),
                      blurRadius: 22,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.shell,
                    (_) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.action,
                    foregroundColor: AppColors.primaryBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    'Quit to Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBg,
                    ).copyWith(inherit: false),
                  ),
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
    required this.voteState,
    required this.onFollowTap,
    required this.onAvoidTap,
    required this.onUpvoteTap,
    required this.onDownvoteTap,
    this.profileImageUrl,
    this.level,
  });

  final String username;
  final String? profileImageUrl;
  final int? level;
  final bool isFollowing;
  final bool isBlocked;
  final _VoteState voteState;
  final VoidCallback onFollowTap;
  final VoidCallback onAvoidTap;
  final VoidCallback onUpvoteTap;
  final VoidCallback onDownvoteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            children: [
              _Avatar(username: username, imageUrl: profileImageUrl),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (level != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'LVL $level',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Vote buttons grouped
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _VoteButton(
                  icon: Icons.thumb_up_rounded,
                  active: voteState == _VoteState.upvoted,
                  activeColor: const Color(0xFF22C55E),
                  onTap: onUpvoteTap,
                ),
                _VoteButton(
                  icon: Icons.thumb_down_rounded,
                  active: voteState == _VoteState.downvoted,
                  activeColor: AppColors.failure,
                  onTap: onDownvoteTap,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Follow button
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onFollowTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isFollowing ? Colors.transparent : AppColors.accent,
                foregroundColor:
                    isFollowing ? AppColors.accent : AppColors.primaryBg,
                side: isFollowing
                    ? BorderSide(color: AppColors.accent.withValues(alpha: 0.4), width: 1)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(70, 34),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              child: Text(isFollowing ? 'Following' : 'Follow'),
            ),
          ),
          const SizedBox(width: 4),
          // Block/Avoid icon button
          GestureDetector(
            onTap: onAvoidTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.block_rounded,
                size: 20,
                color: isBlocked
                    ? AppColors.failure
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Icon(
          icon,
          size: 17,
          color: active ? activeColor : AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, this.imageUrl});

  final String username;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial =
        username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              initial,
              style: GoogleFonts.montserrat(
                color: AppColors.accent,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
