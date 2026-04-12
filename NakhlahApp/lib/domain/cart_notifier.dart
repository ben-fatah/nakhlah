import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single line-item in the shopping cart.
class CartItem {
  final String productId;
  final String name;
  final double price;
  final String unit;
  final String imagePath;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.imagePath,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'unit': unit,
    'imagePath': imagePath,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    unit: json['unit'] as String,
    imagePath: json['imagePath'] as String,
    quantity: (json['quantity'] as num).toInt(),
  );
}

/// Global cart state — holds a list of [CartItem]s.
///
/// Persisted to [SharedPreferences] on every mutation.
///
/// Usage:
/// ```dart
/// cartNotifier.add(item);
/// cartNotifier.remove(productId);
/// cartNotifier.increment(productId);
/// cartNotifier.decrement(productId);
/// cartNotifier.clear();
/// ```
final cartNotifier = CartNotifier();

class CartNotifier extends ValueNotifier<List<CartItem>> {
  static const _prefsKey = 'cart_items';
  SharedPreferences? _prefs;

  CartNotifier() : super([]);

  void init(SharedPreferences prefs) {
    if (_prefs == prefs) return;
    _prefs = prefs;
    _load();
  }

  void _load() {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      value = list;
    } catch (_) {
      value = [];
    }
  }

  void _persist() {
    final encoded = jsonEncode(value.map((e) => e.toJson()).toList());
    _prefs?.setString(_prefsKey, encoded);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  int get totalItems => value.fold(0, (sum, i) => sum + i.quantity);

  double get totalPrice =>
      value.fold(0.0, (sum, i) => sum + i.price * i.quantity);

  bool contains(String productId) => value.any((i) => i.productId == productId);

  int quantityOf(String productId) {
    try {
      return value.firstWhere((i) => i.productId == productId).quantity;
    } catch (_) {
      return 0;
    }
  }

  void add(CartItem item) {
    final next = List<CartItem>.from(value);
    final idx = next.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      next[idx].quantity++;
    } else {
      next.add(item);
    }
    value = next;
    _persist();
  }

  void remove(String productId) {
    value = value.where((i) => i.productId != productId).toList();
    _persist();
  }

  void increment(String productId) {
    final next = List<CartItem>.from(value);
    final idx = next.indexWhere((i) => i.productId == productId);
    if (idx >= 0) next[idx].quantity++;
    value = next;
    _persist();
  }

  void decrement(String productId) {
    final next = List<CartItem>.from(value);
    final idx = next.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      if (next[idx].quantity > 1) {
        next[idx].quantity--;
      } else {
        next.removeAt(idx);
      }
    }
    value = next;
    _persist();
  }

  void clear() {
    value = [];
    _persist();
  }
}
