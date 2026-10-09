import 'package:bimir_lock/controller/user/add_user_controller.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/validators.dart';
import 'package:bimir_lock/widgets/user_avatar.dart';
import 'package:bimir_lock/utils/helper/app_permissions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Your name and, optionally, a photo. On first run this is
/// step 1 of 2; afterwards it is the Profile screen.
class AddUserDetailPage extends StatefulWidget {
  static const String routeName = "/addUserDetail";

  const AddUserDetailPage({super.key});

  @override
  State<AddUserDetailPage> createState() => _AddUserDetailPageState();
}

class _AddUserDetailPageState extends State<AddUserDetailPage> {
  final AddUserDetailController c = Get.put(AddUserDetailController());

  @override
  void dispose() {
    Get.delete<AddUserDetailController>();
    super.dispose();
  }

  Future<void> _photoOptions() async {
    final bool hasPhoto = c.userAvatar != null;
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Choose from library'),
                onTap: () => Navigator.pop(sheet, ImageSource.gallery),
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(
                    LucideIcons.trash2,
                    color: BimirPalette.of(sheet).danger,
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(color: BimirPalette.of(sheet).danger),
                  ),
                  onTap: () {
                    c.removeImage();
                    Navigator.pop(sheet);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    // The library needs no permission (the system picker hands over only the
    // photo chosen); the camera does, and a "never" needs the way to Settings.
    if (source == ImageSource.camera &&
        !await AppPermissions.camera(context, why: 'Taking a profile photo needs the camera.')) {
      return;
    }
    await c.pickImage(source);
  }

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;
    final bool firstRun = c.isFirstRun;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(firstRun ? '' : 'Profile')),
        body: PageBody(
          top: false,
          maxWidth: Space.maxNarrow + Space.gutter * 2,
          child: Form(
            key: c.formKey,
            child: ListView(
              children: [
                if (firstRun) ...[
                  Text(
                    'STEP 1 OF 2',
                    style: BimirPalette.figure(context, color: p.primary),
                  ),
                  const SizedBox(height: Space.sm),
                  Text('About you', style: t.headlineMedium),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Your name and, if you like, a photo. They stay on this phone and are only used to greet you.',
                    style: t.bodyLarge?.copyWith(color: p.muted),
                  ),
                  const SizedBox(height: Space.xl),
                ] else
                  const SizedBox(height: Space.lg),
                Center(
                  child: GetBuilder<AddUserDetailController>(
                    builder: (_) => _AvatarPicker(
                      avatar: UserAvatar(
                        file: c.userAvatar,
                        iconColor: p.muted,
                      ),
                      hasPhoto: c.userAvatar != null,
                      onTap: _photoOptions,
                    ),
                  ),
                ),
                const SizedBox(height: Space.xl),
                TextFormField(
                  controller: c.userNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: Validators.checkFieldEmpty,
                ),
                const SizedBox(height: Space.lg),
                const SizedBox(height: Space.xxl),
                Obx(
                  () => FilledButton(
                    onPressed: c.isLoading.value
                        ? null
                        : () => c.onSaveUserDetail(context),
                    child: c.isLoading.value
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(firstRun ? 'Continue' : 'Save'),
                  ),
                ),
                const SizedBox(height: Space.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatar,
    required this.hasPhoto,
    required this.onTap,
  });

  final Widget avatar;
  final bool hasPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    return Semantics(
      button: true,
      label: hasPhoto ? 'Change photo' : 'Add a photo',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.primary, width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(hasPhoto ? 0 : 24),
                    child: avatar,
                  ),
                ),
                // The badge says what tapping does: change the photo.
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.fill,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.background, width: 3),
                    ),
                    child: Icon(
                      hasPhoto ? LucideIcons.pencil : LucideIcons.camera,
                      size: 17,
                      color: p.onFill,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              hasPhoto ? 'Change photo' : 'Add a photo',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: p.primary),
            ),
          ],
        ),
      ),
    );
  }
}
