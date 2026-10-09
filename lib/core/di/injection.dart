import 'package:get_it/get_it.dart';

/// Global service locator. Access registered services with `getIt<Type>()`.
///
/// Reminder Note fills this through injectable's generated config; Bimir Lock
/// has no build_runner step, so each module registers its own services by hand
/// (see `bootstrapNotes()` for the Notes module).
final GetIt getIt = GetIt.instance;
