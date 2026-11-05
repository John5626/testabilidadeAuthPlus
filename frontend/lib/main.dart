import 'package:flutter/material.dart';

import 'src/app/studyapp_app.dart';
import 'src/core/config/app_config.dart';
import 'src/core/di/app_dependencies.dart';
import 'src/core/navigation/browser_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureBrowserNavigation();

  final config = AppConfig.fromEnvironment();
  final dependencies = AppDependencies(config: config);
  await dependencies.restoreSession();

  runApp(StudyAppApp(dependencies: dependencies));
}
