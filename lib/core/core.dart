// Ported from the Reminder Note app's core layer (theme, text, helpers) so
// Bimir Lock and its Notes module share one Material 3 design system.
export 'package:flutter_scale_kit/flutter_scale_kit.dart';

export 'config/theme_config.dart';
export 'text/text.dart';
export 'theme/theme.dart';
export 'utils/extensions/extensions.dart';
export 'utils/helpers/custom_snackbar.dart';

// Added with the Notes module port (Reminder Note's data/error/dialog layer).
export 'di/di.dart';
export 'errors/errors.dart';
export 'router/router.dart';
export 'services/services.dart';
export 'utils/enums/enums.dart';
export 'utils/helpers/dialog/dialog.dart';
