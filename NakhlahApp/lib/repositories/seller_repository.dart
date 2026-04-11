import '../models/seller_model.dart';

/// Repository providing [Seller] data.
///
/// Currently returns static hardcoded data. Ready for a future Firestore
/// switchover.
class SellerRepository {
  /// Returns the featured sellers shown on the Home screen.
  List<Seller> getFeatured() => _staticSellers;
}

/// Static seller catalogue.
final List<Seller> _staticSellers = [
  const Seller(
    name: 'Al-Madina Farms',
    rating: 4.9,
    reviews: '1.2k',
    isTop: true,
  ),
  const Seller(name: 'Royal Oasis', rating: 4.8, reviews: '850', isTop: true),
];
