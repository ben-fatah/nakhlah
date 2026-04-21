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
          v.originGetter(l).toLowerCase().contains(searchQuery.toLowerCase()) ||
          v.descriptionGetter(l).toLowerCase().contains(searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }
}

/// Static date variety catalogue — all 17 varieties recognised by the AI model.
/// Nutrition values sourced from date_metadata.json (per 100 g).
final List<DateVariety> _staticVarieties = [
  DateVariety(
    nameGetter: (l) => l.ajwaDates,
    originGetter: (l) => l.originMadinah,
    descriptionGetter: (l) => l.descAjwa,
    kcal: 277, carbs: 75, fiber: 7, potassium: 696,
    price: 24.00,
    imagePath: 'assets/images/ajwa.png',
    tag: 'ajwa',
  ),
  DateVariety(
    nameGetter: (l) => l.alligDates,
    originGetter: (l) => l.originTunisiaAlgeria,
    descriptionGetter: (l) => l.descAllig,
    kcal: 271, carbs: 73, fiber: 5, potassium: 638,
    price: 16.00,
    imagePath: 'assets/images/allig.png',
    tag: 'allig',
  ),
  DateVariety(
    nameGetter: (l) => l.amberDates,
    originGetter: (l) => l.originMadinah,
    descriptionGetter: (l) => l.descAmber,
    kcal: 281, carbs: 74, fiber: 7, potassium: 668,
    price: 22.00,
    imagePath: 'assets/images/amber.png',
    tag: 'amber',
  ),
  DateVariety(
    nameGetter: (l) => l.aseelDates,
    originGetter: (l) => l.originSindh,
    descriptionGetter: (l) => l.descAseel,
    kcal: 290, carbs: 76, fiber: 6, potassium: 652,
    price: 14.00,
    imagePath: 'assets/images/aseel.png',
    tag: 'aseel',
  ),
  DateVariety(
    nameGetter: (l) => l.degletNourDates,
    originGetter: (l) => l.originTunisiaAlgeria,
    descriptionGetter: (l) => l.descDegletNour,
    kcal: 282, carbs: 75, fiber: 8, potassium: 656,
    price: 18.00,
    imagePath: 'assets/images/deglet_nour.png',
    tag: 'deglet_nour',
  ),
  DateVariety(
    nameGetter: (l) => l.galaxyDates,
    originGetter: (l) => l.originQassim,
    descriptionGetter: (l) => l.descGalaxy,
    kcal: 270, carbs: 72, fiber: 6, potassium: 650,
    price: 16.00,
    imagePath: 'assets/images/galaxy.png',
    tag: 'galaxy',
  ),
  DateVariety(
    nameGetter: (l) => l.kalmiDates,
    originGetter: (l) => l.originMadinah,
    descriptionGetter: (l) => l.descKalmi,
    kcal: 274, carbs: 73, fiber: 7, potassium: 660,
    price: 17.00,
    imagePath: 'assets/images/kalmi.png',
    tag: 'kalmi',
  ),
  DateVariety(
    nameGetter: (l) => l.khormaDates,
    originGetter: (l) => l.originArabianPeninsula,
    descriptionGetter: (l) => l.descKhorma,
    kcal: 268, carbs: 71, fiber: 6, potassium: 642,
    price: 12.00,
    imagePath: 'assets/images/khorma.png',
    tag: 'khorma',
  ),
  DateVariety(
    nameGetter: (l) => l.medjoolDates,
    originGetter: (l) => l.originMadinah,
    descriptionGetter: (l) => l.descMedjool,
    kcal: 277, carbs: 75, fiber: 7, potassium: 696,
    price: 18.50,
    imagePath: 'assets/images/medjool.png',
    tag: 'medjool',
  ),
  DateVariety(
    nameGetter: (l) => l.meneifiDates,
    originGetter: (l) => l.originRiyadh,
    descriptionGetter: (l) => l.descMeneifi,
    kcal: 265, carbs: 70, fiber: 5, potassium: 620,
    price: 13.50,
    imagePath: 'assets/images/meneifi.png',
    tag: 'meneifi',
  ),
  DateVariety(
    nameGetter: (l) => l.muzafatiDates,
    originGetter: (l) => l.originBamIran,
    descriptionGetter: (l) => l.descMuzafati,
    kcal: 278, carbs: 74, fiber: 7, potassium: 648,
    price: 15.00,
    imagePath: 'assets/images/muzafati.png',
    tag: 'muzafati',
  ),
  DateVariety(
    nameGetter: (l) => l.nabtatAliDates,
    originGetter: (l) => l.originQassim,
    descriptionGetter: (l) => l.descNabtatAli,
    kcal: 268, carbs: 71, fiber: 6, potassium: 630,
    price: 14.00,
    imagePath: 'assets/images/nabtat_ali.png',
    tag: 'nabtat_ali',
  ),
  DateVariety(
    nameGetter: (l) => l.rutabDates,
    originGetter: (l) => l.originMadinahQassim,
    descriptionGetter: (l) => l.descRutab,
    kcal: 142, carbs: 38, fiber: 4, potassium: 380,
    price: 22.00,
    imagePath: 'assets/images/rutab.png',
    tag: 'rutab',
  ),
  DateVariety(
    nameGetter: (l) => l.shaisheDates,
    originGetter: (l) => l.originAhsaQassim,
    descriptionGetter: (l) => l.descShaishe,
    kcal: 272, carbs: 73, fiber: 6, potassium: 655,
    price: 15.00,
    imagePath: 'assets/images/shaishe.png',
    tag: 'shaishe',
  ),
  DateVariety(
    nameGetter: (l) => l.sokariDates,
    originGetter: (l) => l.originQassim,
    descriptionGetter: (l) => l.descSokari,
    kcal: 320, carbs: 85, fiber: 8, potassium: 720,
    price: 15.00,
    imagePath: 'assets/images/sukari.png',
    tag: 'sokari',
  ),
  DateVariety(
    nameGetter: (l) => l.sugaeyDates,
    originGetter: (l) => l.originRiyadh,
    descriptionGetter: (l) => l.descSugaey,
    kcal: 290, carbs: 78, fiber: 7, potassium: 680,
    price: 14.50,
    imagePath: 'assets/images/sugaey.png',
    tag: 'sugaey',
  ),
  DateVariety(
    nameGetter: (l) => l.zahidiDates,
    originGetter: (l) => l.originIraqIran,
    descriptionGetter: (l) => l.descZahidi,
    kcal: 270, carbs: 72, fiber: 5, potassium: 610,
    price: 13.00,
    imagePath: 'assets/images/zahidi.png',
    tag: 'zahidi',
  ),
];
