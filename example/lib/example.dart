import 'dart:io';

import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:path/path.dart' as path;

int calculate() {
  return 6 * 7;
}

const kIsWeb = identical(0, 0.0);

Future<void> setupStorage() async {
  HydratedStateNotifier.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await Directory(
                path.join(Directory.current.path, '.cache'))
            .create(),
  );
}
