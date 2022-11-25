import 'dart:io';

import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';
import 'package:hydrated_state_notifier_hive/hydrated_state_notifier_hive.dart';
import 'package:path/path.dart' as path;

int calculate() {
  return 6 * 7;
}

const kIsWeb = identical(0, 0.0);

Future<void> setupStorage() async {
  HydratedStorage.storage = await HiveHydratedStorage.build(
    storageDirectoryPath: kIsWeb
        ? ''
        : (await Directory(path.join(Directory.current.path, '.cache'))
                .create())
            .path,
  );
}
