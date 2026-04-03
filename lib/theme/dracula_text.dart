import 'package:flutter/material.dart';

/// Typography helpers for the Dracula theme.
///
/// Uses Inter / SF Pro–like proportions via fallback families and
/// slightly increased line heights for better chat readability.
class DraculaText {
  DraculaText._();

  static const List<String> _fontFamilyFallback = <String>[
    'Inter',
    'SF Pro Text',
    'system-ui',
    'Roboto',
    'Tossface',
  ];

  static TextTheme buildTextTheme(TextTheme base) {
    TextStyle? adjust(
      TextStyle? style, {
        double? height,
        FontWeight? weight,
        double? letterSpacing,
      }) {
      if (style == null) return null;
      return style.copyWith(
        fontFamilyFallback: _fontFamilyFallback,
        height: height ?? style.height ?? 1.2,
        fontWeight: weight ?? style.fontWeight,
        letterSpacing: style.fontSize != null ? (letterSpacing ?? -0.01 * style.fontSize!) : style.letterSpacing,
      );
    }

    return base.copyWith(
      // Primary body text – used for messages.
      bodyLarge: adjust(
        base.bodyLarge,
        height: 1.5, // more breathing room for multi-line messages
      ),
      bodyMedium: adjust(
        base.bodyMedium,
        height: 1.5,
      ),
      bodySmall: adjust(
        base.bodySmall,
        height: 1.4,
      ),
      // Titles / usernames.
      titleLarge: adjust(
        base.titleLarge,
        weight: FontWeight.w600,
      ),
      titleMedium: adjust(
        base.titleMedium,
        weight: FontWeight.w600,
      ),
      titleSmall: adjust(
        base.titleSmall,
        weight: FontWeight.w600,
      ),
      // Metadata / captions.
      labelSmall: adjust(
        base.labelSmall,
        height: 1.2,
      ),
      labelMedium: adjust(
        base.labelMedium,
        height: 1.2,
      ),
    );
  }
}

