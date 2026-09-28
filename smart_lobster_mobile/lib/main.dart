import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartLobsterApp());
}

class SmartLobsterApp extends StatelessWidget {
  const SmartLobsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Lobster Farming',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  DatabaseReference get sensorRef =>
      FirebaseDatabase.instance.ref(
        'devices/oase-01/latest',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Lobster Farming',
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: sensorRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Gagal membaca data sensor',
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final raw =
              snapshot.data!.snapshot.value;

          final data =
              Map<String, dynamic>.from(
            raw as Map,
          );

          final ph =
              (data['ph'] as num?)
                      ?.toDouble() ??
                  0;

          final tds =
              (data['tds'] as num?)
                      ?.toDouble() ??
                  0;

          final temperature =
              (data['temperature'] as num?)
                      ?.toDouble() ??
                  0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Kondisi Air',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              SensorCard(
                title: 'pH Air',
                value: ph.toStringAsFixed(2),
                status: getPhStatus(ph),
              ),

              SensorCard(
                title: 'TDS',
                value:
                    '${tds.toStringAsFixed(0)} ppm',
                status: getTdsStatus(tds),
              ),

              SensorCard(
                title: 'Suhu Air',
                value:
                    '${temperature.toStringAsFixed(1)} °C',
                status:
                    getTemperatureStatus(
                      temperature,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getPhStatus(double value) {
  if (value >= 7.0 && value <= 8.0) {
    return 'Ideal';
  }

  if (value >= 6.5 && value <= 9.0) {
    return 'Perlu perhatian';
  }

  return 'Di luar rentang toleransi';
}

String getTdsStatus(double value) {
  // Reference awal dari studi RAS,
  // bukan klaim optimum biologis.
  if (value >= 320 && value <= 400) {
    return 'Reference range';
  }

  return 'Di luar reference range';
}

String getTemperatureStatus(double value) {
  if (value >= 26 && value <= 29) {
    return 'Ideal';
  }

  if (value > 29 && value <= 32) {
    return 'Perlu perhatian';
  }

  if (value > 32) {
    return 'Suhu tinggi';
  }

  return 'Suhu rendah';
}