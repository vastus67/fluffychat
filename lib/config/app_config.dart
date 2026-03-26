import 'dart:ui';

abstract class AppConfig {
  // Const and final configuration values (immutable)
  static const Color primaryColor = Color(0xFF5625BA);
  static const Color primaryColorLight = Color(0xFFCCBDEA);
  static const Color secondaryColor = Color(0xFF41a2bc);

  static const Color chatColor = primaryColor;
  static const double messageFontSize = 16.0;
  static const bool allowOtherHomeservers = true;
  static const bool enableRegistration = true;
  static const bool hideTypingUsernames = false;

  static const String inviteLinkPrefix = 'https://matrix.to/#/';
  static const String deepLinkPrefix = 'im.fluffychat://chat/';
  static const String appSsoUrlScheme = 'im.fluffychat.auth';
  static const String schemePrefix = 'matrix:';
  static const String pushNotificationsChannelId = 'fluffychat_push';
  static const String pushNotificationsAppId = 'chat.fluffy.fluffychat';
  static const double borderRadius = 8.0;
  static const double spaceBorderRadius = 11.0;
  static const double columnWidth = 360.0;

  static const String website = 'https://matrix.org';
  static const String enablePushTutorial =
      'https://matrix.org/docs/';
  static const String encryptionTutorial =
      'https://matrix.org/docs/guides/end-to-end-encryption';
  static const String startChatTutorial =
      'https://joinmatrix.org/';
  static const String howDoIGetStickersTutorial =
      'https://matrix.org/docs/';
  static const String appId = 'im.fluffychat.FluffyChat';
  static const String appOpenUrlScheme = 'im.fluffychat';

  static const String sourceCodeUrl =
      'https://github.com/krille-chan/fluffychat';
  static const String supportUrl =
      'https://matrix.org/support';
  static const String changelogUrl = 'https://matrix.org';
  static const String donationUrl = '';

  static const Set<String> defaultReactions = {'👍', '❤️', '😂', '😮', '😢'};

  static final Uri newIssueUrl = Uri(
    scheme: 'https',
    host: 'github.com',
    path: '/krille-chan/fluffychat/issues/new',
  );

  static final Uri homeserverList = Uri(
    scheme: 'https',
    host: 'servers.joinmatrix.org',
    path: 'servers.json',
  );

  /// Curated list of well-known public homeservers shown by default
  /// in the server picker when the remote list is unavailable or as
  /// a base set for local filtering.
  static const List<Map<String, String>> knownHomeservers = [
    {'name': 'matrix.org', 'description': 'The original Matrix homeserver, run by the Matrix.org Foundation'},
    {'name': 'envs.net', 'description': 'Community-run server hosted in Germany'},
    {'name': 'tchncs.de', 'description': 'Privacy-focused server based in Germany'},
    {'name': 'nitro.chat', 'description': 'Fast and reliable community server'},
    {'name': 'matrix.im', 'description': 'General-purpose Matrix server'},
    {'name': 'converser.eu', 'description': 'European-hosted Matrix server'},
    {'name': 'kde.org', 'description': 'KDE community Matrix server'},
    {'name': 'mozilla.org', 'description': 'Mozilla community Matrix server'},
    {'name': 'gitter.im', 'description': 'Developer community Matrix server'},
    {'name': 'halogen.city', 'description': 'Community-run Matrix server'},
    {'name': 'catgirl.cloud', 'description': 'Fun community Matrix homeserver'},
    {'name': 'matrix.what-the-fock.de', 'description': 'German community server'},
    {'name': 'aguiarvieira.pt', 'description': 'Portuguese community server'},
  ];

  static final Uri privacyUrl = Uri(
    scheme: 'https',
    host: 'matrix.org',
    path: '/legal/privacy-notice',
  );

  static const String mainIsolatePortName = 'main_isolate';
  static const String pushIsolatePortName = 'push_isolate';
}
