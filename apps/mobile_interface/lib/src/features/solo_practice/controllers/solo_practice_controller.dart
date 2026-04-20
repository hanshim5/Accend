import 'package:flutter/material.dart';

import '../../courses/models/lesson_item.dart';
import '../../../common/models/pronunciation_feedback.dart';
import '../services/pronunciation_feedback_service.dart';

/// Fallback prompts used when no lesson items are available from the database.
const List<String> _defaultCardTexts = [
  'The quick brown fox jumped over the lazy dog.',
  'She sells seashells by the seashore.',
  'How much wood would a woodchuck chuck?',
  'Peter Piper picked a peck of pickled peppers.',
  'I scream, you scream, we all scream for ice cream.',
  'Red lorry, yellow lorry.',
  'Unique New York, unique New York.',
  'Buffalo buffalo Buffalo buffalo buffalo buffalo Buffalo buffalo.',
  'The sixth sick sheikh\'s sixth sheep\'s sick.',
  'Fresh French fried fish fingers.',
  'I saw Susie sitting in a shoeshine shop.',
  'Lesser leather never weathered wetter weather better.',
  'Can you can a can as a canner can can a can?',
  'Willy\'s real rear wheel.',
  'The thirty-three thieves thought that they thrilled the throne.',
  'Six sleek swans swam swiftly southwards.',
  'How can a clam cram in a clean cream can?',
  'Fuzzy Wuzzy was a bear. Fuzzy Wuzzy had no hair.',
  'Near an ear, a nearer ear, a nearly eerie ear.',
  'You\'ve done it! Great work completing the lesson.',
];

LessonItem _textToItem(String text, int index) => LessonItem(
      id: '',
      lessonId: '',
      position: index + 1,
      text: text,
    );

/// Holds session state and logic for the solo practice flow:
/// current card index, mic state (idle/recording/playback), and feedback.
class SoloPracticeController {
  SoloPracticeController({List<LessonItem>? items})
      : _items = (items != null && items.isNotEmpty)
            ? items
            : _defaultCardTexts
                .asMap()
                .entries
                .map((e) => _textToItem(e.value, e.key))
                .toList();

  final List<LessonItem> _items;
  final List<PronunciationFeedbackMock> _sessionFeedbacks = [];

  int currentCardIndex = 0;

  /// 0 = idle, 1 = recording, 2 = playback.
  int micStateIndex = 0;

  PronunciationFeedbackMock? currentFeedback;

  /// All feedback results collected so far in this session (one per submitted card).
  List<PronunciationFeedbackMock> get sessionFeedbacks =>
      List.unmodifiable(_sessionFeedbacks);

  /// The ordered list of lesson items used in this session.
  List<LessonItem> get items => List.unmodifiable(_items);

  int get totalCards => _items.length;

  LessonItem get currentItem => _items[currentCardIndex];

  String get currentCard => currentItem.text;

  /// Progress value between 0.0 and 1.0 for the progress bar.
  double get progress => (currentCardIndex + 1) / totalCards;

  /// True when Retry and Submit buttons should be shown (playback state, no feedback yet).
  bool get showRetrySubmit => micStateIndex == 2 && currentFeedback == null;

  /// True when there is a next card after the current one.
  bool get hasNextCard => currentCardIndex < totalCards - 1;

  /// Icon for the mic button based on [micStateIndex]: mic, record dot, or play arrow.
  IconData get currentMicIcon {
    switch (micStateIndex) {
      case 1:
        return Icons.fiber_manual_record;
      case 2:
        return Icons.play_arrow;
      case 0:
      default:
        return Icons.mic;
    }
  }

  /// Advance mic state: idle → recording → playback. No-op when already in playback.
  void advanceMicState() {
    if (micStateIndex < 2) {
      micStateIndex += 1;
    }
  }

  /// Reset mic to idle so the user can re-record.
  void retry() {
    micStateIndex = 0;
  }

  /// Set the current feedback (after submit). Pass null to clear.
  void setFeedback(PronunciationFeedbackMock? value) {
    currentFeedback = value;
  }

  /// Call pronunciation/assess with [audioBytes] and [referenceText], then set
  /// [currentFeedback] (real result or mock on failure). Does not hold [BuildContext]
  /// or show dialogs.
  Future<void> submit({
    required List<int> audioBytes,
    required String referenceText,
    String? accessToken,
  }) async {
    final feedback = await fetchPronunciationFeedback(
      audioBytes: audioBytes,
      referenceText: referenceText,
      accessToken: accessToken,
    );
    currentFeedback = feedback ?? getMockFeedback(referenceText);
  }

  /// Clear feedback and advance to next card (or stay on last). Resets mic to idle.
  /// Saves the current feedback into [sessionFeedbacks] before clearing it.
  /// Returns true if there is a next card, false if this was the last card.
  bool advanceToNextCard() {
    if (currentFeedback != null) {
      _sessionFeedbacks.add(currentFeedback!);
    }
    currentFeedback = null;
    micStateIndex = 0;
    if (currentCardIndex < totalCards - 1) {
      currentCardIndex += 1;
      return true;
    }
    return false;
  }

  /// Reset session to first card, clear feedback and accumulated results, mic to idle.
  void resetSession() {
    currentCardIndex = 0;
    micStateIndex = 0;
    currentFeedback = null;
    _sessionFeedbacks.clear();
  }
}
