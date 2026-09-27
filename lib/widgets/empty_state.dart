import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.description,
  });
  final String description;
  @override
  Widget build(BuildContext context) {
    // Scrollable, not a bare Column. The vault-unreadable description is three
    // lines and it appears UNDER the keyLost banner, which together overflow a
    // short viewport: a RenderFlex overflow clips text from the bottom, and the
    // text being clipped is exactly the sentence that tells the user not to
    // uninstall or clear app data. Clipping that sentence is what turns a
    // recoverable key problem into permanent, unrecoverable data loss.
    //
    // The minHeight keeps the artwork centred whenever it does fit, so the
    // ordinary "no passwords yet" state looks unchanged.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  "assets/lotties/empty_state.json",
                  // Bounded by the available HEIGHT as well as the width.
                  // At 0.7 * width alone the artwork is ~500px tall on a
                  // 720px-wide phone, which pushes the description off the
                  // bottom of a short viewport - and when the vault cannot be
                  // read, that description is the only thing standing between
                  // the user and clearing the app's data.
                  height: math.min(
                    MediaQuery.sizeOf(context).width * 0.7,
                    constraints.maxHeight * 0.30,
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  // Horizontal: keep long lines off the screen edge.
                  // Bottom: clear the "Add password" floating button, which
                  // otherwise sits on top of the last line of the message.
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
