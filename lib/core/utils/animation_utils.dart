/// Utility class to track which items have already been animated
/// to prevent replays during provider refreshes.
class AnimationTracker {
  static final Set<String> _seenTokens = {};

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

  /// Clears all seen tokens. Useful for testing or major state resets.
  static void clear() {
    _seenTokens.clear();
  }
}
