import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat/events/state_message.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/utils/account_config.dart';
import 'package:afterdamage/utils/color_value.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/mxc_image.dart';
import '../../config/app_config.dart';
import '../../widgets/settings_switch_list_tile.dart';
import 'settings_style.dart';

class SettingsStyleView extends StatelessWidget {
  final SettingsStyleController controller;

  const SettingsStyleView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const colorPickerSize = 32.0;
    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !FluffyThemes.isColumnMode(context),
        centerTitle: FluffyThemes.isColumnMode(context),
        title: Text(L10n.of(context).changeTheme),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: MaxWidthBody(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SegmentedButton<ThemeMode>(
                selected: {controller.currentTheme},
                onSelectionChanged: (selected) =>
                    controller.switchTheme(selected.single),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(L10n.of(context).lightTheme),
                    icon: const Icon(FontAwesomeIcons.sun),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(L10n.of(context).darkTheme),
                    icon: const Icon(FontAwesomeIcons.moon),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(L10n.of(context).systemTheme),
                    icon: const Icon(FontAwesomeIcons.circleHalfStroke),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                L10n.of(context).setColorTheme,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DynamicColorBuilder(
              builder: (light, dark) {
                final systemColor =
                    Theme.of(context).brightness == Brightness.light
                    ? light?.primary
                    : dark?.primary;
                final colors = List<Color?>.from(
                  SettingsStyleController.customColors,
                );
                if (systemColor == null) {
                  colors.remove(null);
                }
                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                  ),
                  itemCount: colors.length,
                  itemBuilder: (context, i) {
                    final color = colors[i];
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Tooltip(
                        message: color == null
                            ? L10n.of(context).systemTheme
                            : '#${color.hexValue.toRadixString(16).toUpperCase()}',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(colorPickerSize),
                          onTap: () => controller.setChatColor(color),
                          child: Material(
                            color: color ?? systemColor,
                            elevation: 6,
                            borderRadius: BorderRadius.circular(
                              colorPickerSize,
                            ),
                            child: SizedBox(
                              width: colorPickerSize,
                              height: colorPickerSize,
                              child: controller.currentColor == color
                                  ? Center(
                                      child: Icon(
                                        FontAwesomeIcons.check,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                'Dracula Accent Theme',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: DraculaAccent.values.map((accent) {
                  final isSelected = controller.currentDraculaAccent == accent;
                  return GestureDetector(
                    onTap: () => controller.setDraculaAccent(accent),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: accent.previewColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.previewColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            accent.displayName,
                            style: TextStyle(
                              color: theme.colorScheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            Icon(
                              FontAwesomeIcons.solidCircleCheck,
                              color: theme.colorScheme.surface,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                L10n.of(context).messagesStyle,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder(
              stream: client.onSync.stream.where(
                (syncUpdate) =>
                    syncUpdate.accountData?.any(
                      (accountData) =>
                          accountData.type ==
                          ApplicationAccountConfigExtension.accountDataKey,
                    ) ??
                    false,
              ),
              builder: (context, snapshot) {
                final accountConfig = client.applicationAccountConfig;

                return Column(
                  mainAxisSize: .min,
                  children: [
                    AnimatedContainer(
                      duration: FluffyThemes.animationDuration,
                      curve: FluffyThemes.animationCurve,
                      decoration: const BoxDecoration(),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (accountConfig.wallpaperUrl != null)
                            Opacity(
                              opacity: controller.wallpaperOpacity,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: controller.wallpaperBlur,
                                  sigmaY: controller.wallpaperBlur,
                                ),
                                child: MxcImage(
                                  key: ValueKey(accountConfig.wallpaperUrl),
                                  uri: accountConfig.wallpaperUrl,
                                  fit: BoxFit.cover,
                                  isThumbnail: true,
                                  width: FluffyThemes.columnWidth * 2,
                                  height: 212,
                                ),
                              ),
                            ),
                          Column(
                            mainAxisSize: .min,
                            children: [
                              const SizedBox(height: 16),
                              StateMessage(
                                Event(
                                  eventId: 'style_dummy',
                                  room: Room(
                                    id: '!style_dummy',
                                    client: client,
                                  ),
                                  content: {'membership': 'join'},
                                  type: EventTypes.RoomMember,
                                  senderId: client.userID!,
                                  originServerTs: DateTime.now(),
                                  stateKey: client.userID!,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 12 + 12 + Avatar.defaultSize,
                                  right: 12,
                                  top: accountConfig.wallpaperUrl == null
                                      ? 0
                                      : 12,
                                  bottom: 12,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.bubbleColor,
                                    borderRadius: BorderRadius.circular(
                                      AppConfig.borderRadius,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor',
                                      style: TextStyle(
                                        color: theme.onBubbleColor,
                                        fontSize:
                                            AppConfig.messageFontSize *
                                            AppSettings.fontSizeFactor.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: 12,
                                    left: 12,
                                    top: accountConfig.wallpaperUrl == null
                                        ? 0
                                        : 12,
                                    bottom: 12,
                                  ),
                                  child: Material(
                                    color:
                                        theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      AppConfig.borderRadius,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Lorem ipsum dolor sit amet',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize:
                                              AppConfig.messageFontSize *
                                              AppSettings.fontSizeFactor.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: theme.dividerColor),
                    ListTile(
                      title: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                        ),
                        onPressed: controller.setWallpaper,
                        icon: const Icon(FontAwesomeIcons.penToSquare),
                        label: Text(L10n.of(context).setWallpaper),
                      ),
                      trailing: accountConfig.wallpaperUrl == null
                          ? null
                          : IconButton(
                              icon: const Icon(FontAwesomeIcons.trash),
                              color: theme.colorScheme.error,
                              onPressed: controller.deleteChatWallpaper,
                            ),
                    ),
                    if (accountConfig.wallpaperUrl != null) ...[
                      ListTile(title: Text(L10n.of(context).opacity)),
                      Slider.adaptive(
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        semanticFormatterCallback: (d) => d.toString(),
                        value: controller.wallpaperOpacity,
                        onChanged: controller.updateWallpaperOpacity,
                        onChangeEnd: controller.saveWallpaperOpacity,
                      ),
                      ListTile(title: Text(L10n.of(context).blur)),
                      Slider.adaptive(
                        min: 0.0,
                        max: 10.0,
                        divisions: 10,
                        semanticFormatterCallback: (d) => d.toString(),
                        value: controller.wallpaperBlur,
                        onChanged: controller.updateWallpaperBlur,
                        onChangeEnd: controller.saveWallpaperBlur,
                      ),
                    ],
                  ],
                );
              },
            ),
            ListTile(
              title: Text(L10n.of(context).fontSize),
              trailing: Text('Ã— ${AppSettings.fontSizeFactor.value}'),
            ),
            Slider.adaptive(
              min: 0.5,
              max: 2.5,
              divisions: 20,
              value: AppSettings.fontSizeFactor.value,
              semanticFormatterCallback: (d) => d.toString(),
              onChanged: controller.changeFontSizeFactor,
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                L10n.of(context).overview,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsSwitchListTile.adaptive(
              title: L10n.of(context).presencesToggle,
              setting: AppSettings.showPresences,
            ),
            SettingsSwitchListTile.adaptive(
              title: L10n.of(context).displayNavigationRail,
              setting: AppSettings.displayNavigationRail,
            ),
          ],
        ),
      ),
    );
  }
}
