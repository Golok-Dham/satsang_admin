import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

/// Available theme options for the admin panel
enum AdminTheme {
  // Using valid FlexScheme values from FlexColorScheme 8.x
  aquaBlue('Aqua Blue', FlexScheme.aquaBlue),
  indigo('Indigo Night', FlexScheme.indigo),
  blueWhale('Blue Whale', FlexScheme.blueWhale),
  hippieBlue('Hippie Blue', FlexScheme.hippieBlue),
  brandBlue('Brand Blue', FlexScheme.brandBlue),
  deepPurple('Deep Purple', FlexScheme.deepPurple),
  green('Forest Green', FlexScheme.green),
  espresso('Espresso', FlexScheme.espresso);

  const AdminTheme(this.displayName, this.scheme);
  final String displayName;
  final FlexScheme scheme;
}

/// Theme mode (light/dark/system)
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.light;
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey) ?? 0;
    state = ThemeMode.values[modeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

/// Selected color scheme
@riverpod
class AdminThemeNotifier extends _$AdminThemeNotifier {
  static const _themeKey = 'admin_theme';

  @override
  AdminTheme build() {
    _loadTheme();
    return AdminTheme.indigo; // Default to Indigo as requested
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? AdminTheme.indigo.index;
    if (themeIndex < AdminTheme.values.length) {
      state = AdminTheme.values[themeIndex];
    }
  }

  Future<void> setTheme(AdminTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
}

/// Provides the current light theme
@riverpod
ThemeData lightTheme(Ref ref) {
  final adminTheme = ref.watch(adminThemeProvider);
  return FlexThemeData.light(
    scheme: adminTheme.scheme,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      fabUseShape: true,
      fabAlwaysCircular: false,
      fabSchemeColor: SchemeColor.primary,
      chipSchemeColor: SchemeColor.primary,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorBackgroundAlpha: 21,
      inputDecoratorRadius: 8.0,
      inputDecoratorUnfocusedHasBorder: true,
      inputDecoratorFocusedHasBorder: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      cardRadius: 12.0,
      dialogRadius: 16.0,
      appBarScrolledUnderElevation: 0,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}

/// Provides the current dark theme
@riverpod
ThemeData darkTheme(Ref ref) {
  final adminTheme = ref.watch(adminThemeProvider);
  return FlexThemeData.dark(
    scheme: adminTheme.scheme,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
      fabUseShape: true,
      fabAlwaysCircular: false,
      fabSchemeColor: SchemeColor.primary,
      chipSchemeColor: SchemeColor.primary,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorBackgroundAlpha: 43,
      inputDecoratorRadius: 8.0,
      inputDecoratorUnfocusedHasBorder: true,
      inputDecoratorFocusedHasBorder: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      cardRadius: 12.0,
      dialogRadius: 16.0,
      appBarScrolledUnderElevation: 0,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}

/// Sidebar colors based on current theme
@riverpod
Color sidebarColor(Ref ref) {
  final adminTheme = ref.watch(adminThemeProvider);
  final themeMode = ref.watch(themeModeProvider);
  final isDark = themeMode == ThemeMode.dark;

  // Get deep variant of primary color for sidebar
  final colors = FlexSchemeColor.from(primary: FlexColor.schemes[adminTheme.scheme]!.light.primary);

  if (isDark) {
    return FlexColor.schemes[adminTheme.scheme]!.dark.primaryContainer.darken(40);
  }
  return colors.primary.darken(35);
}
