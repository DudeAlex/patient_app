import 'package:flutter/material.dart';

import 'core/di/bootstrap.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapAppContainer();
  runApp(const PatientApp());
}
