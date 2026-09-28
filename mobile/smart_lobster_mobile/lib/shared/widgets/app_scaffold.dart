import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../features/activities/presentation/activities_page.dart';
import '../../features/activities/services/event_service.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/monitoring/presentation/monitoring_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../models/sensor_reading.dart';
import '../../services/sensor_service.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.sensorService});

  final SensorService sensorService;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;
  late final Stream<SensorReading> _sensorStream;
  late final EventService _eventService;

  @override
  void initState() {
    super.initState();
    _sensorStream = widget.sensorService.watchLatest();
    _eventService = EventService();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(sensorStream: _sensorStream),
      MonitoringPage(
        historyLoader: widget.sensorService.getMonitoringHistory,
        latestStream: _sensorStream,
        isActive: _selectedIndex == 1,
      ),
      ActivitiesPage(
        eventLoader: _eventService.getEvents,
        eventCreator: _eventService.createEvent,
        isActive: _selectedIndex == 2,
      ),
      const SettingsPage(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarDividerColor: AppColors.outline,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics_rounded),
                  label: 'Monitoring',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note_rounded),
                  label: 'Aktivitas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Pengaturan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
