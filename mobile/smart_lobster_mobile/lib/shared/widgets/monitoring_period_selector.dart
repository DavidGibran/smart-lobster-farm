import 'package:flutter/material.dart';

import '../../models/monitoring_period.dart';

class MonitoringPeriodSelector extends StatelessWidget {
  const MonitoringPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  final MonitoringPeriod selectedPeriod;
  final ValueChanged<MonitoringPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MonitoringPeriod>(
      segments: [
        for (final period in MonitoringPeriod.values)
          ButtonSegment(value: period, label: Text(period.label)),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
    );
  }
}
