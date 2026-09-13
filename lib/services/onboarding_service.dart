import 'package:shared_preferences/shared_preferences.dart';

/// Stores the first-launch flag for the onboarding flow.
///
/// Keeps a single boolean `onboarding_completed` in [SharedPreferences]
/// so the onboarding is shown only on the very first launch.
class OnboardingService {
  static const String _completedKey = 'onboarding_completed';

  /// Whether the onboarding should be shown (true if not completed yet).
  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_completedKey) ?? false);
  }

  /// Marks the onboarding as completed.
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
