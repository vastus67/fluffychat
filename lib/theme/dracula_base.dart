import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dracula_colors.dart';
import 'dracula_text.dart';

/// Shared base for all Dracula accent themes.
/// 
/// Defines:
/// - Background / surface colors (shared across all themes)
/// - TextTheme
/// - BorderRadius tokens
/// - Spacing constants
/// - Elevation defaults
/// 
/// All accent themes extend this base.
class DraculaBase {
  DraculaBase._();

  // === Radius tokens (8–16px) ===
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  static const BorderRadius radiusSmAll =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius radiusMdAll =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius radiusLgAll =
      BorderRadius.all(Radius.circular(radiusLarge));

  // === Standard spacing / padding tokens ===
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;

  /// Muted foreground color for timestamps / metadata.
  static Color mutedForeground() => DraculaColors.muted.withOpacity(0.9);

  /// Build base ColorScheme for Dracula themes.
  /// 
  /// [accentColor] is the primary/secondary color for the specific theme.
  /// [errorColor] defaults to Dracula red, but can be overridden (e.g., for red theme).
  static ColorScheme buildColorScheme({
    required Color accentColor,
    Color? errorColor,
  }) {
    return ColorScheme.dark(
      // Base surfaces (shared)
      surface: DraculaColors.background,
      onSurface: DraculaColors.foreground,
      surfaceContainerHighest: DraculaColors.currentLine,
      
      // Accent colors
      primary: accentColor,
      onPrimary: DraculaColors.background,
      primaryContainer: accentColor.withOpacity(0.2),
      onPrimaryContainer: accentColor,
      
      secondary: accentColor.withOpacity(0.8),
      onSecondary: DraculaColors.background,
      secondaryContainer: accentColor.withOpacity(0.15),
      onSecondaryContainer: accentColor,
      
      tertiary: accentColor.withOpacity(0.6),
      onTertiary: DraculaColors.background,
      tertiaryContainer: accentColor.withOpacity(0.1),
      onTertiaryContainer: accentColor,
      
      // Error (red by default, can override)
      error: errorColor ?? DraculaColors.red,
      onError: DraculaColors.background,
      
      // Other
      outline: DraculaColors.muted,
      outlineVariant: DraculaColors.muted.withOpacity(0.5),
      shadow: Colors.black.withOpacity(0.5),
      
      // Surfaces
      surfaceContainer: DraculaColors.currentLine.withOpacity(0.5),
      surfaceContainerLow: DraculaColors.currentLine.withOpacity(0.3),
      surfaceContainerHigh: DraculaColors.currentLine.withOpacity(0.7),
      
      // Inverse
      inverseSurface: DraculaColors.foreground,
      onInverseSurface: DraculaColors.background,
      inversePrimary: accentColor,
    );
  }

  /// Build complete ThemeData with Dracula styling.
  /// 
  /// This is the base that all accent themes extend.
  static ThemeData buildTheme({
    required ColorScheme colorScheme,
    required BuildContext context,
    bool isColumnMode = false,
  }) {
    final textTheme = DraculaText.buildTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // Surfaces
      scaffoldBackgroundColor: DraculaColors.background,
      canvasColor: DraculaColors.background,
      cardColor: DraculaColors.currentLine,
      dividerColor: DraculaColors.currentLine,
      
      // Typography
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        toolbarHeight: isColumnMode ? 72 : 56,
        backgroundColor: DraculaColors.background,
        foregroundColor: DraculaColors.foreground,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.primary),
        actionsIconTheme: IconThemeData(color: colorScheme.primary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor: DraculaColors.background,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(width: 1.5, color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DraculaColors.currentLine.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(spacingMd),
        hintStyle: TextStyle(color: DraculaColors.muted),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: DraculaColors.currentLine,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: DraculaColors.currentLine.withOpacity(0.5),
        labelStyle: TextStyle(color: DraculaColors.foreground),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        showCheckmark: false,
      ),
      
      // Switch & Checkbox
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return DraculaColors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return DraculaColors.currentLine;
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return DraculaColors.currentLine;
        }),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return DraculaColors.muted;
        }),
      ),
      
      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: DraculaColors.currentLine,
        linearTrackColor: DraculaColors.currentLine,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DraculaColors.currentLine,
        contentTextStyle: TextStyle(color: DraculaColors.foreground),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: DraculaColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DraculaColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),
      
      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: DraculaColors.currentLine,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: DraculaColors.foreground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // List tile
      listTileTheme: ListTileThemeData(
        textColor: DraculaColors.foreground,
        iconColor: colorScheme.primary,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer,
      ),
      
      // Navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DraculaColors.background,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: DraculaColors.muted);
        }),
      ),
      
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: DraculaColors.background,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: DraculaColors.muted),
        indicatorColor: colorScheme.primaryContainer,
      ),
      
      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: DraculaColors.muted,
        indicatorColor: colorScheme.primary,
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: DraculaColors.currentLine,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
      ),
    );
  }
}
