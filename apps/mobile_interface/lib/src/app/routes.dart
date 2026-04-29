import 'package:flutter/material.dart';

import '../common/pages/session_results_page.dart';
import '../features/courses/models/lesson_item.dart';
import '../features/login/pages/login_page.dart';
import '../features/login/pages/reset_password_page.dart';

import '../features/onboarding/pages/native_language_page.dart';
import '../features/onboarding/pages/onboarding_user_info_page.dart';
import '../features/onboarding/pages/learning_goal.dart';
import '../features/onboarding/pages/focus_areas.dart';
import '../features/onboarding/pages/daily_goal.dart';
import '../features/onboarding/pages/feedback_tone.dart';
import '../features/onboarding/pages/skill_assess.dart';
import '../features/onboarding/pages/accent_selection.dart';
import '../features/onboarding/pages/onboarding_complete.dart';

import '../features/courses/models/lesson.dart';
import '../features/courses/pages/courses_list_page.dart';
import '../features/home/pages/home.dart';
import '../features/social/pages/social.dart';
import '../features/public_profile/pages/profile.dart';
import '../common/models/pronunciation_feedback.dart';
import '../features/solo_practice/pages/solo_practice_page.dart';

import '../features/group_session/pages/group_session_select_page.dart';
import '../features/group_session/pages/group_session_private_select_page.dart';
import '../features/group_session/pages/group_session_private_create_page.dart';
import '../features/group_session/pages/group_session_private_join_page.dart';
import '../features/group_session/pages/group_session_active_lobby_page.dart';
import '../features/group_session/pages/group_session_public_match_page.dart';
import '../features/group_session/pages/group_post_session_page.dart';
import '../features/group_session/models/private_lobby.dart';

// ---------------------------------------------------------------------------
// Dummy data for group session results — replace when real session data lands
// ---------------------------------------------------------------------------

final _groupDummyItems = [
  LessonItem(id: 'gs-1', lessonId: 'group-session', position: 0, text: 'The quick brown fox jumps over the lazy dog.'),
  LessonItem(id: 'gs-2', lessonId: 'group-session', position: 1, text: 'She sells seashells by the seashore.'),
  LessonItem(id: 'gs-3', lessonId: 'group-session', position: 2, text: 'How much wood would a woodchuck chuck?'),
  LessonItem(id: 'gs-4', lessonId: 'group-session', position: 3, text: 'Peter Piper picked a peck of pickled peppers.'),
];

const _groupDummyFeedbacks = [
  // "The quick brown fox jumps over the lazy dog."
  PronunciationFeedbackMock(
    accuracyScore: 88, fluencyScore: 82, completenessScore: 91, pronScore: 87,
    words: [
      WordFeedback(text: 'The',   accuracy: 95, phonemes: [PhonemeFeedback(symbol: 'dh', accuracy: 95, userSaid: 'dh'), PhonemeFeedback(symbol: 'ax', accuracy: 95, userSaid: 'ax')]),
      WordFeedback(text: 'quick', accuracy: 92, phonemes: [PhonemeFeedback(symbol: 'k', accuracy: 92, userSaid: 'k'), PhonemeFeedback(symbol: 'w', accuracy: 90, userSaid: 'w'), PhonemeFeedback(symbol: 'ih', accuracy: 93, userSaid: 'ih'), PhonemeFeedback(symbol: 'k', accuracy: 92, userSaid: 'k')]),
      WordFeedback(text: 'brown', accuracy: 85, phonemes: [PhonemeFeedback(symbol: 'b', accuracy: 88, userSaid: 'b'), PhonemeFeedback(symbol: 'r', accuracy: 80, userSaid: 'r'), PhonemeFeedback(symbol: 'aw', accuracy: 85, userSaid: 'aw'), PhonemeFeedback(symbol: 'n', accuracy: 90, userSaid: 'n')]),
      WordFeedback(text: 'fox',   accuracy: 90, phonemes: [PhonemeFeedback(symbol: 'f', accuracy: 91, userSaid: 'f'), PhonemeFeedback(symbol: 'aa', accuracy: 88, userSaid: 'aa'), PhonemeFeedback(symbol: 'k', accuracy: 55, userSaid: 'g')]),
      WordFeedback(text: 'jumps', accuracy: 78, phonemes: [PhonemeFeedback(symbol: 'jh', accuracy: 72, userSaid: 'jh'), PhonemeFeedback(symbol: 'ah', accuracy: 80, userSaid: 'ah'), PhonemeFeedback(symbol: 'm', accuracy: 85, userSaid: 'm'), PhonemeFeedback(symbol: 'p', accuracy: 75, userSaid: 'p'), PhonemeFeedback(symbol: 's', accuracy: 78, userSaid: 's')]),
      WordFeedback(text: 'over',  accuracy: 88, phonemes: [PhonemeFeedback(symbol: 'ow', accuracy: 88, userSaid: 'ow'), PhonemeFeedback(symbol: 'v', accuracy: 90, userSaid: 'v'), PhonemeFeedback(symbol: 'er', accuracy: 85, userSaid: 'er')]),
      WordFeedback(text: 'the',   accuracy: 95, phonemes: [PhonemeFeedback(symbol: 'dh', accuracy: 95, userSaid: 'dh'), PhonemeFeedback(symbol: 'ax', accuracy: 95, userSaid: 'ax')]),
      WordFeedback(text: 'lazy',  accuracy: 82, phonemes: [PhonemeFeedback(symbol: 'l', accuracy: 85, userSaid: 'l'), PhonemeFeedback(symbol: 'ey', accuracy: 80, userSaid: 'ey'), PhonemeFeedback(symbol: 'z', accuracy: 78, userSaid: 'z'), PhonemeFeedback(symbol: 'iy', accuracy: 88, userSaid: 'iy')]),
      WordFeedback(text: 'dog',   accuracy: 86, phonemes: [PhonemeFeedback(symbol: 'd', accuracy: 88, userSaid: 'd'), PhonemeFeedback(symbol: 'ao', accuracy: 82, userSaid: 'ao'), PhonemeFeedback(symbol: 'g', accuracy: 88, userSaid: 'g')]),
    ],
  ),

  // "She sells seashells by the seashore."
  PronunciationFeedbackMock(
    accuracyScore: 71, fluencyScore: 68, completenessScore: 75, pronScore: 71,
    words: [
      WordFeedback(text: 'She',       accuracy: 90, phonemes: [PhonemeFeedback(symbol: 'sh', accuracy: 90, userSaid: 'sh'), PhonemeFeedback(symbol: 'iy', accuracy: 92, userSaid: 'iy')]),
      WordFeedback(text: 'sells',     accuracy: 68, phonemes: [PhonemeFeedback(symbol: 's', accuracy: 70, userSaid: 's'), PhonemeFeedback(symbol: 'eh', accuracy: 65, userSaid: 'ae'), PhonemeFeedback(symbol: 'l', accuracy: 72, userSaid: 'l'), PhonemeFeedback(symbol: 'z', accuracy: 68, userSaid: 'z')]),
      WordFeedback(text: 'seashells', accuracy: 58, phonemes: [PhonemeFeedback(symbol: 's', accuracy: 62, userSaid: 's'), PhonemeFeedback(symbol: 'iy', accuracy: 70, userSaid: 'iy'), PhonemeFeedback(symbol: 'sh', accuracy: 52, userSaid: 's'), PhonemeFeedback(symbol: 'eh', accuracy: 55, userSaid: 'ae'), PhonemeFeedback(symbol: 'l', accuracy: 68, userSaid: 'l'), PhonemeFeedback(symbol: 'z', accuracy: 60, userSaid: 'z')]),
      WordFeedback(text: 'by',        accuracy: 88, phonemes: [PhonemeFeedback(symbol: 'b', accuracy: 90, userSaid: 'b'), PhonemeFeedback(symbol: 'ay', accuracy: 86, userSaid: 'ay')]),
      WordFeedback(text: 'the',       accuracy: 92, phonemes: [PhonemeFeedback(symbol: 'dh', accuracy: 92, userSaid: 'dh'), PhonemeFeedback(symbol: 'ax', accuracy: 92, userSaid: 'ax')]),
      WordFeedback(text: 'seashore',  accuracy: 60, phonemes: [PhonemeFeedback(symbol: 's', accuracy: 65, userSaid: 's'), PhonemeFeedback(symbol: 'iy', accuracy: 72, userSaid: 'iy'), PhonemeFeedback(symbol: 'sh', accuracy: 50, userSaid: 's'), PhonemeFeedback(symbol: 'ao', accuracy: 58, userSaid: 'ah'), PhonemeFeedback(symbol: 'r', accuracy: 62, userSaid: 'r')]),
    ],
  ),

  // "How much wood would a woodchuck chuck?"
  PronunciationFeedbackMock(
    accuracyScore: 79, fluencyScore: 85, completenessScore: 80, pronScore: 81,
    words: [
      WordFeedback(text: 'How',       accuracy: 88, phonemes: [PhonemeFeedback(symbol: 'hh', accuracy: 88, userSaid: 'hh'), PhonemeFeedback(symbol: 'aw', accuracy: 86, userSaid: 'aw')]),
      WordFeedback(text: 'much',      accuracy: 82, phonemes: [PhonemeFeedback(symbol: 'm', accuracy: 90, userSaid: 'm'), PhonemeFeedback(symbol: 'ah', accuracy: 80, userSaid: 'ah'), PhonemeFeedback(symbol: 'ch', accuracy: 78, userSaid: 'ch')]),
      WordFeedback(text: 'wood',      accuracy: 76, phonemes: [PhonemeFeedback(symbol: 'w', accuracy: 82, userSaid: 'w'), PhonemeFeedback(symbol: 'uh', accuracy: 70, userSaid: 'uw'), PhonemeFeedback(symbol: 'd', accuracy: 78, userSaid: 'd')]),
      WordFeedback(text: 'would',     accuracy: 74, phonemes: [PhonemeFeedback(symbol: 'w', accuracy: 80, userSaid: 'w'), PhonemeFeedback(symbol: 'uh', accuracy: 68, userSaid: 'uw'), PhonemeFeedback(symbol: 'd', accuracy: 76, userSaid: 'd')]),
      WordFeedback(text: 'a',         accuracy: 96, phonemes: [PhonemeFeedback(symbol: 'ax', accuracy: 96, userSaid: 'ax')]),
      WordFeedback(text: 'woodchuck', accuracy: 72, phonemes: [PhonemeFeedback(symbol: 'w', accuracy: 82, userSaid: 'w'), PhonemeFeedback(symbol: 'uh', accuracy: 68, userSaid: 'uw'), PhonemeFeedback(symbol: 'd', accuracy: 78, userSaid: 'd'), PhonemeFeedback(symbol: 'ch', accuracy: 65, userSaid: 'sh'), PhonemeFeedback(symbol: 'ah', accuracy: 75, userSaid: 'ah'), PhonemeFeedback(symbol: 'k', accuracy: 80, userSaid: 'k')]),
      WordFeedback(text: 'chuck',     accuracy: 80, phonemes: [PhonemeFeedback(symbol: 'ch', accuracy: 78, userSaid: 'ch'), PhonemeFeedback(symbol: 'ah', accuracy: 82, userSaid: 'ah'), PhonemeFeedback(symbol: 'k', accuracy: 82, userSaid: 'k')]),
    ],
  ),

  // "Peter Piper picked a peck of pickled peppers."
  PronunciationFeedbackMock(
    accuracyScore: 64, fluencyScore: 60, completenessScore: 68, pronScore: 64,
    words: [
      WordFeedback(text: 'Peter',   accuracy: 72, phonemes: [PhonemeFeedback(symbol: 'p', accuracy: 75, userSaid: 'p'), PhonemeFeedback(symbol: 'iy', accuracy: 78, userSaid: 'iy'), PhonemeFeedback(symbol: 't', accuracy: 68, userSaid: 't'), PhonemeFeedback(symbol: 'er', accuracy: 65, userSaid: 'er')]),
      WordFeedback(text: 'Piper',   accuracy: 65, phonemes: [PhonemeFeedback(symbol: 'p', accuracy: 70, userSaid: 'p'), PhonemeFeedback(symbol: 'ay', accuracy: 62, userSaid: 'ay'), PhonemeFeedback(symbol: 'p', accuracy: 68, userSaid: 'p'), PhonemeFeedback(symbol: 'er', accuracy: 60, userSaid: 'er')]),
      WordFeedback(text: 'picked',  accuracy: 58, phonemes: [PhonemeFeedback(symbol: 'p', accuracy: 65, userSaid: 'p'), PhonemeFeedback(symbol: 'ih', accuracy: 55, userSaid: 'iy'), PhonemeFeedback(symbol: 'k', accuracy: 60, userSaid: 'k'), PhonemeFeedback(symbol: 't', accuracy: 52, userSaid: 'd')]),
      WordFeedback(text: 'a',       accuracy: 94, phonemes: [PhonemeFeedback(symbol: 'ax', accuracy: 94, userSaid: 'ax')]),
      WordFeedback(text: 'peck',    accuracy: 62, phonemes: [PhonemeFeedback(symbol: 'p', accuracy: 68, userSaid: 'p'), PhonemeFeedback(symbol: 'eh', accuracy: 58, userSaid: 'ae'), PhonemeFeedback(symbol: 'k', accuracy: 62, userSaid: 'k')]),
      WordFeedback(text: 'of',      accuracy: 88, phonemes: [PhonemeFeedback(symbol: 'ah', accuracy: 88, userSaid: 'ah'), PhonemeFeedback(symbol: 'v', accuracy: 85, userSaid: 'v')]),
      WordFeedback(text: 'pickled', accuracy: 55, phonemes: [PhonemeFeedback(symbol: 'p', accuracy: 62, userSaid: 'p'), PhonemeFeedback(symbol: 'ih', accuracy: 50, userSaid: 'iy'), PhonemeFeedback(symbol: 'k', accuracy: 58, userSaid: 'k'), PhonemeFeedback(symbol: 'l', accuracy: 60, userSaid: 'l'), PhonemeFeedback(symbol: 'd', accuracy: 48, userSaid: 't')]),
      WordFeedback(text: 'peppers', accuracy: 60, phonemes: [PhonemeFeedback(symbol: 'p', accuracy: 65, userSaid: 'p'), PhonemeFeedback(symbol: 'eh', accuracy: 55, userSaid: 'ae'), PhonemeFeedback(symbol: 'p', accuracy: 62, userSaid: 'p'), PhonemeFeedback(symbol: 'er', accuracy: 58, userSaid: 'er'), PhonemeFeedback(symbol: 'z', accuracy: 62, userSaid: 'z')]),
    ],
  ),
];

class AppRoutes {
  static const login = '/login';
  static const shell = '/shell';

  static const onboardingUserInfo = '/onboarding/user-info';
  static const onboardingNativeLanguage = '/onboarding/native-language';
  static const onboardingLearningGoal = '/onboarding/learning-goal';
  static const onboardingFocusAreas = '/onboarding/focus-areas';
  static const onboardingDailyGoal = '/onboarding/daily-goal';
  static const onboardingFeedbackTone = '/onboarding/feedback-tone';
  static const onboardingSkillAssess = '/onboarding/skill-assess';
  static const onboardingAccentSelection = '/onboarding/accent-selection';
  static const onboardingComplete = '/onboarding/complete';

  static const onboardingIntro = '/onboarding/intro';

  static const courses = '/courses';
  static const home = '/home';
  static const social = '/social';
  static const profile = '/profile';
  static const socialDebug = '/social/debug';
  static const soloPractice = '/solo-practice';

  static const groupSessionSelect = '/group_session/session-select';
  static const groupSessionPrivateSelect = '/group_session/private-select';
  static const groupSessionPrivateCreate = '/group_session/private-create';
  static const groupSessionPrivateJoin = '/group_session/private-join';
  static const groupSessionActiveLobby = '/group_session/active-lobby';
  static const groupSessionPublicMatch = '/group_session/public-match';
  static const groupSessionResults = '/group_session/results';
  static const groupSessionPostSession = '/group_session/post-session';

  static const resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> get table => {
    login: (_) => const LoginPage(),

    onboardingUserInfo: (_) => const OnboardingUserInfoPage(),
    onboardingNativeLanguage: (_) => const NativeLanguagePage(),
    onboardingLearningGoal: (_) => const LearningGoalPage(),
    onboardingFocusAreas: (_) => const FocusAreasPage(),
    onboardingDailyGoal: (_) => const DailyGoalPage(),
    onboardingFeedbackTone: (_) => const FeedbackTonePage(),
    onboardingSkillAssess: (_) => const SkillAssessPage(),
    onboardingAccentSelection: (_) => const AccentSelectionPage(),
    onboardingComplete: (_) => const OnboardingCompletePage(),

    courses: (_) => const CoursesListPage(),
    home: (_) => const HomePage(),
    social: (_) => const SocialPage(),
    profile: (_) => const ProfilePage(),
    socialDebug: (_) => const SocialPage(),
    soloPractice: (ctx) {
      final lesson = ModalRoute.of(ctx)!.settings.arguments as Lesson?;
      return SoloPracticePage(lesson: lesson);
    },
    groupSessionSelect: (_) => const GroupSessionSelectPage(),
    groupSessionPrivateSelect: (_) => const GroupSessionPrivateSelectPage(),
    groupSessionPrivateCreate: (_) => const GroupSessionPrivateCreatePage(),
    groupSessionPrivateJoin: (_) => const GroupSessionPrivateJoinPage(),
    groupSessionActiveLobby: (_) => const GroupSessionActiveLobbyPage(),
    groupSessionPublicMatch: (_) => const GroupSessionPublicMatchPage(),
    groupSessionResults: (ctx) {
      final args = ModalRoute.of(ctx)!.settings.arguments;
      final participants = args is Map<String, Object?> && args['participants'] is List<PrivateLobby>
          ? (args['participants'] as List<PrivateLobby>)
          : (args is List<PrivateLobby> ? args : <PrivateLobby>[]);
      final feedbacks = args is Map<String, Object?> && args['feedbacks'] is List<PronunciationFeedbackMock>
          ? (args['feedbacks'] as List<PronunciationFeedbackMock>)
          : _groupDummyFeedbacks;
      final items = args is Map<String, Object?> && args['items'] is List<LessonItem>
          ? (args['items'] as List<LessonItem>)
          : _groupDummyItems;
      return SessionResultsPage(
        feedbacks: feedbacks,
        items: items,
        sessionTitle: 'Group Session',
        ctaLabel: 'View Participants',
        onCtaTap: (c) => Navigator.of(c).pushReplacementNamed(
          groupSessionPostSession,
          arguments: <String, Object>{
            'participants': participants,
            'feedbacks': feedbacks,
            'items': items,
          },
        ),
        motivationalMessageOverride: (avg) {
          if (avg >= 85) return 'Your group crushed it — sharp pronunciation and great flow across the session!';
          if (avg >= 70) return 'Solid group effort! A few more sessions like this and the whole team will be at the summit.';
          if (avg >= 55) return 'Good footwork as a group. Study the phrases that tripped you up and the next climb will be smoother.';
          return 'Every session counts. Keep climbing together — the view gets better every time.';
        },
      );
    },
    groupSessionPostSession: (ctx) {
      final args = ModalRoute.of(ctx)!.settings.arguments;
      final participants = args is Map<String, Object?> && args['participants'] is List<PrivateLobby>
          ? (args['participants'] as List<PrivateLobby>)
          : (args is List<PrivateLobby> ? args : <PrivateLobby>[]);
      final feedbacks = args is Map<String, Object?> && args['feedbacks'] is List<PronunciationFeedbackMock>
          ? (args['feedbacks'] as List<PronunciationFeedbackMock>)
          : const <PronunciationFeedbackMock>[];
      final items = args is Map<String, Object?> && args['items'] is List<LessonItem>
          ? (args['items'] as List<LessonItem>)
          : const <LessonItem>[];
      return GroupPostSessionPage(
        participants: participants,
        feedbacks: feedbacks,
        items: items,
      );
    },
    resetPassword: (_) => const ResetPasswordPage(),
  };
}
