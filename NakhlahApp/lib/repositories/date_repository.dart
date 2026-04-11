import '../l10n/app_localizations.dart';
import '../models/date_model.dart';

/// Repository providing [DateVariety] data.
///
/// Currently returns static hardcoded data. Ready for a future Firestore
/// switchover.
class DateRepository {
  /// Returns all date varieties.
  List<DateVariety> getAll() => _staticVarieties;

  /// Returns varieties filtered by [tag] and optional [searchQuery].
  List<DateVariety> getFiltered(
    AppLocalizations l, {
    required String tag,
    String searchQuery = '',
  }) {
    return _staticVarieties.where((v) {
      final matchFilter = tag == 'all' || v.tag == tag;
      final matchSearch = searchQuery.isEmpty ||
          v.nameGetter(l).toLowerCase().contains(searchQuery.toLowerCase()) ||
          v.originGetter(l).toLowerCase().contains(searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }
}

/// Static date variety catalogue.
final List<DateVariety> _staticVarieties = [
  DateVariety(
    nameGetter: (l) => l.ajwaAlMadinah,
    originGetter: (l) => l.originMadinah,
    kcal: 280,
    price: 24.00,
    imagePath: 'assets/images/ajwa.png',
    tag: 'ajwa',
  ),
  DateVariety(
    nameGetter: (l) => l.premiumMedjool,
    originGetter: (l) => l.originJericho,
    kcal: 277,
    price: 18.50,
    imagePath: 'assets/images/medjool.png',
    tag: 'medjool',
  ),
  DateVariety(
    nameGetter: (l) => l.sukkariMofatall,
    originGetter: (l) => l.originQassim,
    kcal: 320,
    price: 15.00,
    imagePath: 'assets/images/sukari.png',
    tag: 'sukkari',
  ),
  DateVariety(
    nameGetter: (l) => l.khalasAlAhsa,
    originGetter: (l) => l.originAhsa,
    kcal: 300,
    price: 12.90,
    imagePath: 'assets/images/khalas.png',
    tag: 'khalas',
  ),
  DateVariety(
    nameGetter: (l) => l.barhiGolden,
    originGetter: (l) => l.originQassim,
    kcal: 265,
    price: 20.00,
    imagePath: 'assets/images/barhi.png',
    tag: 'barhi',
  ),
  DateVariety(
    nameGetter: (l) => l.sagaiDates,
    originGetter: (l) => l.originRiyadh,
    kcal: 290,
    price: 14.50,
    imagePath: 'assets/images/sagai.png',
    tag: 'sagai',
  ),
];
