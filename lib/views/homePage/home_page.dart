import 'dart:io';

import 'package:bimir_lock/controller/homePage/home_page_controller.dart';

import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/views/homePage/add_password.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:bimir_lock/widgets/empty_state.dart';
import 'package:bimir_lock/widgets/vault_status_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

import '../../widgets/bimir_lock_drawer.dart';
import '../../widgets/custom/custom_text_field.dart';
import '../../widgets/slidable_list_tile.dart';
import '../user/add_user_detail.dart';

class HomePage extends StatelessWidget {
  static const String routeName = "/homePage";
  HomePage({
    super.key,
  });

  final HomePageController c = Get.put(HomePageController());

  final CoreController cc = Get.find<CoreController>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: UpgradeAlert(
        showIgnore: false,
        barrierDismissible: false,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Builder(builder: (context) {
                return IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  highlightColor: Colors.transparent,
                  icon: Icon(
                    Icons.menu_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
                );
              }),
            ),
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: theme.colorScheme.onInverseSurface,
                  ),
                  child: ClipOval(
                    child: cc.currentUser.value?.userAvatar == null
                        ? const Icon(
                            Icons.person,
                            size: 30,
                          )
                        : GestureDetector(
                            onTap: () {
                              navigatorKey.currentState!.pushNamed(
                                  AddUserDetailPage.routeName,
                                  arguments: true);
                            },
                            child: Image.file(
                              File(
                                cc.currentUser.value!.userAvatar!,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
            ],

            //drawr
            //profile pic
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                children: [
                  VaultStatusBanner(controller: c),
                  BimirLockTextField(
                    focusNode: _focusNode,
                    prefixIcon: const Icon(Icons.search),
                    controller: c.searchEditingController,
                    label: "Search",
                    hint: "Facebook || name || email",
                    onValueChange: (value) {
                      return c.searchPassword(value);
                    },
                  ),
                  const SizedBox(
                    height: 30,
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        FocusManager.instance.primaryFocus!.unfocus();
                        await c.loadPasswords();
                        c.searchEditingController.clear();
                        c.searchPassword("");
                      },
                      child: Obx(
                        () => c.loading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : c.searchedValue.isNotEmpty
                                ? c.searchedPasswords.isNotEmpty
                                    ? ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        shrinkWrap: false,
                                        itemCount: c.searchedPasswords.length + 1,
                                        itemBuilder: (context, index) {
                                          if (kDebugMode) {
                                            print(c.searchedPasswords.length);
                                          }
                                          if (c.searchedPasswords.length ==
                                              index) {
                                            return const SizedBox(
                                              height: 100,
                                            );
                                          }

                                          return SlidableListTile(
                                            passwordTable:
                                                c.searchedPasswords[index],
                                          );
                                        },
                                      )
                                    : const EmptyState(
                                        description:
                                            "Password you are searching cannot be found.\nPlease add passwords")
                                : c.passwords!.isEmpty
                                    ? EmptyState(
                                        description: c.vaultError.value != null
                                            // Never let a read failure read as
                                            // "you have no passwords": that is
                                            // what makes a frightened user
                                            // clear app data.
                                            ? "Your saved passwords are still on this device,\nbut they can't be read right now.\nDo not uninstall the app or clear its data."
                                            : "Password cannot be found.\nPlease add passwords")
                                    : ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        shrinkWrap: false,
                                        itemCount: c.passwords!.length + 1,
                                        itemBuilder: (context, index) {
                                          if (c.passwords!.length == index) {
                                            return const SizedBox(
                                              height: 100,
                                            );
                                          }
                                          return SlidableListTile(
                                            passwordTable: c.passwords![index],
                                          );
                                        },
                                      ),
                      ),
                    ),
                  ),
                  // tile
                ],
              ),
            ),
          ),
          resizeToAvoidBottomInset: false,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "addPasswordButton",
            onPressed: () {
              if (c.vaultHealth.value == VaultKeyHealth.keyLost) {
                // Fail closed: a write while the key is unusable would either
                // be impossible to encrypt or would overwrite something we
                // cannot read back.
                Get.snackbar("Vault locked",
                    "Bimir Lock can't unlock your saved passwords on this device, so adding a new one is disabled. Your saved data has not been changed.");
                return;
              }
              if (cc.encryptedPassword == null) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Required Access pin!!!"),
                        content: const Text(
                          "You have not set access pin yet. Please set access pin first to add password.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              navigatorKey.currentState!
                                  .pushNamed(SetAccessPinPage.routeName);
                            },
                            child: const Text(
                              "Ok",
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Cancel",
                            ),
                          ),
                        ],
                      );
                    });
                Get.snackbar("Error", "Please set access pin first");
                return;
              } else {
                navigatorKey.currentState!.pushNamed(AddPasswordPage.routeName);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Add password"),
            backgroundColor: theme.colorScheme.onInverseSurface,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          drawer: BimirLockDrawer(),
        ),
      ),
    );
  }
}
