/// Utility class to track which items have already been animated
/// to prevent replays during provider refreshes.
class AnimationTracker {
  static final Set<String> _seenTokens = {};
  static final Map<String, double> _lastValues = {};

  /// Checks if a token has been seen before.
  /// If not, marks it as seen and returns false.
  /// If seen, returns true.
  static bool hasSeen(String token) {
    if (_seenTokens.contains(token)) {
      return true;
    }
    _seenTokens.add(token);
    return false;
  }

  /// Checks if a token has been seen without marking it.
  static bool isSeen(String token) {
    return _seenTokens.contains(token);
  }

  /// Gets the last recorded value for a token.
  static double? getValue(String token) {
    return _lastValues[token];
  }

  /// Updates the recorded value for a token.
  static void updateValue(String token, double value) {
    _lastValues[token] = value;
  }

  /// Clears all seen tokens and values. Useful for testing or major state resets.
  static void clear() {
    _seenTokens.clear();
    _lastValues.clear();
  }
}
