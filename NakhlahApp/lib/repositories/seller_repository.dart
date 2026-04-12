import '../models/product_model.dart';
import '../models/seller_model.dart';
import '../repositories/product_repository.dart';

/// Repository providing [Seller] data.
///
/// Currently backed by a static catalogue. To switch to Firestore:
/// replace [getAllSellers] with a Firestore collection query and keep
/// the same method signatures — callers will not change.
class SellerRepository {
  // ── Query methods ──────────────────────────────────────────────────────────

  /// Returns the two featured sellers shown on the Home screen.
  List<Seller> getFeatured() =>
      _staticSellers.where((s) => s.isTop).take(2).toList();

  /// Returns all sellers in the catalogue.
  List<Seller> getAllSellers() => _staticSellers;

  /// Returns the seller with [id], or `null` if not found.
  Seller? getById(String id) {
    try {
      return _staticSellers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns all sellers that carry the product identified by [productId].
  ///
  /// Matches against [Seller.productIds]. Returns an empty list — not null —
  /// when no sellers carry the given product.
  List<Seller> getSellersByProduct(String productId) {
    return _staticSellers
        .where((s) => s.productIds.contains(productId))
        .toList();
  }

  /// Returns all products sold by [seller] using the supplied [productRepo].
  List<Product> getProductsForSeller(
    Seller seller,
    ProductRepository productRepo,
  ) {
    return productRepo.getByIds(seller.productIds);
  }
}

// Internal import reference for getProductsForSeller return type.
// If circular dependency ever arises, extract to a service class.

// ── Static seller catalogue ───────────────────────────────────────────────────
// TODO: Replace with Firestore stream when the seller backend is ready.

final List<Seller> _staticSellers = [
  const Seller(
    id: 'al_madina_farms',
    name: 'Al-Madina Farms',
    rating: 4.9,
    reviews: '1.2k',
    reviewCount: 1200,
    isTop: true,
    location: 'Al-Madinah Al-Munawwarah, KSA',
    phoneNumber: '+966501234001',
    productIds: ['ajwa', 'medjool'],
    description:
        'A family-owned farm operating for over 30 years in the fertile fields '
        'surrounding Al-Madinah. Specialists in hand-picked Ajwa dates, '
        'triple-washed and naturally sun-dried with no additives.',
  ),
  const Seller(
    id: 'royal_oasis',
    name: 'Royal Oasis',
    rating: 4.8,
    reviews: '850',
    reviewCount: 850,
    isTop: true,
    location: 'Al-Ahsa, Eastern Province, KSA',
    phoneNumber: '+966501234002',
    productIds: ['medjool', 'khalas', 'barhi'],
    description:
        'Royal Oasis sources its dates directly from certified farms in Al-Ahsa '
        '— a UNESCO-listed oasis region. Known for premium Khalas and Medjool '
        'varieties, cold-chain shipped to preserve freshness.',
  ),
  const Seller(
    id: 'qassim_valley',
    name: 'Qassim Valley Farms',
    rating: 4.7,
    reviews: '620',
    reviewCount: 620,
    isTop: false,
    location: 'Buraydah, Al-Qassim, KSA',
    phoneNumber: '+966501234003',
    productIds: ['sukkari', 'sagai'],
    description:
        'The Qassim region is the heartland of Sukkari dates, and Qassim Valley '
        'Farms represents the finest producers of this golden variety. Every batch '
        'is quality-graded and vacuum-sealed for maximum shelf life.',
  ),
  const Seller(
    id: 'ahsa_naturals',
    name: 'Al-Ahsa Naturals',
    rating: 4.6,
    reviews: '410',
    reviewCount: 410,
    isTop: false,
    location: 'Al-Hofuf, Al-Ahsa, KSA',
    phoneNumber: '+966501234004',
    productIds: ['khalas', 'barhi', 'ajwa'],
    description:
        'Al-Ahsa Naturals partners with smallholder farmers to bring rare and '
        'seasonal varieties to market. Their Barhi in the khalal stage is a '
        'highlight — crisp, golden, and unlike anything else.',
  ),
  const Seller(
    id: 'desert_rose',
    name: 'Desert Rose Trading',
    rating: 4.5,
    reviews: '390',
    reviewCount: 390,
    isTop: false,
    location: 'Riyadh, KSA',
    phoneNumber: '+966501234005',
    productIds: ['sagai', 'sukkari', 'medjool'],
    description:
        'Desert Rose Trading curates a diverse selection of premium Saudi dates '
        'for both retail and corporate gifting. Their elegantly packaged gift '
        'boxes are a popular choice for Ramadan and Eid occasions.',
  ),
  const Seller(
    id: 'najd_harvest',
    name: 'Najd Harvest Co.',
    rating: 4.4,
    reviews: '275',
    reviewCount: 275,
    isTop: false,
    location: 'Riyadh, Najd Region, KSA',
    phoneNumber: '+966501234006',
    productIds: ['sukkari', 'medjool', 'sagai'],
    description:
        'Najd Harvest is a Riyadh-based cooperative that aggregates produce from '
        'over 40 licensed farms. They offer competitive prices on bulk orders and '
        'provide traceability certificates for every shipment.',
  ),
];
