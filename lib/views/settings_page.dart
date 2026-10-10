import 'dart:io';

import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/controller/autofill/autofill_controller.dart';
import 'package:bimir_lock/controller/backup/backup_controller.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/modules/settings_ui/settings_ui.dart';
import 'package:bimir_lock/ui/autofill_guide.dart';
import 'package:bimir_lock/ui/coach_marks.dart';
import 'package:bimir_lock/ui/forgot_pin.dart';
import 'package:bimir_lock/ui/photo_preview.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/unlock.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/constants.dart';
import 'package:bimir_lock/utils/helper/app_permissions.dart';
import 'package:bimir_lock/utils/helper/biometric_helper.dart';
import 'package:bimir_lock/utils/helper/app_reset.dart';
import 'package:bimir_lock/utils/helper/feedback.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:bimir_lock/views/faq/faq_page.dart';
import 'package:bimir_lock/views/intruder_page.dart';
import 'package:bimir_lock/views/pin/change_access_pin.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:bimir_lock/views/user/add_user_detail.dart';
import 'package:bimir_lock/views/quotes_page.dart';
import 'package:bimir_lock/widgets/user_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  static const String routeName = "/settings";
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final CoreController cc = Get.find<CoreController>();
  final AutofillController ac = Get.find<AutofillController>();
  final BiometricController bc = Get.find<BiometricController>();
  final BackupController backup = BackupController();

  bool get _hasPin => cc.encryptedPassword != null;

  /// Set before PINs went to 6 digits.
  bool get _shortPin => (cc.encryptedPassword?.length ?? pinLength) < pinLength;

  bool _photoOn = false;

  @override
  void initState() {
    super.initState();
    _loadIntruder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachMarks.showOnce(
        context,
        tourId: CoachTours.settings,
        steps: const [
          CoachStep(
            targetId: 'settings.profile',
            circle: true,
            title: 'Your profile',
            body: 'Tap the pencil to change your name or photo.',
          ),
          CoachStep(
            targetId: 'settings.security',
            title: 'Security',
            body:
                'Change your PIN, and open passwords with Face ID or fingerprint instead.',
          ),
          CoachStep(
            targetId: 'settings.backup',
            title: 'Back up your vault',
            body:
                'Save an encrypted copy to Files or Drive. Phones get lost; a backup is how your passwords survive that.',
          ),
          CoachStep(
            targetId: 'settings.tips',
            title: 'Tips again',
            body: 'Missed something? Bring these tips back from here.',
          ),
        ],
      );
    });
  }

  Future<void> _pin() async {
    await navigatorKey.currentState!.pushNamed(
      _hasPin ? ChangeAccessPinPage.routeName : SetAccessPinPage.routeName,
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadIntruder() async {
    await IntruderWatch.refresh();
    final bool on = await IntruderWatch.isEnabled();
    if (mounted) setState(() => _photoOn = on);
  }

  Future<void> _intruders() async {
    // Behind the PIN, so whoever was guessing cannot delete their own photo
    // or switch the camera off before trying again.
    final bool ok = await confirmIdentity(
      context,
      title: 'Wrong PIN alerts',
      message: 'Confirm it is you.',
    );
    if (!ok) return;
    await navigatorKey.currentState!.pushNamed(IntruderPage.routeName);
    await _loadIntruder();
  }

  /// Debug builds only. Erases everything and starts first-run setup again.
  Future<void> _resetApp() async {
    final bool sure = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Reset the app?',
      message:
          'Every password, note, your profile, PIN, settings and wrong PIN alerts on this phone are deleted, and setup starts again. This cannot be undone.',
      confirmText: 'Erase everything',
      dialogType: DialogType.danger,
      icon: Icons.restart_alt_rounded,
    );
    if (!sure) return;
    if (!await AppReset.wipeAndRestart()) {
      showNote("Couldn't reset everything. Please try again.");
    }
  }

  Future<void> _open(Uri url, {bool inApp = false}) async {
    try {
      final bool ok = await launchUrl(
        url,
        mode: inApp
            ? LaunchMode.inAppBrowserView
            : LaunchMode.externalApplication,
      );
      if (!ok) showNote("Couldn't open the link.");
    } catch (_) {
      showNote("Couldn't open the link.");
    }
  }

  /// Why fingerprint / face unlock cannot be switched on here, and the way
  /// to fix it where there is one.
  Future<void> _explainBiometric(BiometricState why) async {
    final String how = bc.label.value;
    switch (why) {
      case BiometricState.ready:
        return;
      case BiometricState.notEnrolled:
        final bool open = await DialogUtils.showConfirmationDialog(
          context,
          title: 'Set up $how first',
          message:
              'Bimir Lock can open with your $how once it is set up on this phone. Add it in the phone\'s settings, then come back and switch this on. Your PIN keeps working either way.',
          confirmText: 'Open Settings',
          cancelText: 'Not now',
          icon: _isFace(how)
              ? LucideIcons.scanFace
              : LucideIcons.fingerprintPattern,
        );
        if (open) await AppPermissions.openSecurity();
      case BiometricState.blocked:
        await AppPermissions.offerSettings(
          context,
          title: '$how is off for Bimir Lock',
          message:
              'Allow $how for Bimir Lock in your phone\'s settings (or set it up under Face ID & Passcode), then come back and switch this on. Your PIN keeps working either way.',
          icon: _isFace(how)
              ? LucideIcons.scanFace
              : LucideIcons.fingerprintPattern,
        );
      case BiometricState.noHardware:
        await DialogUtils.showInformationDialog(
          context,
          title: 'No fingerprint or face unlock',
          message:
              'This phone cannot unlock with a fingerprint or a face, so your PIN opens everything. A forgotten PIN cannot be reset here: keep a backup file (Settings › Backup) somewhere safe.',
          icon: LucideIcons.keyRound,
        );
    }
    await bc.refreshStatus();
  }

  bool _isFace(String label) => label.toLowerCase().contains('face');

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        top: false,
        child: ListView(
          children: [
            const SizedBox(height: Space.lg),
            Center(
              child: CoachTarget(
                id: 'settings.profile',
                child: _EditableAvatar(
                  cc: cc,
                  onEdit: () => navigatorKey.currentState!.pushNamed(
                    AddUserDetailPage.routeName,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            Obx(
              () => Text(
                cc.currentUser.value?.userName?.trim().isNotEmpty == true
                    ? cc.currentUser.value!.userName!.trim()
                    : 'You',
                style: t.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            // For as long as AutoFill is off on a phone that has it: the
            // feature people most often never find. Re-read on every resume.
            Obx(
              () => ac.available && !ac.on
                  ? Padding(
                      padding: const EdgeInsets.only(top: Space.xl),
                      child: Notice(
                        tone: Tone.secure,
                        icon: LucideIcons.textCursorInput,
                        title: 'AutoFill is off',
                        message:
                            'Turn it on to fill your saved passwords in other apps.',
                        action: TextButton(
                          onPressed: () => offerAutofill(context),
                          child: const Text('Turn on'),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: Space.xxl),
            const SettingsSectionHeader(label: 'Appearance'),
            const SettingsThemePicker(),
            const SizedBox(height: Space.xl),
            CoachTarget(
              id: 'settings.security',
              child: Obx(
                () => RowGroup(
                  title: 'Security',
                  children: [
                    SettingRow(
                      icon: LucideIcons.rectangleEllipsis,
                      title: _hasPin
                          ? 'Change access PIN'
                          : 'Set an access PIN',
                      subtitle: !_hasPin
                          ? 'Needed before passwords can be opened'
                          : _shortPin
                          ? 'Yours has ${cc.encryptedPassword!.length} digits. A $pinLength-digit PIN is far harder to guess.'
                          : 'Opens every password',
                      onTap: _pin,
                    ),
                    if (_hasPin)
                      SettingRow(
                        icon: LucideIcons.keyRound,
                        title: 'Forgot PIN?',
                        subtitle: bc.canUse
                            ? 'Reset it with ${bc.label.value}'
                            : bc.state.value == BiometricState.noHardware
                            ? "Can't be reset on this phone. Keep a backup file."
                            : 'Needs ${bc.label.value} unlock to be on',
                        onTap: () async {
                          await forgotPin(context);
                          if (mounted) setState(() {});
                        },
                      ),
                    ValueListenableBuilder<int>(
                      valueListenable: IntruderWatch.unseen,
                      builder: (BuildContext context, int unseen, _) =>
                          SettingRow(
                            icon: LucideIcons.shieldAlert,
                            title: 'Wrong PIN alerts',
                            subtitle: _photoOn
                                ? 'Photo when wrong PINs lock the keypad is on'
                                : 'Photograph whoever keeps entering wrong PINs',
                            trailing: unseen == 0
                                ? null
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Space.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.danger,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$unseen new',
                                      style: t.labelSmall?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onError,
                                      ),
                                    ),
                                  ),
                            onTap: _intruders,
                          ),
                    ),
                    SettingRow(
                      icon: _isFace(bc.label.value)
                          ? LucideIcons.scanFace
                          : LucideIcons.fingerprintPattern,
                      title: bc.state.value == BiometricState.noHardware
                          ? 'Fingerprint or face unlock'
                          : 'Unlock with ${bc.label.value}',
                      subtitle: switch (bc.state.value) {
                        BiometricState.ready => 'Instead of typing the PIN',
                        BiometricState.notEnrolled =>
                          'Set up ${bc.label.value} on this phone first',
                        BiometricState.blocked =>
                          '${bc.label.value} is off for Bimir Lock',
                        BiometricState.noHardware =>
                          'Not on this phone. Your PIN opens everything.',
                      },
                      // What to do about it, when it cannot simply be
                      // switched on.
                      onTap: bc.state.value == BiometricState.ready
                          ? null
                          : () => _explainBiometric(bc.state.value),
                      trailing: Switch(
                        value: bc.isEnabled.value,
                        // Nothing to switch on a phone that has neither.
                        onChanged: bc.state.value == BiometricState.noHardware
                            ? null
                            : (bool v) => bc.toggle(
                                v,
                                confirmPin: () => confirmIdentity(
                                  context,
                                  title: 'Confirm your PIN',
                                  message:
                                      'To turn on ${bc.label.value} unlock.',
                                  allowBiometric: false,
                                ),
                                onUnavailable: _explainBiometric,
                              ),
                      ),
                    ),
                    // iPhone / iPad: the switch is in the phone's settings, so
                    // this row says whether it is on and how to get there.
                    if (Platform.isIOS)
                      SettingRow(
                        icon: LucideIcons.textCursorInput,
                        title: 'AutoFill',
                        subtitle: ac.iosEnabled.value
                            ? 'On. Fills passwords in Safari and other apps'
                            : 'Off. Tap to see how to turn it on',
                        onTap: () => offerAutofill(context),
                      ),
                    // Left out where the OS has no autofill framework for us.
                    if (ac.isSupported.value)
                      SettingRow(
                        icon: LucideIcons.textCursorInput,
                        title: 'Autofill',
                        subtitle: 'Fill and save passwords in other apps',
                        trailing: Switch(
                          value: ac.isEnabled.value,
                          onChanged: ac.toggleAutofill,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            CoachTarget(
              id: 'settings.backup',
              child: RowGroup(
                title: 'Backup',
                children: [
                  SettingRow(
                    icon: LucideIcons.fileUp,
                    title: 'Back up to a file',
                    subtitle: 'Encrypted with a backup password you choose',
                    onTap: backup.backUp,
                  ),
                  SettingRow(
                    icon: LucideIcons.fileDown,
                    title: 'Restore from a file',
                    subtitle: 'Adds what is missing; never deletes anything',
                    onTap: backup.restore,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            RowGroup(
              title: 'Quotes',
              children: [
                SettingRow(
                  icon: LucideIcons.quote,
                  title: 'Recently seen quotes',
                  subtitle: 'The ones shown when Bimir Lock opens',
                  onTap: () =>
                      Navigator.of(context).pushNamed(QuotesPage.routeName),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            CoachTarget(
              id: 'settings.tips',
              child: RowGroup(
                title: 'Help',
                children: [
                  SettingRow(
                    icon: LucideIcons.circleQuestionMark,
                    title: 'FAQ',
                    subtitle: 'Search any question about Bimir Lock',
                    onTap: () =>
                        Navigator.of(context).pushNamed(FaqPage.routeName),
                  ),
                  SettingRow(
                    icon: LucideIcons.messageSquareWarning,
                    title: 'Report a problem',
                    subtitle: 'Email the developer. Never include a password.',
                    onTap: () async {
                      if (!await AppFeedback.reportProblem()) {
                        showNote(
                          'No email app found. Write to ${ContactLink.email}',
                        );
                      }
                    },
                  ),
                  SettingRow(
                    icon: LucideIcons.star,
                    title: 'Rate Bimir Lock',
                    subtitle: Platform.isIOS
                        ? 'On the App Store'
                        : 'On Google Play',
                    trailing: Icon(
                      LucideIcons.externalLink,
                      size: 18,
                      color: p.muted,
                    ),
                    onTap: () async {
                      if (!await AppFeedback.openStorePage()) {
                        showNote("Couldn't open the store.");
                      }
                    },
                  ),
                  SettingRow(
                    icon: LucideIcons.lightbulb,
                    title: 'Show tips again',
                    subtitle: 'The first-time tips on each screen',
                    onTap: () async {
                      await CoachMarks.resetAll();
                      showNote('Tips will show again as you use the app.');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            RowGroup(
              title: 'Legal',
              children: [
                SettingRow(
                  icon: LucideIcons.shield,
                  title: 'Privacy policy',
                  trailing: Icon(
                    LucideIcons.externalLink,
                    size: 18,
                    color: p.muted,
                  ),
                  onTap: () =>
                      _open(Uri.parse(LegalLink.privacyPolicy), inApp: true),
                ),
                SettingRow(
                  icon: LucideIcons.scale,
                  title: 'Terms and conditions',
                  trailing: Icon(
                    LucideIcons.externalLink,
                    size: 18,
                    color: p.muted,
                  ),
                  onTap: () => _open(Uri.parse(LegalLink.terms), inApp: true),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: Space.xl),
              RowGroup(
                title: 'Debug',
                children: [
                  SettingRow(
                    icon: LucideIcons.rotateCcw,
                    title: 'Reset app',
                    subtitle:
                        'Debug builds only. Erases everything on this phone and starts setup again.',
                    danger: true,
                    onTap: _resetApp,
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.xl),
            Padding(
              padding: const EdgeInsets.only(left: Space.xs, bottom: Space.sm),
              child: Eyebrow('Developer'),
            ),
            Panel(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bimal Khatri', style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Bimir Lock is designed and built by one developer in Pokhara, Nepal. Questions and ideas are welcome.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: Space.lg),
                  // Full size always; on a narrow phone the last ones move
                  // to a second line.
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final (FaIconData icon, String label, Uri url)
                          in <(FaIconData, String, Uri)>[
                            (
                              FontAwesomeIcons.globe,
                              'Website',
                              Uri.parse(ContactLink.websiteLink),
                            ),
                            (
                              FontAwesomeIcons.github,
                              'GitHub',
                              Uri.parse(ContactLink.githubLink),
                            ),
                            (
                              FontAwesomeIcons.linkedinIn,
                              'LinkedIn',
                              Uri.parse(ContactLink.linkedinLink),
                            ),
                            (
                              FontAwesomeIcons.youtube,
                              'YouTube',
                              Uri.parse(ContactLink.youtubeLink),
                            ),
                            (
                              FontAwesomeIcons.instagram,
                              'Instagram',
                              Uri.parse(ContactLink.instagramLink),
                            ),
                            (
                              FontAwesomeIcons.facebookF,
                              'Facebook',
                              Uri.parse(ContactLink.facebookLink),
                            ),
                            (
                              FontAwesomeIcons.envelope,
                              'Email',
                              Uri(
                                scheme: 'mailto',
                                path: ContactLink.email,
                                query: 'subject=Bimir%20Lock',
                              ),
                            ),
                          ])
                        _BrandButton(
                          icon: icon,
                          label: label,
                          onTap: () => _open(url),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

/// The profile photo, round, with a pencil badge. The photo opens large (as
/// in the Callbreak Tracker app); the pencil opens Edit profile. With no
/// photo yet, the circle opens Edit profile too.
class _EditableAvatar extends StatefulWidget {
  const _EditableAvatar({required this.cc, required this.onEdit});

  final CoreController cc;
  final VoidCallback onEdit;

  @override
  State<_EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<_EditableAvatar> {
  final GlobalKey _circle = GlobalKey();

  void _open() {
    final File? photo = widget.cc.avatarFile.value;
    if (photo == null) return widget.onEdit();
    final String name = widget.cc.currentUser.value?.userName?.trim() ?? '';
    showPhotoPreview(
      context,
      file: photo,
      name: name.isEmpty ? null : name,
      from: _circle.currentContext == null
          ? null
          : photoRect(_circle.currentContext!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Obx(
          () => Semantics(
            button: true,
            label: widget.cc.avatarFile.value == null
                ? 'Edit profile'
                : 'Show profile photo',
            child: Material(
              key: _circle,
              shape: CircleBorder(side: BorderSide(color: p.primary)),
              color: p.surfaceMuted,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _open,
                child: SizedBox.square(
                  dimension: 96,
                  child: UserAvatar(
                    file: widget.cc.avatarFile.value,
                    iconSize: 48,
                    iconColor: p.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Semantics(
            button: true,
            label: 'Edit profile',
            child: Material(
              color: p.fill,
              shape: CircleBorder(
                side: BorderSide(color: p.background, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onEdit,
                child: SizedBox.square(
                  dimension: 34,
                  child: Icon(LucideIcons.pencil, size: 16, color: p.onFill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandButton extends StatelessWidget {
  const _BrandButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: p.surfaceMuted,
          shape: CircleBorder(side: BorderSide(color: p.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 46,
              child: Center(child: FaIcon(icon, size: 18, color: p.foreground)),
            ),
          ),
        ),
      ),
    );
  }
}
