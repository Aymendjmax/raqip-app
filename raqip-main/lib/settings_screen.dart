import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// شاشة الإعدادات الموحدة للتطبيق (اللغة/المظهر/نوع الخريطة/عن التطبيق).

// ── نصوص التطبيق (عربي / إنجليزي) ──────────────────────────
class S {
  final bool isAr;
  const S(this.isAr);

  // Settings
  String get settings      => isAr ? 'الإعدادات'        : 'Settings';
  String get language      => isAr ? 'اللغة'             : 'Language';
  String get appearance    => isAr ? 'المظهر'            : 'Appearance';
  String get displayMode   => isAr ? 'وضع العرض'         : 'Display Mode';
  String get light         => isAr ? 'فاتح'              : 'Light';
  String get dark          => isAr ? 'داكن'              : 'Dark';
  String get auto          => isAr ? 'تلقائي'            : 'Auto';
  String get map           => isAr ? 'الخريطة'           : 'Map';
  String get mapType       => isAr ? 'نوع الخريطة'       : 'Map Type';
  String get normal        => isAr ? 'عادي'              : 'Normal';
  String get aboutApp      => isAr ? 'عن التطبيق'        : 'About App';
  String get version       => isAr ? 'الإصدار'           : 'Version';
  String get aboutDesc     => isAr
      ? 'رقيب — تطبيق ذكي لحفظ إحداثياتك المفضلة وإدارتها بسهولة.'
      : 'Raqib — Smart app to save and manage your favorite locations.';
  String get developer     => isAr ? 'المطور'            : 'Developer';
  String get devBio        => isAr
      ? 'مرحباً! أنا Akio، مطور شغوف بعمر 15 سنة. بدأت رحلتي مع البرمجة منذ عام تقريباً، ومنذ ذلك الحين وأنا أتعلم وأبني مشاريع جديدة باستمرار.'
      : "Hi! I'm Akio, a passionate 15-year-old developer. I started my programming journey about a year ago, and since then I've been learning and building new projects continuously.";
  String get officialSite  => isAr ? 'الموقع الرسمي'     : 'Official Website';

  String get appStatus => isAr ? 'حالة التطبيق' : 'Application Status';
  String get appUpToDate => isAr ? 'أنت تستخدم أحدث إصدار' : 'You are using the latest version';
  String get updateAvailable => isAr ? 'يوجد تحديث جديد متوفر' : 'A new update is available';
  String get latestVersion => isAr ? 'الإصدار الجديد' : 'Latest version';
  String get downloadUpdate => isAr ? 'تحميل التحديث' : 'Download Update';
  String get installNow => isAr ? 'تحديث الآن' : 'Install Now';
  String get updateCheckFailed => isAr ? 'تعذر التحقق من التحديثات' : 'Failed to check for updates';
  String get autoLanguage => isAr ? 'تلقائي' : 'Auto';
  String get donation => isAr ? 'الدعم' : 'Support';
  String get copyRip => isAr ? 'نسخ رقم Rip' : 'Copy RIP Number';
  String get ripCopied => isAr ? 'تم نسخ رقم Rip' : 'RIP number copied';
  String get paypalSoon => isAr ? 'سيتم دعم PayPal قريباً.' : 'PayPal support is coming soon.';

  // Home
  String get currentLocation => isAr ? 'موقعك الحالي'           : 'Your Location';
  String get noLocation      => isAr ? 'لم يتم تحديد الموقع بعد' : 'Location not set yet';
  String get settingsBtn     => isAr ? 'إعدادات'                 : 'Settings';
  String get savedBtn        => isAr ? 'محفوظاتي'               : 'Saved';
  String get copyBtn         => isAr ? 'نسخ'                     : 'Copy';
  String get saveBtn         => isAr ? 'حفظ'                     : 'Save';
  String get cancel          => isAr ? 'إلغاء'                   : 'Cancel';
  String get save            => isAr ? 'حفظ'                     : 'Save';
  String get locating        => isAr ? 'جاري تحديد موقعك...'     : 'Locating...';
  String get locationFound   => isAr ? 'تم تحديد موقعك'          : 'Location found';
  String get locationFailed  => isAr ? 'تعذر تحديد الموقع'       : 'Failed to get location';
  String get locateFirst     => isAr ? 'يرجى تحديد موقعك أولاً'  : 'Please locate yourself first';
  String get saveLocation    => isAr ? 'حفظ الموقع'              : 'Save Location';
  String get locationName    => isAr ? 'اسم الموقع'              : 'Location name';
  String get locationHint    => isAr ? 'مثال: البيت، العمل...'   : 'e.g. Home, Office...';
  String get locationSaved   => isAr ? 'تم حفظ الموقع بنجاح'     : 'Location saved!';
  String get noCoordsMsg     => isAr ? 'لا يوجد موقع لنسخه'      : 'No location to copy';
  String get coordsCopied    => isAr ? 'تم نسخ الإحداثيات'       : 'Coordinates copied!';
  String get noInternet      => isAr ? 'لا يوجد اتصال بالإنترنت'  : 'No internet connection';
  String get internetBack    => isAr ? 'تم استعادة الاتصال بالإنترنت' : 'Internet connection restored';
  String get loadingLocation => isAr ? 'جاري تحميل الموقع...'      : 'Loading location...';
  String get loadingRoute    => isAr ? 'جاري تحميل المسار...'      : 'Loading route...';
  String get openOnMap       => isAr ? 'عرض على الخريطة'          : 'Show on map';
  String get routeToPlace    => isAr ? 'تعيين مسار لهذا المكان'    : 'Route to this place';
  String get back            => isAr ? 'عودة'                      : 'Back';
  String get routeCancelled  => isAr ? 'تم إلغاء المسار'           : 'Route cancelled';
  String get routeFailed     => isAr ? 'تعذر جلب المسار عبر الطرق' : 'Failed to fetch road route';
  String get routeSingleOnly => isAr ? 'تم العثور على مسار واحد فقط في هذه المنطقة حالياً.' : 'Only one route was found for this area right now.';
  String get routeNeedsInternet => isAr ? 'يلزم اتصال إنترنت لتعيين المسار' : 'Internet is required to start routing';
  String get remainingDistance => isAr ? 'المسافة المتبقية'         : 'Remaining distance';
  String get cancelRoute     => isAr ? 'إلغاء المسار'              : 'Cancel route';
  String get arrived         => isAr ? 'تم الوصول إلى الوجهة'      : 'You have arrived';
  String get routeStarted    => isAr ? 'تم بدء التوجيه للموقع'      : 'Routing started';
  String get pickLocationFirst => isAr ? 'اختر موقعاً محفوظاً أولاً' : 'Select a saved location first';
  String get chooseRoute     => isAr ? 'اختر مساراً مناسباً'         : 'Choose a suitable route';
  String get startNavigation => isAr ? 'بدء التوجيه'                : 'Start navigation';
  String get routeOptionFast => isAr ? 'الأسرع'                     : 'Fastest';
  String get routeOptionAlt  => isAr ? 'بديل'                       : 'Alternative';
  String get nextDirection   => isAr ? 'التوجيه القادم'             : 'Next direction';
  String get estimatedTime   => isAr ? 'الوقت المتوقع'              : 'Estimated time';
  String get tapRouteHint    => isAr ? 'يمكنك الضغط على أي مسار في الخريطة لتغييره فورًا.' : 'Tap any route on the map to switch instantly.';
  String get goBack          => isAr ? 'عد للمحفوظات'               : 'Go back to saved list';
  String get gpsOff          => isAr ? 'GPS غير مفعّل'           : 'GPS is off';
  String get gpsOffMsg       => isAr
      ? 'يحتاج تطبيق رقيب إلى تفعيل GPS لتحديد موقعك الحالي.'
      : 'Raqib needs GPS to determine your current location.';
  String get enableGps       => isAr ? 'تفعيل GPS'               : 'Enable GPS';

  // Saved Screen
  String get saved           => isAr ? 'المحفوظات'               : 'Saved';
  String get searchHint      => isAr ? 'ابحث عن موقع...'         : 'Search locations...';
  String get confirmDelete   => isAr ? 'تأكيد الحذف'             : 'Confirm Delete';
  String get deleteMsg       => isAr ? 'هل تريد حذف'             : 'Delete';
  String get cannotUndo      => isAr ? 'لا يمكن التراجع عن هذا الإجراء.' : 'This action cannot be undone.';
  String get deleted         => isAr ? 'تم حذفه'                 : 'deleted';
  String get delete          => isAr ? 'حذف'                     : 'Delete';
  String get nameUpdated     => isAr ? 'تم تحديث الاسم'           : 'Name updated!';
  String get noResults       => isAr ? 'لا توجد نتائج'            : 'No results';
  String get noSaved         => isAr ? 'لا توجد مواقع محفوظة'     : 'No saved locations';
  String get noSavedHint     => isAr ? 'احفظ موقعك من الصفحة الرئيسية' : 'Save a location from the home screen';
  String get copy            => isAr ? 'نسخ'                     : 'Copy';
  String get edit            => isAr ? 'تعديل'                   : 'Edit';
  String get addLocation     => isAr ? 'إضافة موقع'               : 'Add location';
  String get latitude        => isAr ? 'خط العرض'                : 'Latitude';
  String get longitude       => isAr ? 'خط الطول'                : 'Longitude';
  String get coordinates     => isAr ? 'الإحداثيات'              : 'Coordinates';
  String get coordinatesHint => isAr
      ? 'مثال: 37.7749, -122.4194'
      : 'e.g. 37.7749, -122.4194';
  String get invalidCoords   => isAr ? 'الإحداثيات غير صحيحة'      : 'Invalid coordinates';
  String get locationAdded   => isAr ? 'تمت إضافة الموقع بنجاح'    : 'Location added successfully';

  // Widget Section
  String get widgetTitle     => isAr ? 'الويدجت'                 : 'Widgets';
  String get widgetDesc      => isAr
      ? 'أضف ويدجت رقيب لشاشتك الرئيسية للوصول السريع لإحداثياتك'
      : 'Add Raqib widget to your home screen for quick access to your coordinates';
  String get widgetSmall     => isAr ? 'صغير'                    : 'Small';
  String get widgetMedium    => isAr ? 'متوسط'                   : 'Medium';
  String get widgetLarge     => isAr ? 'كبير'                    : 'Large';
  String get widgetSmallDesc => isAr ? 'إحداثيات + نسخ'          : 'Coords + Copy';
  String get widgetMediumDesc=> isAr ? 'اسم الموقع + أزرار'      : 'Location + Buttons';
  String get widgetLargeDesc => isAr ? 'قائمة آخر 3 مواقع'       : 'Last 3 locations';
  String get addWidget       => isAr ? '+ إضافة'                 : '+ Add';
  String get widgetAdded     => isAr ? 'اتبع التعليمات لإضافة الويدجت' : 'Follow instructions to add widget';
}

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final ThemeMode currentTheme;
  final String currentLanguage;
  final String currentMapType;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onMapTypeChanged;

  const SettingsScreen({
    super.key,
    required this.prefs,
    required this.currentTheme,
    required this.currentLanguage,
    required this.currentMapType,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onMapTypeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode;
  late String _language;
  late String _mapType;
  UpdateInfo? _updateInfo;
  String _currentVersion = '2.0.0';
  bool _isCheckingUpdate = true;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0;
  File? _downloadedApk;
  List<String> _videoLinks = [];

  @override
  void initState() {
    super.initState();
    _themeMode = widget.currentTheme;
    _language  = widget.prefs.getString('language') ?? 'auto';
    _mapType   = widget.currentMapType;
    _prepareUpdateState();
  }



  Future<void> _prepareUpdateState() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version.isEmpty ? '2.0.0' : info.version;
    } catch (_) {}
    await _checkForUpdates(autoOpen: true);
  }
  String get _effectiveLanguage {
    if (_language == 'auto') {
      final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      return code.startsWith('ar') ? 'ar' : 'en';
    }
    return _language == 'ar' ? 'ar' : 'en';
  }

  Future<void> _checkForUpdates({bool autoOpen = false}) async {
    setState(() => _isCheckingUpdate = true);
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        if (mounted) setState(() => _isCheckingUpdate = false);
        return;
      }
      final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/fifikoridek2-boop/akio-api/main/raqip/README.md',
      ));
      if (response.statusCode != 200) {
        if (mounted) setState(() => _updateInfo = null);
        return;
      }
      final parsed = UpdateInfo.parse(response.body);
      if (parsed == null) {
        if (mounted) setState(() => _updateInfo = null);
        return;
      }
      final apk = await _existingApkIfValid(parsed.version);
      if (!mounted) return;
      setState(() {
        _updateInfo = parsed;
        _videoLinks = _extractVideoLinks(_effectiveLanguage == 'ar' ? parsed.textAr : parsed.textEn);
        _isDownloaded = apk != null;
        _downloadedApk = apk;
      });
      if (autoOpen && parsed.hasUpdate(_currentVersion)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openUpdateSheet();
        });
        await _downloadUpdate(forceRefresh: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _updateInfo = null);
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<File?> _existingApkIfValid(String version) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/raqip-update-$version.apk');
    if (!await file.exists()) return null;
    if (await file.length() == 0) return null;
    return file;
  }

  Future<void> _downloadUpdate({bool forceRefresh = false}) async {
    final update = _updateInfo;
    if (update == null) return;
    setState(() { _isDownloading = true; _downloadProgress = 0; });
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/raqip-update-${update.version}.apk');
    if (forceRefresh && await file.exists()) {
      await file.delete();
    }
    final request = http.Request('GET', Uri.parse(update.downloadUrl));
    final response = await request.send();
    final sink = file.openWrite();
    final total = response.contentLength ?? 0;
    int received = 0;
    await for (final chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (mounted && total > 0) {
        setState(() => _downloadProgress = received / total);
      }
    }
    await sink.flush();
    await sink.close();
    final ok = await file.exists() && await file.length() > 0;
    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _isDownloaded = ok;
      _downloadedApk = ok ? file : null;
    });
  }

  Future<void> _installUpdate() async {
    final file = _downloadedApk;
    if (file == null || !await file.exists() || await file.length() == 0) return;
    await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
  }

  void _openUpdateSheet() {
    final update = _updateInfo;
    if (update == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final s = S(_effectiveLanguage == 'ar');
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children:[
              Text('${s.latestVersion}: ${update.version}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: Markdown(
                  controller: controller,
                  data: _effectiveLanguage == 'ar' ? update.textAr : update.textEn,
                  imageBuilder: (uri, title, alt) => GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(child: Image.network(uri.toString(), fit: BoxFit.contain)),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(uri.toString()),
                    ),
                  ),
                  onTapLink: (text, href, title) async {
                    if (href == null) return;
                    final uri = Uri.parse(href);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              if (_videoLinks.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._videoLinks.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: Text(link),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _isDownloading ? null : (_isDownloaded ? _installUpdate : _downloadUpdate),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(_isDownloading ? '${(_downloadProgress * 100).toStringAsFixed(0)}%' : (_isDownloaded ? s.installNow : s.downloadUpdate)),
              ))
            ]),
          ),
        );
      },
    );
  }

  List<String> _extractVideoLinks(String markdownText) {
    final matches = RegExp(r'https?:\/\/[^\s\)]+', caseSensitive: false)
        .allMatches(markdownText)
        .map((m) => m.group(0)!)
        .where((url) =>
            url.contains('youtube.com') ||
            url.contains('youtu.be') ||
            url.contains('vimeo.com') ||
            url.endsWith('.mp4') ||
            url.endsWith('.webm'))
        .toSet()
        .toList();
    return matches;
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = S(_effectiveLanguage == 'ar');

    return Directionality(
      textDirection: _effectiveLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.settings),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── اللغة ─────────────────────────────────
            _SettingsCard(
              icon: Icons.language_rounded,
              title: s.language,
              child: Row(
                children: [
                  _SegBtn(
                    label: s.autoLanguage,
                    selected: _language == 'auto',
                    onTap: () {
                      setState(() => _language = 'auto');
                      widget.onLanguageChanged('auto');
                    },
                  ),
                  const SizedBox(width: 8),
                  _SegBtn(
                    label: 'العربية',
                    selected: _language == 'ar',
                    onTap: () {
                      setState(() => _language = 'ar');
                      widget.onLanguageChanged('ar');
                    },
                  ),
                  const SizedBox(width: 8),
                  _SegBtn(
                    label: 'English',
                    selected: _language == 'en',
                    onTap: () {
                      setState(() => _language = 'en');
                      widget.onLanguageChanged('en');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── المظهر ────────────────────────────────
            _SettingsCard(
              icon: Icons.palette_rounded,
              title: s.appearance,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.displayMode,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SegBtn(
                        icon: Icons.light_mode_rounded,
                        label: s.light,
                        selected: _themeMode == ThemeMode.light,
                        onTap: () {
                          setState(() => _themeMode = ThemeMode.light);
                          widget.onThemeChanged(ThemeMode.light);
                        },
                      ),
                      const SizedBox(width: 8),
                      _SegBtn(
                        icon: Icons.dark_mode_rounded,
                        label: s.dark,
                        selected: _themeMode == ThemeMode.dark,
                        onTap: () {
                          setState(() => _themeMode = ThemeMode.dark);
                          widget.onThemeChanged(ThemeMode.dark);
                        },
                      ),
                      const SizedBox(width: 8),
                      _SegBtn(
                        icon: Icons.brightness_auto_rounded,
                        label: s.auto,
                        selected: _themeMode == ThemeMode.system,
                        onTap: () {
                          setState(() => _themeMode = ThemeMode.system);
                          widget.onThemeChanged(ThemeMode.system);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── الخريطة ───────────────────────────────
            _SettingsCard(
              icon: Icons.map_rounded,
              title: s.map,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.mapType,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SegBtn(
                        icon: Icons.brightness_auto_rounded,
                        label: s.auto,
                        selected: _mapType == 'auto',
                        onTap: () {
                          setState(() => _mapType = 'auto');
                          widget.onMapTypeChanged('auto');
                        },
                      ),
                      const SizedBox(width: 8),
                      _SegBtn(
                        icon: Icons.wb_sunny_rounded,
                        label: s.light,
                        selected: _mapType == 'normal',
                        onTap: () {
                          setState(() => _mapType = 'normal');
                          widget.onMapTypeChanged('normal');
                        },
                      ),
                      const SizedBox(width: 8),
                      _SegBtn(
                        icon: Icons.nightlight_round,
                        label: s.dark,
                        selected: _mapType == 'dark',
                        onTap: () {
                          setState(() => _mapType = 'dark');
                          widget.onMapTypeChanged('dark');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── عن التطبيق ────────────────────────────
            _SettingsCard(
              icon: Icons.info_outline_rounded,
              title: s.aboutApp,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.version,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      Text('2.0.0',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(s.aboutDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _SettingsCard(
              icon: _updateInfo?.hasUpdate(_currentVersion) == true ? Icons.system_update_rounded : Icons.verified_rounded,
              title: s.appStatus,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _updateInfo?.hasUpdate(_currentVersion) == true ? _openUpdateSheet : null,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _isCheckingUpdate
                      ? const LinearProgressIndicator()
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_updateInfo == null
                              ? s.updateCheckFailed
                              : (_updateInfo?.hasUpdate(_currentVersion) == true
                                  ? s.updateAvailable
                                  : s.appUpToDate)),
                          if (_updateInfo?.hasUpdate(_currentVersion) == true) ...[
                            const SizedBox(height: 4),
                            Text('${s.latestVersion}: ${_updateInfo?.version ?? ''}'),
                          ]
                        ]),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── المطور ────────────────────────────────
            _SettingsCard(
              icon: Icons.person_rounded,
              title: s.developer,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage:
                            const AssetImage('lib/assets/images/developer.png'),
                        onBackgroundImageError: (_, __) {},
                        child: const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Akio | اكيو',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(s.devBio,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri =
                            Uri.parse('https://akio-web.vercel.app');
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Akio | Codex'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              icon: Icons.volunteer_activism_rounded,
              title: s.donation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RIP',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '004 00418 4580272147 08',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: '004 00418 4580272147 08'),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.ripCopied)),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(s.copyRip),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.paypalSoon,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String textAr;
  final String textEn;

  const UpdateInfo({required this.version, required this.downloadUrl, required this.textAr, required this.textEn});

  static UpdateInfo? parse(String readme) {
    String? extractField(String key) {
      final pattern = RegExp(r'<!--\s*' + key + r'\s*:(.*?)-->', dotAll: true);
      return pattern.firstMatch(readme)?.group(1)?.trim();
    }

    String? extractBlock(String key) {
      final pattern = RegExp(
        r'<!--\s*' + key + r'_START\s*-->([\s\S]*?)<!--\s*' + key + r'_END\s*-->',
      );
      return pattern.firstMatch(readme)?.group(1)?.trim();
    }

    final version = extractField('VERSION');
    final download = extractField('DOWNLOAD');
    final textAr = extractBlock('TEXT_AR');
    final textEn = extractBlock('TEXT_EN');
    if ([version, download, textAr, textEn].any((e) => e == null || e!.isEmpty)) {
      return null;
    }
    return UpdateInfo(
      version: version!,
      downloadUrl: download!,
      textAr: textAr!,
      textEn: textEn!,
    );
  }

  bool hasUpdate(String currentVersion) => _compare(version, currentVersion) > 0;

  int _compare(String a, String b) {
    final pa = a.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final pb = b.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final maxLen = pa.length > pb.length ? pa.length : pb.length;
    for (int i = 0; i < maxLen; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y ? 1 : -1;
    }
    return 0;
  }

}

// ── Widgets مساعدة ────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 18,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant),
                const SizedBox(height: 2),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
