import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/models/pronunciation_feedback.dart';

/// Aggregated score for a single phoneme across a practice session.
class _PhonemeAggregate {
  double totalScore;
  int count;

  _PhonemeAggregate(this.totalScore, this.count);
}

/// Service responsible for persisting phoneme progress after a practice session.
///
/// Aggregates per-phoneme accuracy scores from all feedback items in a session,
/// then POSTs the batch to the Gateway → progress-service for weighted-average
/// merging with the user's historical data.
///
/// Usage:
/// - Inject via Provider as a plain [ProgressService] (no ChangeNotifier).
/// - Call [submitPhonemeScores] fire-and-forget from [PracticeResultsPage].
class ProgressService {
  ProgressService({
    required ApiClient api,
    required AuthService auth,
  })  : _api = api,
        _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  /// Aggregate and submit phoneme scores from a completed practice session.
  ///
  /// Collects every [PhonemeFeedback] with a non-null accuracy across all
  /// [feedbacks], groups them by symbol, and computes the session-average
  /// score and total count for each phoneme. That payload is sent to
  /// `POST /progress/phonemes/batch` via the Gateway.
  ///
  /// Returns silently on auth failure or empty phoneme data so the caller
  /// never needs to handle errors — this is always best-effort.
  Future<void> submitPhonemeScores(
    List<PronunciationFeedbackMock> feedbacks,
  ) async {
    final token = _auth.accessToken;
    if (token == null) return;

    final Map<String, _PhonemeAggregate> aggregates = {};

    for (final feedback in feedbacks) {
      for (final word in feedback.words) {
        for (final phoneme in word.phonemes) {
          final accuracy = phoneme.accuracy;
          if (accuracy == null) continue;

          final symbol = phoneme.symbol.toLowerCase().trim();
          if (symbol.isEmpty) continue;

          final existing = aggregates[symbol];
          if (existing != null) {
            existing.totalScore += accuracy;
            existing.count += 1;
          } else {
            aggregates[symbol] = _PhonemeAggregate(accuracy, 1);
          }
        }
      }
    }

    if (aggregates.isEmpty) return;

    final phonemeScores = aggregates.entries.map((e) {
      final avg = e.value.totalScore / e.value.count;
      return {
        'symbol': e.key,
        'score': double.parse(avg.toStringAsFixed(4)),
        'count': e.value.count,
      };
    }).toList();

    try {
      await _api.postJson(
        '/progress/phonemes/batch',
        accessToken: token,
        body: {'phoneme_scores': phonemeScores},
      );
    } catch (_) {
      // Best-effort — never interrupt the results UI.
    }
  }

  /// Best-effort logging of active practice duration for today's daily goal.
  ///
  /// [secondsDelta] should represent active session seconds (not wall time).
  Future<void> submitDailyMinutes({
    required int secondsDelta,
  }) async {
    if (secondsDelta <= 0) return;

    final token = _auth.accessToken;
    if (token == null) return;

    try {
      await _api.postJson(
        '/progress/daily-minutes',
        accessToken: token,
        body: {'seconds_delta': secondsDelta},
      );
    } catch (_) {
      // Best-effort — never interrupt user flow.
    }
  }
}
