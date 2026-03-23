import 'package:flutter/material.dart';

/// Curated muted palette matching Dracula / Afterdamage aesthetic.
/// 20 hand-picked colors: deep burgundy, plum, slate, muted teal,
/// dusty olive, smoked amber, charcoal-tinted hues — no neon.
const List<Color> afterdamageAvatarPalette = [
  Color(0xFF6D2B3A), // deep burgundy
  Color(0xFF7B3F5E), // plum
  Color(0xFF4A3B5C), // dark violet
  Color(0xFF5B4A6E), // muted purple
  Color(0xFF3D4F6A), // slate blue
  Color(0xFF2C5F6E), // deep teal
  Color(0xFF3A6B5E), // muted teal
  Color(0xFF4E6B4A), // dusty olive
  Color(0xFF5C6644), // sage
  Color(0xFF7A6A3A), // smoked amber
  Color(0xFF8B5E3C), // warm brown
  Color(0xFF6B4F3D), // cocoa
  Color(0xFF5A3E3E), // rosewood
  Color(0xFF4B4453), // charcoal plum
  Color(0xFF3E4E4E), // dark slate
  Color(0xFF556B6B), // muted cyan-grey
  Color(0xFF6E5A6E), // mauve grey
  Color(0xFF5C4B4B), // smoky rose
  Color(0xFF3F5A5A), // deep sea
  Color(0xFF7A5C5C), // dusty rose
];

/// Stable FNV-1a–style 32-bit hash for deterministic palette selection.
/// No randomness, no runtime seed — identical output for identical input.
int _stableStringHash(String s) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    hash ^= s.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Returns [Colors.white] or [Colors.black] depending on which gives
/// better contrast against [bg].  Uses WCAG relative luminance.
Color contrastForeground(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.4 ? Colors.black : Colors.white;
}

extension StringColor on String {
  // ── Legacy HSL-based helpers (used for sender-name text colors) ──

  static final _colorCache = <String, Map<double, Color>>{};

  Color _getColorLight(double light) {
    var number = 0.0;
    for (var i = 0; i < length; i++) {
      number += codeUnitAt(i);
    }
    number = (number % 12) * 25.5;
    return HSLColor.fromAHSL(0.75, number, 1, light).toColor();
  }

  /// Saturated colour for sender names in light mode.
  Color get color {
    _colorCache[this] ??= {};
    return _colorCache[this]![0.3] ??= _getColorLight(0.3);
  }

  /// Darker variant used in space view.
  Color get darkColor {
    _colorCache[this] ??= {};
    return _colorCache[this]![0.2] ??= _getColorLight(0.2);
  }

  /// Lighter variant used for sender names in dark mode.
  Color get lightColorText {
    _colorCache[this] ??= {};
    return _colorCache[this]![0.7] ??= _getColorLight(0.7);
  }

  // ── New palette-based avatar background ──

  static final _avatarColorCache = <String, Color>{};

  /// Deterministic muted background color for fallback letter avatars.
  Color get avatarBackground {
    return _avatarColorCache[this] ??= afterdamageAvatarPalette[
        _stableStringHash(this).abs() % afterdamageAvatarPalette.length];
  }

  /// Auto-contrast foreground (white or black) for [avatarBackground].
  Color get avatarForeground => contrastForeground(avatarBackground);
}
