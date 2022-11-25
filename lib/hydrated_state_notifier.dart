/// An extension to [package:state_notifier](https://pub.dev/packages/state_notifier)
/// which automatically persists and restores provider states.
///
/// Built to work with [package:state_notifier](https://pub.dev/packages/state_notifier).
library hydrated_state_notifier;

export 'package:state_notifier/state_notifier.dart';

export 'src/exceptions.dart';
export 'src/hydrated_state_notifier.dart' hide NIL;
export 'src/hydrated_state_controller.dart';
export 'src/hydrated_cipher.dart';
export 'src/hydrated_storage.dart';
