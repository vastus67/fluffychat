import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized brand-specific icons for Afterdamage Chat.
///
/// All icons are theme-aware — they inherit color from the current
/// [IconTheme] or accept an explicit [color] override.
class AfterdamageIcons {
  AfterdamageIcons._(); // non-instantiable

  static const String _basePath = 'assets/icons/afterdamage';

  /// Glagolitic Slovo (Ⱄ) icon used for the "New Chat" action.
  ///
  /// Returns an [SvgPicture] that respects `currentColor` via a
  /// [ColorFilter] derived from the ambient [IconTheme].
  static Widget newChat(
    BuildContext context, {
    double size = 20,
    Color? color,
  }) {
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      '$_basePath/glagolitic_slovo.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
