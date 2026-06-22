import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'home_screen.dart';

/// نقطة تشغيل تطبيق رقيب:
/// 1) تهيئة Flutter.
/// 2) تثبيت اتجاه الشاشة عمودي.
/// 3) تحميل SharedPreferences وتمريرها للتطبيق.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(RaqibApp(prefs: prefs));
}

class RaqibApp extends StatefulWidget {
  /// مرجع التخزين المحلي للإعدادات (لغة/مظهر/...).
  final SharedPreferences prefs;
  const RaqibApp({super.key, required this.prefs});

  @override
  State<RaqibApp> createState() => _RaqibAppState();
}

class _RaqibAppState extends State<RaqibApp> {
  /// المظهر الحالي للتطبيق (فاتح/داكن/تلقائي).
  late ThemeMode _themeMode;

  /// اللغة الحالية للتطبيق (`ar` أو `en`).
  late String _languagePreference;

  String get _effectiveLanguage {
    if (_languagePreference == 'auto') {
      final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
      return code.startsWith('ar') ? 'ar' : 'en';
    }
    return _languagePreference == 'ar' ? 'ar' : 'en';
  }

  @override
  void initState() {
    super.initState();
    final savedTheme = widget.prefs.getString('theme_mode') ?? 'system';
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
    _languagePreference = widget.prefs.getString('language') ?? 'auto';
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    final key = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark  => 'dark',
      _               => 'system',
    };
    widget.prefs.setString('theme_mode', key);
  }

  void setLanguage(String lang) {
    setState(() => _languagePreference = lang);
    widget.prefs.setString('language', lang);
  }

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(const TextTheme());
    final lang = _effectiveLanguage;
    final isAr = lang == 'ar';

    return MaterialApp(
      title: 'Raqib',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      locale: Locale(lang),
      builder: (context, child) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: HomeScreen(
        prefs: widget.prefs,
        onThemeChanged: setThemeMode,
        onLanguageChanged: setLanguage,
        currentTheme: _themeMode,
        currentLanguage: lang,
      ),
    );
  }
}
