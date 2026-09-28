import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/sensor_service.dart';
import 'shared/widgets/app_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID');

  runApp(const SmartLobsterApp());
}

class SmartLobsterApp extends StatelessWidget {
  const SmartLobsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Lobster Farming',
      theme: AppTheme.light(),
      home: AppScaffold(sensorService: SensorService()),
    );
  }
}
