import 'package:flutter/foundation.dart';

/// Lightweight singleton that lets any widget switch the main [HomePage]
/// tab without holding a reference to its state.
///
/// Usage:
/// ```dart
/// // In HomePage.initState:
/// NavigationService.instance.onTabChange = _onNavTap;
///
/// // From anywhere:
/// NavigationService.instance.switchTab(3); // open Market tab
/// ```
class NavigationService {
  NavigationService._();
  static final instance = NavigationService._();

  /// Registered by [_HomePageState] right after build; cleared on dispose.
  ValueChanged<int>? onTabChange;

  /// Switch to [index] in the main bottom navigation.
  /// Safe to call even before [onTabChange] is registered — it is a no-op.
  void switchTab(int index) => onTabChange?.call(index);
}
