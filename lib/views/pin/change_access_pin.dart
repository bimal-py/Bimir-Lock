import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:flutter/material.dart';

class ChangeAccessPinPage extends StatelessWidget {
  static const String routeName = "/change-access-pin";

  const ChangeAccessPinPage({super.key});

  @override
  Widget build(BuildContext context) => const PinSetupView(changing: true);
}
