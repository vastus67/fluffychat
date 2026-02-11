import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat_details/chat_details.dart';
import 'package:afterdamage/pages/chat_details/participant_list_item.dart';
import 'package:afterdamage/utils/fluffy_share.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/chat_settings_popup_menu.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:afterdamage/widgets/matrix.dart';
import '../../utils/url_launcher.dart';
import '../../widgets/mxc_image_viewer.dart';
import '../../widgets/qr_code_viewer.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatDetailsController controller;

  const ChatDetailsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final room = Matrix.of(context).client.getRoomById(controller.roomId!);
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).oopsSomethingWentWrong)),
        body: Center(
          child: Text(L10n.of(context).youAreNoLongerParticipatingInThisChat),
        ),
      );
    }

    final directChatMatrixID = room.directChatMatrixID;
    final roomAvatar = room.avatar;

    return StreamBuilder(
      stream: room.client.onRoomState.stream.where(
        (update) => update.roomId == room.id,
      ),
      builder: (context, snapshot) {
        var members = room.getParticipants().toList()
          ..sort((b, a) => a.powerLevel.compareTo(b.powerLevel));
        members = members.take(10).toList();
        final actualMembersCount =
            (room.summary.mInvitedMemberCount ?? 0) +
            (room.summary.mJoinedMemberCount ?? 0);
        final canRequestMoreMembers = members.length < actualMembersCount;
        final iconColor = theme.textTheme.bodyLarge!.color;
        final displayname = room.getLocalizedDisplayname(
          MatrixLocals(L10n.of(context)),
        );
        return Scaffold(
          appBar: AppBar(
            leading:
                controller.widget.embeddedCloseButton ??
                const Center(child: BackButton()),
            elevation: theme.appBarTheme.elevation,
            actions: <Widget>[
              if (room.canonicalAlias.isNotEmpty)
                IconButton(
                  tooltip: L10n.of(context).share,
                  icon: const Icon(FontAwesomeIcons.qrcode),
                  onPressed: () =>
                      showQrCodeViewer(context, room.canonicalAlias),
                )
              else if (directChatMatrixID != null)
                IconButton(
                  tooltip: L10n.of(context).share,
                  icon: const Icon(FontAwesomeIcons.qrcode),
                  onPressed: () =>
                      showQrCodeViewer(context, directChatMatrixID),
                ),
              if (controller.widget.embeddedCloseButton == null)
                ChatSettingsPopupMenu(room, false),
            ],
            title: Text(L10n.of(context).chatDetails),
            backgroundColor: theme.appBarTheme.backgroundColor,
          ),
          body: MaxWidthBody(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: members.length + 1 + (canRequestMoreMembers ? 1 : 0),
              itemBuilder: (BuildContext context, int i) => i == 0
                  ? Column(
                      crossAxisAlignment: .stretch,
                      children: <Widget>[
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Stack(
                                children: [
                                  Hero(
                                    tag:
                                        controller.widget.embeddedCloseButton !=
                                            null
                                        ? 'embedded_content_banner'
                                        : 'content_banner',
                                    child: Avatar(
                                      mxContent: room.avatar,
                                      name: displayname,
                                      size: Avatar.defaultSize * 2.5,
                                      onTap: roomAvatar != null
                                          ? () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  MxcImageViewer(roomAvatar),
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (!room.isDirectChat &&
                                      room.canChangeStateEvent(
                                        EventTypes.RoomAvatar,
                                      ))
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: FloatingActionButton.small(
                                        onPressed: controller.setAvatarAction,
                                        heroTag: null,
                                        child: const Icon(
                                          FontAwesomeIcons.camera,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: .center,
                                crossAxisAlignment: .start,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => room.isDirectChat
                                        ? null
                                        : room.canChangeStateEvent(
                                            EventTypes.RoomName,
                                          )
                                        ? controller.setDisplaynameAction()
                                        : FluffyShare.share(
                                            displayname,
                                            context,
                                            copyOnly: true,
                                          ),
                                    icon: Icon(
                                      room.isDirectChat
                                          ? FontAwesomeIcons.comment
                                          : room.canChangeStateEvent(
                                              EventTypes.RoomName,
                                            )
                                          ? FontAwesomeIcons.penToSquare
                                          : FontAwesomeIcons.copy,
                                      size: 16,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.onSurface,
                                      iconColor: theme.colorScheme.onSurface,
                                    ),
                                    label: Text(
                                      room.isDirectChat
                                          ? L10n.of(context).directChat
                                          : displayname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => room.isDirectChat
                                        ? null
                                        : context.push(
                                            '/rooms/${controller.roomId}/details/members',
                                          ),
                                    icon: const Icon(
                                      FontAwesomeIcons.users,
                                      size: 14,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.secondary,
                                      iconColor: theme.colorScheme.secondary,
                                    ),
                                    label: Text(
                                      L10n.of(
                                        context,
                                      ).countParticipants(actualMembersCount),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      //    style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (room.canChangeStateEvent(EventTypes.RoomTopic) ||
                            room.topic.isNotEmpty) ...[
                          Divider(color: theme.dividerColor),
                          ListTile(
                            title: Text(
                              L10n.of(context).chatDescription,
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing:
                                room.canChangeStateEvent(EventTypes.RoomTopic)
                                ? IconButton(
                                    onPressed: controller.setTopicAction,
                                    tooltip: L10n.of(
                                      context,
                                    ).setChatDescription,
                                    icon: const Icon(FontAwesomeIcons.penToSquare),
                                  )
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: SelectableLinkify(
                              text: room.topic.isEmpty
                                  ? L10n.of(context).noChatDescriptionYet
                                  : room.topic,
                              textScaleFactor: MediaQuery.textScalerOf(
                                context,
                              ).scale(1),
                              options: const LinkifyOptions(humanize: false),
                              linkStyle: const TextStyle(
                                color: Colors.blueAccent,
                                decorationColor: Colors.blueAccent,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: room.topic.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: theme.textTheme.bodyMedium!.color,
                                decorationColor:
                                    theme.textTheme.bodyMedium!.color,
                              ),
                              onOpen: (url) =>
                                  UrlLauncher(context, url.url).launchUrl(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (!room.isDirectChat) ...[
                          Divider(color: theme.dividerColor),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.surfaceContainer,
                              foregroundColor: iconColor,
                              child: const Icon(
                                FontAwesomeIcons.userShield,
                              ),
                            ),
                            title: Text(L10n.of(context).accessAndVisibility),
                            subtitle: Text(
                              L10n.of(context).accessAndVisibilityDescription,
                            ),
                            onTap: () => context.push(
                              '/rooms/${room.id}/details/access',
                            ),
                            trailing: const Icon(FontAwesomeIcons.chevronRight),
                          ),
                          ListTile(
                            title: Text(L10n.of(context).chatPermissions),
                            subtitle: Text(
                              L10n.of(context).whoCanPerformWhichAction,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.surfaceContainer,
                              foregroundColor: iconColor,
                              child: const Icon(FontAwesomeIcons.sliders),
                            ),
                            trailing: const Icon(FontAwesomeIcons.chevronRight),
                            onTap: () => context.push(
                              '/rooms/${room.id}/details/permissions',
                            ),
                          ),
                        ],
                        Divider(color: theme.dividerColor),
                        ListTile(
                          title: Text(
                            L10n.of(
                              context,
                            ).countParticipants(actualMembersCount),
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!room.isDirectChat && room.canInvite)
                          ListTile(
                            title: Text(L10n.of(context).inviteContact),
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              radius: Avatar.defaultSize / 2,
                              child: const Icon(FontAwesomeIcons.plus),
                            ),
                            trailing: const Icon(FontAwesomeIcons.chevronRight),
                            onTap: () => context.go('/rooms/${room.id}/invite'),
                          ),
                      ],
                    )
                  : i < members.length + 1
                  ? ParticipantListItem(members[i - 1])
                  : ListTile(
                      title: Text(
                        L10n.of(context).loadCountMoreParticipants(
                          (actualMembersCount - members.length),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        child: const Icon(
                          FontAwesomeIcons.users,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () => context.push(
                        '/rooms/${controller.roomId!}/details/members',
                      ),
                      trailing: const Icon(FontAwesomeIcons.chevronRight),
                    ),
            ),
          ),
        );
      },
    );
  }
}
