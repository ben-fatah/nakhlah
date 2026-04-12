import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global favorites state — holds a [Set] of favorited [Product.id] strings.
///
/// Persisted to [SharedPreferences] on every mutation so that favorites
/// survive app restarts.
///
/// Usage:
/// ```dart
/// // In main():
/// final prefs = await SharedPreferences.getInstance();
/// favoritesNotifier.init(prefs);
///
/// // In a widget:
/// ValueListenableBuilder<Set<String>>(
///   valueListenable: favoritesNotifier,
///   builder: (_, favorites, __) => Icon(
///     favorites.contains(product.id)
///         ? Icons.favorite_rounded
///         : Icons.favorite_border_rounded,
///   ),
/// );
///
/// // Toggle:
/// favoritesNotifier.toggle(product.id);
/// ```
///
/// This follows the same singleton pattern as [localeProvider] — a single
/// top-level instance is imported wherever needed.
final favoritesNotifier = FavoritesNotifier();

/// [ValueNotifier] that manages a set of favorited product IDs.
class FavoritesNotifier extends ValueNotifier<Set<String>> {
  static const _prefsKey = 'favorite_product_ids';

  SharedPreferences? _prefs;

  FavoritesNotifier() : super({});

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Loads persisted favorites from [SharedPreferences].
  ///
  /// Call once at app startup, after [SharedPreferences.getInstance()].
  /// Safe to call more than once (subsequent calls are no-ops if the prefs
  /// instance is the same).
  void init(SharedPreferences prefs) {
    if (_prefs == prefs) return; // already initialised with this instance
    _prefs = prefs;
    final saved = prefs.getStringList(_prefsKey) ?? [];
    value = Set<String>.from(saved);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns `true` if [productId] is in the favorites set.
  bool isFavorite(String productId) => value.contains(productId);

  /// Adds [productId] to favorites if absent, removes it if present.
  ///
  /// Immediately persists the updated set to [SharedPreferences].
  void toggle(String productId) {
    final next = Set<String>.from(value);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    value = next; // notifies listeners
    _prefs?.setStringList(_prefsKey, next.toList());
  }
}
