import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

class AccessPinWidget extends StatelessWidget {
  final TextEditingController pinController;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Function(String)? onCompleted;

  AccessPinWidget({
    super.key,
    required this.pinController,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onCompleted,
  });

  // final pinController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Color.fromRGBO(23, 171, 144, 0.4);
    var theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );
    return Pinput(
      controller: pinController,
      focusNode: focusNode,
      length: 4,
      // pinput 6 no longer forces this off, which enabled copy/cut of the pin
      enableInteractiveSelection: false,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      closeKeyboardWhenCompleted: true,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      isCursorAnimationEnabled: true,
      defaultPinTheme: defaultPinTheme,
      validator: validator,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      onCompleted: onCompleted,
      // onChanged: (value) {
      //   debugPrint('onChanged: $value');
      // },
      cursor: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            width: 22,
            height: 1,
            color: focusedBorderColor,
          ),
        ],
      ),
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: focusedBorderColor),
        ),
      ),
      submittedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          color: fillColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: focusedBorderColor),
        ),
      ),
      errorPinTheme: defaultPinTheme.copyBorderWith(
        border: Border.all(color: theme.colorScheme.error),
      ),
    );
  }
}
