import '../l10n/app_localizations.dart';
import '../models/product_model.dart';

/// Repository providing [Product] data.
///
/// Currently returns static hardcoded data. Ready for a future Firestore
/// switchover — just replace the body of [getAll] with a Firestore query.
class ProductRepository {
  /// Returns all products.
  List<Product> getAll(AppLocalizations l) => _staticProducts;

  /// Returns products filtered by [tag] and optional [searchQuery].
  List<Product> getFiltered(
    AppLocalizations l, {
    required String tag,
    String searchQuery = '',
  }) {
    return _staticProducts.where((p) {
      final matchFilter = tag == 'all' || p.tag == tag;
      final matchSearch =
          searchQuery.isEmpty ||
          p.nameGetter(l).toLowerCase().contains(searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }
}

/// Static product catalogue.
final List<Product> _staticProducts = [
  Product(
    nameGetter: (l) => l.premiumMedjool,
    rating: 4.8,
    reviews: 85,
    price: 110,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/medjool.png',
    tag: 'medjool',
    isVerified: true,
  ),
  Product(
    nameGetter: (l) => l.ajwaAlMadinah,
    rating: 4.9,
    reviews: 120,
    price: 85,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/ajwa.png',
    tag: 'ajwa',
    isVerified: true,
  ),
  Product(
    nameGetter: (l) => l.khalasAlAhsa,
    rating: 4.5,
    reviews: 67,
    price: 130,
    unitGetter: (l) => l.isArabic ? 'لكل ٣ كغ' : 'per 3 kg',
    imagePath: 'assets/images/khalas.png',
    tag: 'khalas',
    isVerified: false,
  ),
  Product(
    nameGetter: (l) => l.sukkariMofatall,
    rating: 4.7,
    reviews: 42,
    price: 45,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/sukari.png',
    tag: 'sukkari',
    isVerified: true,
  ),
  Product(
    nameGetter: (l) => l.barhiGolden,
    rating: 4.6,
    reviews: 33,
    price: 60,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/barhi.png',
    tag: 'barhi',
    isVerified: false,
  ),
  Product(
    nameGetter: (l) => l.sagaiDates,
    rating: 4.4,
    reviews: 28,
    price: 55,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/sagai.png',
    tag: 'sagai',
    isVerified: false,
  ),
];
