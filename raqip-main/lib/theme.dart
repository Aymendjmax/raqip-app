import 'package:flutter/material.dart';

// ثيم Material 3 الخاص بتطبيق رقيب.
class MaterialTheme {
  final TextTheme textTheme;
  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00677d),
      surfaceTint: Color(0xff00677d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2dbbde),
      onPrimaryContainer: Color(0xff004756),
      secondary: Color(0xff3a6472),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffbbe7f6),
      onSecondaryContainer: Color(0xff3f6876),
      tertiary: Color(0xff7c4899),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffcf96ed),
      onTertiaryContainer: Color(0xff5b2978),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fafd),
      onSurface: Color(0xff171c1f),
      onSurfaceVariant: Color(0xff3d494d),
      outline: Color(0xff6d797e),
      outlineVariant: Color(0xffbcc9ce),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c3134),
      inversePrimary: Color(0xff54d6fa),
      primaryFixed: Color(0xffb3ebff),
      onPrimaryFixed: Color(0xff001f27),
      primaryFixedDim: Color(0xff54d6fa),
      onPrimaryFixedVariant: Color(0xff004e5f),
      secondaryFixed: Color(0xffbee9f9),
      onSecondaryFixed: Color(0xff001f27),
      secondaryFixedDim: Color(0xffa2cddd),
      onSecondaryFixedVariant: Color(0xff214c59),
      tertiaryFixed: Color(0xfff5d9ff),
      onTertiaryFixed: Color(0xff30004a),
      tertiaryFixedDim: Color(0xffe6b4ff),
      onTertiaryFixedVariant: Color(0xff62307f),
      surfaceDim: Color(0xffd5dbdd),
      surfaceBright: Color(0xfff5fafd),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff4f7),
      surfaceContainer: Color(0xffe9eff1),
      surfaceContainerHigh: Color(0xffe4e9ec),
      surfaceContainerHighest: Color(0xffdee3e6),
    );
  }

  ThemeData light() => theme(lightScheme());

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff56d7fb),
      surfaceTint: Color(0xff54d6fa),
      onPrimary: Color(0xff003642),
      primaryContainer: Color(0xff2dbbde),
      onPrimaryContainer: Color(0xff004756),
      secondary: Color(0xffa2cddd),
      onSecondary: Color(0xff013542),
      secondaryContainer: Color(0xff234f5b),
      onSecondaryContainer: Color(0xff95bfce),
      tertiary: Color(0xffe7b5ff),
      onTertiary: Color(0xff4a1667),
      tertiaryContainer: Color(0xffcf96ed),
      onTertiaryContainer: Color(0xff5b2978),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f1416),
      onSurface: Color(0xffdee3e6),
      onSurfaceVariant: Color(0xffbcc9ce),
      outline: Color(0xff869398),
      outlineVariant: Color(0xff3d494d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e6),
      inversePrimary: Color(0xff00677d),
      primaryFixed: Color(0xffb3ebff),
      onPrimaryFixed: Color(0xff001f27),
      primaryFixedDim: Color(0xff54d6fa),
      onPrimaryFixedVariant: Color(0xff004e5f),
      secondaryFixed: Color(0xffbee9f9),
      onSecondaryFixed: Color(0xff001f27),
      secondaryFixedDim: Color(0xffa2cddd),
      onSecondaryFixedVariant: Color(0xff214c59),
      tertiaryFixed: Color(0xfff5d9ff),
      onTertiaryFixed: Color(0xff30004a),
      tertiaryFixedDim: Color(0xffe6b4ff),
      onTertiaryFixedVariant: Color(0xff62307f),
      surfaceDim: Color(0xff0f1416),
      surfaceBright: Color(0xff343a3c),
      surfaceContainerLowest: Color(0xff090f11),
      surfaceContainerLow: Color(0xff171c1f),
      surfaceContainer: Color(0xff1b2023),
      surfaceContainerHigh: Color(0xff252b2d),
      surfaceContainerHighest: Color(0xff303638),
    );
  }

  ThemeData dark() => theme(darkScheme());

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    fontFamily: 'Cairo',
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamily: 'Cairo',
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
    ),
  );

  List<ExtendedColor> get extendedColors => [];
}

// ── ألوان رقيب الإضافية ────────────────────────────────────
class RaqibColors {
  static const Color blueDark = Color(0xff1A4D8F);
  static const Color blueMid = Color(0xff29ABE2);
  static const Color blueLight = Color(0xff5BC8F5);

  static const Color successGreen = Color(0xff2E7D32);
  static const Color warningYellow = Color(0xffF57F17);
  static const Color errorRed = Color(0xffC62828);

  static const Color successGreenLight = Color(0xffE8F5E9);
  static const Color warningYellowLight = Color(0xffFFFDE7);
  static const Color errorRedLight = Color(0xffFFEBEE);

  // تدرج الأزرار
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blueDark, blueMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
