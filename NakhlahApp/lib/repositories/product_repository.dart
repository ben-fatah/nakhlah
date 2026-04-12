import '../l10n/app_localizations.dart';
import '../models/product_model.dart';

/// Repository providing [Product] data.
///
/// Currently backed by a static catalogue. Ready for Firestore:
/// replace [getAll] / [getFiltered] with Firestore queries and keep the
/// same method signatures — callers will not need to change.
class ProductRepository {
  // ── Query methods ──────────────────────────────────────────────────────────

  /// Returns all products in the catalogue.
  List<Product> getAll(AppLocalizations l) => _staticProducts;

  /// Returns the product with [id], or `null` if not found.
  Product? getById(String id) {
    try {
      return _staticProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns all products whose [Product.id] is contained in [ids].
  List<Product> getByIds(List<String> ids) {
    return _staticProducts.where((p) => ids.contains(p.id)).toList();
  }

  /// Returns products filtered by [tag] and an optional [searchQuery].
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

// ── Static product catalogue ───────────────────────────────────────────────────
// [id] matches [tag] for consistency with seller.productIds references.
// TODO: Replace with Firestore stream when online catalogue is ready.

final List<Product> _staticProducts = [
  Product(
    id: 'medjool',
    nameGetter: (l) => l.premiumMedjool,
    descriptionGetter: (l) => l.isArabic
        ? 'تمر المجدول، ملك التمور، يتميز بحجمه الكبير وطعمه الكراميلي وملمسه الطري. '
              'يُزرع في واحات الجزيرة العربية وهو مفضل لما يمنحه من طاقة طبيعية فورية.'
        : 'The king of dates — prized for its impressively large size, caramel-like '
              'flavour, and soft, chewy texture. Grown across Arabian Peninsula oases, '
              'it delivers quick natural energy and is rich in potassium and fibre.',
    rating: 4.8,
    reviews: 85,
    price: 110,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/medjool.png',
    tag: 'medjool',
    isVerified: true,
  ),
  Product(
    id: 'ajwa',
    nameGetter: (l) => l.ajwaAlMadinah,
    descriptionGetter: (l) => l.isArabic
        ? 'تمر العجوة من المدينة المنورة، صنف نادر ذو لون داكن وطعم لطيف غير مفرط الحلاوة. '
              'يحظى بمكانة تاريخية وروحانية خاصة ويُعدّ من أفضل أصناف التمر في العالم.'
        : 'A prized variety from Al-Madinah Al-Munawwarah. Dark, soft, and slightly dry '
              'with a subtle sweetness and deep, earthy notes. Historically significant '
              'in Islamic tradition and beloved for its exceptional nutritional profile.',
    rating: 4.9,
    reviews: 120,
    price: 85,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/ajwa.png',
    tag: 'ajwa',
    isVerified: true,
  ),
  Product(
    id: 'khalas',
    nameGetter: (l) => l.khalasAlAhsa,
    descriptionGetter: (l) => l.isArabic
        ? 'الخلاص فخر الأحساء، يتميز بطعمه العسلي الغني وقوامه اللزج المميز. '
              'يُحصد في موسمه الطبيعي ويُعدّ من أرقى أصناف التمر في المملكة العربية السعودية.'
        : 'The pride of Al-Ahsa, Saudi Arabia. Rich in natural sugars with a distinctive '
              'honey-like taste and a luscious, sticky texture. Best savoured fresh after '
              'the harvest season — a genuine Arabian delicacy.',
    rating: 4.5,
    reviews: 67,
    price: 130,
    unitGetter: (l) => l.isArabic ? 'لكل ٣ كغ' : 'per 3 kg',
    imagePath: 'assets/images/khalas.png',
    tag: 'khalas',
    isVerified: false,
  ),
  Product(
    id: 'sukkari',
    nameGetter: (l) => l.sukkariMofatall,
    descriptionGetter: (l) => l.isArabic
        ? 'السكري المفتل جوهرة القصيم، يتميز بقوامه المقرمش ولونه الذهبي وطعمه الحلو الذي يذوب في الفم. '
              'من أكثر أصناف التمر شعبية في المملكة وتحظى بإقبال واسع في رمضان.'
        : 'A jewel of the Qassim region. Sukkari dates are celebrated for their crispy '
              'texture, golden colour, and melt-in-the-mouth sweetness. One of the most '
              'popular varieties in Saudi Arabia, especially during Ramadan.',
    rating: 4.7,
    reviews: 42,
    price: 45,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/sukari.png',
    tag: 'sukkari',
    isVerified: true,
  ),
  Product(
    id: 'barhi',
    nameGetter: (l) => l.barhiGolden,
    descriptionGetter: (l) => l.isArabic
        ? 'البرحي الذهبي فريد في نوعه إذ يُستمتع به في مرحلة الخلال (الأصفر) قبل الرطوبة الكاملة. '
              'قوامه مقرمش وطعمه حلو مع لمسة خفيفة من الحموضة. يُزرع في العراق والسعودية.'
        : 'Unique in that they are best enjoyed at the khalal (yellow) stage before full '
              'ripening. Crisp, sweet, and slightly tangy — a refreshing contrast to the '
              'softer varieties. Cultivated extensively across Iraq and Saudi Arabia.',
    rating: 4.6,
    reviews: 33,
    price: 60,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/barhi.png',
    tag: 'barhi',
    isVerified: false,
  ),
  Product(
    id: 'sagai',
    nameGetter: (l) => l.sagaiDates,
    descriptionGetter: (l) => l.isArabic
        ? 'تمر السقعي ذو اللونين المميز: الجزء العلوي جاف ومجعد والسفلي طري وحلو. '
              'يتميز بنكهة الكراميل الخفيفة وهو من الأصناف الشائعة في منطقة الرياض.'
        : 'A striking two-toned variety with a dry, wrinkled top and a moist, sweet '
              'bottom half. Its subtle caramel flavour makes it a firm favourite in the '
              'Riyadh region and an excellent choice for gifting.',
    rating: 4.4,
    reviews: 28,
    price: 55,
    unitGetter: (l) => l.isArabic ? 'لكل كغ' : 'per kg',
    imagePath: 'assets/images/sagai.png',
    tag: 'sagai',
    isVerified: false,
  ),
];
