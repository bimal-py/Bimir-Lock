import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BimirLockTextField extends StatelessWidget {
  final Function(String)? onValueChange;
  final bool autoFocus;
  final BorderRadius? radius;

  final String? hint;
  final int? maxline;
  final String? initial;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final TextInputType textInputType;
  final TextCapitalization textCapitalization;
  final Color? border;
  final bool readOnly;
  final bool obscure;
  final Function()? onTap;
  final Function()? onEyeTap;
  final Function(String)? onSubmit;
  final TextStyle? textStyle;
  final FocusNode? focusNode;
  final String? label;
  final bool enabled;
  final bool hasCopy;

  /// False for a row whose stored value could not be opened. Copying would put
  /// an empty string (or, worse, a raw envelope) on the clipboard and the user
  /// would believe it was their password.
  final bool canCopy;
  final bool isPass;

  const BimirLockTextField({
    super.key,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onValueChange,
    this.controller,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.done,
    this.textInputType = TextInputType.text,
    this.border,
    this.readOnly = false,
    this.onTap,
    this.onEyeTap,
    this.initial,
    this.obscure = false,
    this.onSubmit,
    this.autoFocus = false,
    this.maxline,
    this.radius,
    this.textStyle,
    this.focusNode,
    this.label,
    this.enabled = true,
    this.hasCopy = false,
    this.canCopy = true,
    this.isPass = false,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return TextFormField(
      enabled: enabled,
      focusNode: focusNode,
      autocorrect: false,
      autofocus: autoFocus,
      onFieldSubmitted: onSubmit,
      obscureText: obscure,
      onTap: (onTap != null) ? onTap! : null,
      readOnly: readOnly,
      keyboardType: textInputType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: (maxline != null) ? maxline : 1,
      initialValue: initial,
      validator: (validator != null) ? validator : null,
      controller: (controller != null) ? controller : null,
      onChanged: (text) {
        if (onValueChange != null) {
          onValueChange!(text);
        }
      },
      decoration: InputDecoration(
        prefixIcon: (prefixIcon != null) ? prefixIcon : null,
        suffixIcon: hasCopy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      final String text = controller?.text ?? "";
                      if (!canCopy || text.isEmpty) {
                        Fluttertoast.showToast(
                            msg: "Nothing to copy",
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.black,
                            textColor: Colors.white);
                        return;
                      }
                      Clipboard.setData(ClipboardData(text: text)).then(
                          (value) => Fluttertoast.showToast(
                              msg: "Text copied",
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.black,
                              textColor: Colors.white));
                    },
                    child: Icon(
                      Icons.copy,
                      color: canCopy ? null : theme.disabledColor,
                    ),
                  ),
                  if (isPass)
                    const SizedBox(
                      width: 10,
                    ),
                  isPass
                      ? InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: onEyeTap,
                          child: obscure
                              ? const Icon(
                                  Icons.visibility,
                                )
                              : const Icon(
                                  Icons.visibility_off,
                                ),
                        )
                      : const SizedBox.shrink(),
                  if (isPass)
                    const SizedBox(
                      width: 8,
                    ),
                ],
              )
            : null,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: (radius != null) ? radius! : const BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(
              width: 1, color: (border == null) ? theme.colorScheme.onPrimaryContainer : border!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: (radius != null) ? radius! : const BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(
              width: 1, color: (border == null) ? theme.colorScheme.onPrimaryContainer : border!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: (radius != null) ? radius! : const BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(width: 1, color: theme.colorScheme.error),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: (radius != null) ? radius! : const BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(
              width: 1, color: (border == null) ? theme.colorScheme.onPrimaryContainer : border!),
        ),
        hintText: hint ?? "",
        hintStyle: textStyle,
        labelText: label,
        suffix: null,
      ),
      style: textStyle,
    );
  }
}
