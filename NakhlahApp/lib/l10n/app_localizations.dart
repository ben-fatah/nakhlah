import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  // ── Auth ────────────────────────────────────────────────────────────────
  String get welcomeBack => isArabic ? 'مرحباً بعودتك' : 'WELCOME BACK';
  String get createAccount => isArabic ? 'إنشاء حساب' : 'CREATE ACCOUNT';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get confirmPassword =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get signUp => isArabic ? 'إنشاء حساب' : 'Sign Up';
  String get forgotPassword =>
      isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get continueWithGoogle =>
      isArabic ? 'المتابعة مع Google' : 'Continue with Google';
  String get noAccount =>
      isArabic ? 'ليس لديك حساب؟ ' : "Don't have an account? ";
  String get alreadyAccount =>
      isArabic ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ';

  // ── Sign-Up specifics ────────────────────────────────────────────────────
  String get namePlaceholder => isArabic ? 'علي العتيبي' : 'Ali Al-Otaibi';
  String get emailPlaceholder =>
      isArabic ? 'example@mail.com' : 'example@mail.com';
  String get phoneSaudi =>
      isArabic ? 'رقم الجوال (سعودي)' : 'Phone Number (Saudi)';
  String get skipPhoneVerification =>
      isArabic ? 'تخطى التحقق من الجوال' : 'Skip phone verification';
  String get orDivider => isArabic ? 'أو' : 'OR';
  String get bySigningUp => isArabic
      ? 'بالتسجيل، أنت توافق على '
      : 'By signing up, you agree to our ';
  String get termsOfService => isArabic ? 'شروط الخدمة' : 'Terms of Service';
  String get andWord => isArabic ? ' و ' : ' and ';
  String get privacyPolicy => isArabic ? 'سياسة الخصوصية' : 'Privacy\nPolicy';

  // ── Password requirements ────────────────────────────────────────────────
  String get reqMinLength =>
      isArabic ? '8 أحرف على الأقل' : 'At least 8 characters';
  String get reqUppercase =>
      isArabic ? 'حرف كبير واحد على الأقل' : 'At least one capital letter';
  String get reqNumber =>
      isArabic ? 'رقم واحد على الأقل' : 'At least one number';
  String get reqSpecialChar =>
      isArabic ? 'رمز خاص واحد على الأقل' : 'At least one special character';

  // ── Password Reset (new password screen) ──────────────────────────────────
  String get newPassword => isArabic ? 'كلمة المرور الجديدة' : 'New Password';
  String get confirmNewPassword =>
      isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password';
  String get enterNewPassword =>
      isArabic ? 'أدخل كلمة المرور الجديدة' : 'Enter a new password for';
  String get verifyingResetLink => isArabic
      ? 'جارٍ التحقق من رابط إعادة التعيين...'
      : 'Verifying reset link...';
  String get linkInvalid => isArabic ? 'الرابط غير صالح' : 'Link Invalid';
  String get passwordChanged =>
      isArabic ? 'تم تغيير كلمة المرور!' : 'Password Changed!';
  String get passwordChangedSubtitle => isArabic
      ? 'تم تحديث كلمة المرور بنجاح.\nيمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.'
      : 'Your password has been updated successfully.\nYou can now sign in with your new password.';
  String get goToSignIn => isArabic ? 'الذهاب لتسجيل الدخول' : 'Go to Sign In';
  String get backToSignIn =>
      isArabic ? 'العودة لتسجيل الدخول' : 'Back to Sign In';
  String get confirmNewPasswordBtn =>
      isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password';

  // ── Onboarding ─────────────────────────────────────────────────────
  String get skip => isArabic ? 'تخطى' : 'Skip';
  String get next => isArabic ? 'التالي' : 'Next';
  String get getStarted => isArabic ? 'ابدأ الآن' : 'Get Started';

  // ── Home ────────────────────────────────────────────────────────────────
  String get scanDates => isArabic ? 'مسح التمر' : 'Scan Dates';
  String get scanNow => isArabic ? 'امسح الآن' : 'Scan Now';
  String get recentScans => isArabic ? 'عمليات المسح الأخيرة' : 'Recent Scans';
  String get viewAll => isArabic ? 'عرض الكل' : 'View all';
  String get featuredSellers =>
      isArabic ? 'البائعون المميزون' : 'Featured Sellers';
  String get exploreAll => isArabic ? 'استكشاف الكل' : 'Explore All';
  String get scan => isArabic ? 'مسح' : 'Scan';
  String get explore => isArabic ? 'استكشاف' : 'Explore';
  String get market => isArabic ? 'السوق' : 'Market';
  String get history => isArabic ? 'السجل' : 'History';
  String get home => isArabic ? 'الرئيسية' : 'Home';
  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  String get identifyInSeconds => isArabic
      ? 'تعرف على أصناف التمر في ثوانٍ'
      : 'Identify date varieties in seconds';
  String get greeting => isArabic ? 'مرحباً' : 'Marhaba';
  String get sellerAdTitle =>
      isArabic ? 'تمور سعودية فاخرة' : 'Premium Saudi Dates';
  String get sellerAdSubtitle => isArabic ? 'انضم كبائع' : 'Join as a Seller';

  // ── Profile ─────────────────────────────────────────────────────────────
  String get myProfile => isArabic ? 'ملفي الشخصي' : 'My Profile';
  String get editInformation =>
      isArabic ? 'تعديل المعلومات' : 'Edit Information';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get emailAddress => isArabic ? 'البريد الإلكتروني' : 'Email Address';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get phoneHint => isArabic ? '05xxxxxxxx' : '05xxxxxxxx';
  String get saveUpdates => isArabic ? 'حفظ التغييرات' : 'Save Updates';
  String get saving => isArabic ? 'جارٍ الحفظ...' : 'Saving...';
  String get myJourney => isArabic ? 'رحلتي' : 'My Journey';
  String get datesScanned => isArabic ? 'تمر ممسوح' : 'Dates Scanned';
  String get savedFavorites =>
      isArabic ? 'المفضلة المحفوظة' : 'Saved Favorites';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get changeLanguage => isArabic ? 'تغيير اللغة' : 'Change Language';
  String get currentLanguage => isArabic ? 'العربية' : 'English';
  String get dietaryGoals => isArabic ? 'الأهداف الغذائية' : 'Dietary Goals';
  String get logOut => isArabic ? 'تسجيل الخروج' : 'Log Out';
  String get profileUpdated => isArabic
      ? 'تم تحديث الملف الشخصي بنجاح!'
      : 'Profile updated successfully!';
  String get couldNotLoad =>
      isArabic ? 'تعذر تحميل الملف الشخصي.' : 'Could not load profile.';
  String get failedToSave =>
      isArabic ? 'فشل الحفظ. حاول مجدداً.' : 'Failed to save. Try again.';

  // ── Scan ────────────────────────────────────────────────────────────────
  String get scanDateFruit => isArabic ? 'مسح ثمرة التمر' : 'Scan Date Fruit';
  String get alignDate => isArabic
      ? 'ضع ثمرة التمر داخل الإطار الذهبي'
      : 'Align the date within the gold frame';
  String get gallery => isArabic ? 'المعرض' : 'GALLERY';
  String get flash => isArabic ? 'الفلاش' : 'FLASH';
  String get optimizing =>
      isArabic ? 'جارٍ التحسين...' : 'OPTIMIZING FOR LIGHTING...';
  String get analyzing => isArabic ? 'جارٍ التحليل...' : 'ANALYZING IMAGE...';
  String get imagePicked => isArabic
      ? 'تم اختيار الصورة. اضغط زر المسح للتحليل.'
      : 'Image selected. Tap scan to analyze.';

  // ── Scan Result ──────────────────────────────────────────────────────────
  String get scanResult => isArabic ? 'نتيجة المسح' : 'Scan Result';
  String get confidence => isArabic ? 'نسبة الدقة' : 'Confidence';
  String get origin => isArabic ? 'المنشأ' : 'Origin';
  String get verifiedOrigin => isArabic ? 'المنشأ موثق' : 'VERIFIED ORIGIN';
  String get nutritionPer100g =>
      isArabic ? 'القيمة الغذائية لكل 100 جم' : 'NUTRITION PER 100 G';
  String get caloriesLabel => isArabic ? 'السعرات' : 'CALORIES';
  String get carbsLabel => isArabic ? 'الكربوهيدرات' : 'CARBS';
  String get fiberLabel => isArabic ? 'الألياف' : 'FIBER';
  String get potassiumLabel => isArabic ? 'البوتاسيوم' : 'POTASSIUM';
  String get findSellers => isArabic ? 'ابحث عن بائعين' : 'Find Sellers';
  String get shareResults => isArabic ? 'مشاركة النتائج' : 'Share Results';
  String get scanAgain => isArabic ? 'مسح مجدداً' : 'Scan Again';
  String get errorAnalyzing =>
      isArabic ? 'تعذر تحليل الصورة.' : 'Could not analyze image.';
  String get tryAgain => isArabic ? 'حاول مجدداً' : 'Try Again';
  String shareText(String name, String origin, String confidence) => isArabic
      ? '🌴 نتيجة مسح نخلة:\n'
            'الصنف: $name\n'
            'المنشأ: $origin\n'
            'نسبة الدقة: $confidence\n\n'
            'تم المسح بواسطة تطبيق نخلة 🌿'
      : '🌴 Nakhlah Scan Result:\n'
            'Variety: $name\n'
            'Origin: $origin\n'
            'Confidence: $confidence\n\n'
            'Scanned via the Nakhlah app 🌿';

  // ── Explore ──────────────────────────────────────────────────────────────
  String get exploreDates => isArabic ? 'استكشاف التمور' : 'Explore Dates';
  String get searchHint => isArabic
      ? 'ابحث عن الصنف أو المنشأ أو النكهة...'
      : 'Search variety, origin or flavor...';
  String get allVarieties => isArabic ? 'جميع الأصناف' : 'All Varieties';
  String get noVarietiesFound =>
      isArabic ? 'لا توجد أصناف' : 'No varieties found';
  String get kcalLabel => isArabic ? 'سعرة' : 'kcal';

  // Filter chip labels
  String get filterAjwa => isArabic ? 'عجوة' : 'Ajwa';
  String get filterMedjool => isArabic ? 'مجدول' : 'Medjool';
  String get filterSukkari => isArabic ? 'سكري' : 'Sukkari';
  String get filterKhalas => isArabic ? 'خلاص' : 'Khalas';
  String get filterBarhi => isArabic ? 'برحي' : 'Barhi';
  String get filterSagai => isArabic ? 'صقعي' : 'Sagai';
  String get filterGalaxy => isArabic ? 'جالاكسي' : 'Galaxy';
  String get filterMeneifi => isArabic ? 'منيفي' : 'Meneifi';
  String get filterNabtatAli => isArabic ? 'نبتة علي' : 'Nabtat Ali';
  String get filterRutab => isArabic ? 'رطب' : 'Rutab';
  String get filterShaishe => isArabic ? 'شيشة' : 'Shaishe';

  // Variety names
  String get ajwaAlMadinah => isArabic ? 'عجوة المدينة' : 'Ajwa Al-Madinah';
  String get premiumMedjool => isArabic ? 'مجدول فاخر' : 'Premium Medjool';
  String get sukkariMofatall => isArabic ? 'سكري مفتل' : 'Sukkari Mofatall';
  String get khalasAlAhsa => isArabic ? 'خلاص الأحساء' : 'Khalas Al-Ahsa';
  String get barhiGolden => isArabic ? 'برحي ذهبي' : 'Barhi Golden';
  String get sagaiDates => isArabic ? 'تمر صقعي' : 'Sagai Dates';
  String get galaxyDates => isArabic ? 'تمر جالاكسي' : 'Galaxy Dates';
  String get meneifiDates => isArabic ? 'تمر منيفي' : 'Meneifi Dates';
  String get nabtatAliDates => isArabic ? 'تمر نبتة علي' : 'Nabtat Ali Dates';
  String get rutabDates => isArabic ? 'رطب طازج' : 'Fresh Rutab';
  String get shaisheDates => isArabic ? 'تمر شيشة' : 'Shaishe Dates';

  // Variety origins
  String get originMadinah =>
      isArabic ? 'المدينة المنورة، السعودية' : 'Madinah, KSA';
  String get originJericho => isArabic ? 'أريحا، فلسطين' : 'Jericho, Palestine';
  String get originQassim => isArabic ? 'القصيم، السعودية' : 'Al-Qassim, KSA';
  String get originAhsa => isArabic ? 'الأحساء، السعودية' : 'Al-Ahsa, KSA';
  String get originRiyadh => isArabic ? 'الرياض، السعودية' : 'Riyadh, KSA';
  String get originSaudiArabia =>
      isArabic ? 'المملكة العربية السعودية' : 'Saudi Arabia';
  String get originGulfRegion =>
      isArabic ? 'منطقة الخليج' : 'Gulf Region';
  String get originIraq =>
      isArabic ? 'العراق / القصيم، السعودية' : 'Iraq / Al-Qassim, KSA';
  String get originMadinahQassim =>
      isArabic ? 'المدينة المنورة / القصيم، السعودية' : 'Al-Madinah / Al-Qassim, KSA';
  String get originAhsaQassim =>
      isArabic ? 'الأحساء / القصيم، السعودية' : 'Al-Ahsa / Al-Qassim, KSA';

  // ── Notifications ────────────────────────────────────────────────────────
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get noNotificationsYet =>
      isArabic ? 'لا توجد إشعارات حتى الآن' : 'No notifications yet';
  String get noNotificationsSubtitle => isArabic
      ? 'ستظهر هنا إشعارات العروض والتحديثات'
      : 'Offers and updates will appear here';

  // ── History ──────────────────────────────────────────────────────────────
  String get scanHistory => isArabic ? 'سجل المسح' : 'Scan History';
  String get noScansYet => isArabic ? 'لا توجد عمليات مسح بعد' : 'No scans yet';
  String get noScansYetSubtitle => isArabic
      ? 'امسح ثمرة تمر لرؤية سجلك هنا'
      : 'Scan a date fruit to see your history here';

  // ── Product Detail ────────────────────────────────────────────────────────
  String get productDetails => isArabic ? 'تفاصيل المنتج' : 'Product Details';
  String get description => isArabic ? 'الوصف' : 'Description';
  String get sellers => isArabic ? 'البائعون' : 'Sellers';
  String get addToCart => isArabic ? 'أضف إلى السلة' : 'Add to Cart';
  String get addedToFavorites =>
      isArabic ? 'أُضيف إلى المفضلة ❤' : 'Added to favorites ❤';
  String get removedFromFavorites =>
      isArabic ? 'أُزيل من المفضلة' : 'Removed from favorites';
  String get noSellersFound => isArabic
      ? 'لا يوجد بائعون لهذا المنتج'
      : 'No sellers found for this product';
  String get viewSellerProfile =>
      isArabic ? 'عرض ملف البائع' : 'View Seller Profile';

  // ── Seller Page ───────────────────────────────────────────────────────────
  String get sellerProfile => isArabic ? 'ملف البائع' : 'Seller Profile';
  String get aboutSeller => isArabic ? 'عن البائع' : 'About';
  String get sellerProducts => isArabic ? 'المنتجات' : 'Products';
  String get contactSeller => isArabic ? 'تواصل' : 'Contact';
  String get callSeller => isArabic ? 'اتصل بالبائع' : 'Call Seller';
  String get verifiedSeller => isArabic ? 'بائع موثق' : 'Verified Seller';
  String get topSeller => isArabic ? 'أفضل بائع' : 'Top Seller';
  String get noProductsForSeller =>
      isArabic ? 'لا توجد منتجات لهذا البائع' : 'No products listed';
  String get reviewsLabel => isArabic ? 'تقييم' : 'reviews';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
