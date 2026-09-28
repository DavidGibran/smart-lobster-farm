import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/monitoring_period.dart';
import '../../models/monitoring_chart_series.dart';

class SensorLineChart extends StatelessWidget {
  const SensorLineChart({
    super.key,
    required this.points,
    required this.period,
    required this.lineColor,
    required this.referenceMinimum,
    required this.referenceMaximum,
    required this.decimalDigits,
    this.unit = '',
    this.scaleMinimum,
    this.scaleMaximum,
  });

  final List<SensorChartPoint> points;
  final MonitoringPeriod period;
  final Color lineColor;
  final double referenceMinimum;
  final double referenceMaximum;
  final double? scaleMinimum;
  final double? scaleMaximum;
  final int decimalDigits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final firstTimestamp = points.first.timestamp;
    final spots = points
        .map((point) {
          final elapsedMinutes =
              point.timestamp.difference(firstTimestamp).inSeconds /
              Duration.secondsPerMinute;
          return FlSpot(elapsedMinutes, point.value);
        })
        .toList(growable: false);

    final rawMaxX = spots.last.x;
    final maxX = rawMaxX <= 0 ? 1.0 : rawMaxX;
    final bounds = _calculateYBounds();
    final xInterval = _xInterval(maxX);
    final yInterval = (bounds.maximum - bounds.minimum) / 4;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: bounds.minimum,
        maxY: bounds.maximum,
        clipData: const FlClipData.all(),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: referenceMinimum,
              y2: referenceMaximum,
              color: lineColor.withAlpha(20),
            ),
          ],
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.outline, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: AppColors.outline),
            bottom: BorderSide(color: AppColors.outline),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yInterval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 6,
                child: Text(
                  value.toStringAsFixed(unit == 'ppm' ? 0 : 1),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final timestamp = firstTimestamp.add(
                  Duration(
                    seconds: (value * Duration.secondsPerMinute).round(),
                  ),
                );
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    _formatAxisTime(timestamp),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            tooltipMargin: 8,
            maxContentWidth: 140,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipRoundedRadius: 10,
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    final point = points[spot.spotIndex];
                    final suffix = unit.isEmpty ? '' : ' $unit';
                    final timestamp = DateFormat(
                      'dd MMM HH:mm',
                      'id_ID',
                    ).format(point.timestamp);
                    return LineTooltipItem(
                      '$timestamp\n${point.value.toStringAsFixed(decimalDigits)}$suffix',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  })
                  .toList(growable: false);
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: lineColor,
            barWidth: 2.2,
            isCurved: false,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  ({double minimum, double maximum}) _calculateYBounds() {
    var minimum = points.map((point) => point.value).reduce(math.min);
    var maximum = points.map((point) => point.value).reduce(math.max);
    minimum = math.min(minimum, scaleMinimum ?? referenceMinimum);
    maximum = math.max(maximum, scaleMaximum ?? referenceMaximum);

    final span = maximum - minimum;
    final padding = span == 0 ? math.max(maximum.abs() * 0.1, 1) : span * 0.12;
    return (
      minimum: math.max(0, minimum - padding),
      maximum: maximum + padding,
    );
  }

  double _xInterval(double maxX) {
    return switch (period) {
      MonitoringPeriod.day24 => math.min(maxX, 360),
      MonitoringPeriod.days7 => math.min(maxX, 1440),
      MonitoringPeriod.days30 => maxX / 5,
    };
  }

  String _formatAxisTime(DateTime timestamp) {
    return switch (period) {
      MonitoringPeriod.day24 => DateFormat('HH:mm', 'id_ID').format(timestamp),
      MonitoringPeriod.days7 => DateFormat('EEE', 'id_ID').format(timestamp),
      MonitoringPeriod.days30 => DateFormat('d MMM', 'id_ID').format(timestamp),
    };
  }
}
