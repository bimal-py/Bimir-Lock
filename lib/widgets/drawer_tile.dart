import 'package:bimir_lock/core/core_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrawerTile extends StatelessWidget {
  final CoreController cc = Get.find<CoreController>();

  final bool hasSwitch;
  final IconData iconData;
  final String title;

  // Optional switch source. When these are null the switch stays the theme
  // switch it has always been, so the existing tiles are unchanged.
  final RxBool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  DrawerTile({
    super.key,
    this.hasSwitch = false,
    required this.iconData,
    required this.title,
    this.switchValue,
    this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                iconData,
                size: 30,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          // Text(
          //   title,
          //   style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          // ),
          hasSwitch
              ? Transform.scale(
                  alignment: Alignment.centerRight,
                  scale: 0.6,
                  child: Container(
                    padding: const EdgeInsets.all(0),
                    child: Obx(() => Switch(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: switchValue != null
                              ? switchValue!.value
                              : cc.themeMode.value == ThemeMode.dark,
                          onChanged: onSwitchChanged ??
                              (value) {
                                cc.toggleThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                          // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )),
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 20,
                )
        ],
      ),
    );
  }
}
