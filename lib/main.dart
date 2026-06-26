import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'storage/local_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory appDirectory = await getApplicationDocumentsDirectory();

  await LocalDb.initialize(
    hiveDirectoryPath: appDirectory.path,
  );

  runApp(const RoadGuardApp());
}
