import 'package:flutter/material.dart' as mat;
import 'package:fl_chart/fl_chart.dart' as fl_chart;

class PriorityChart extends mat.StatelessWidget {
  final Map<String, int> stats;

  const PriorityChart({
    super.key,
    required this.stats,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final highCount = stats['High'] ?? 0;
    final mediumCount = stats['Medium'] ?? 0;
    final lowCount = stats['Low'] ?? 0;
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks by Priority',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.SizedBox(
              height: 200,
              child: highCount == 0 && mediumCount == 0 && lowCount == 0
                  ? const mat.Center(child: mat.Text('No data available'))
                  : _buildBarChart(context, highCount, mediumCount, lowCount),
            ),
          ],
        ),
      ),
    );
  }
  
  mat.Widget _buildBarChart(
    mat.BuildContext context, 
    int highCount, 
    int mediumCount, 
    int lowCount
  ) {
    return fl_chart.BarChart(
      fl_chart.BarChartData(
        alignment: fl_chart.BarChartAlignment.spaceAround,
        maxY: [highCount, mediumCount, lowCount].reduce(
          (a, b) => a > b ? a : b
        ).toDouble() + 2,
        barTouchData: fl_chart.BarTouchData(
          enabled: true,
        ),
        titlesData: _buildTitlesData(context),
        gridData: fl_chart.FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => fl_chart.FlLine(
            color: mat.Theme.of(context).colorScheme.onSurface.withAlpha(25),
            strokeWidth: 1,
          ),
        ),
        borderData: fl_chart.FlBorderData(show: false),
        barGroups: _buildBarGroups(highCount, mediumCount, lowCount),
      ),
    );
  }

  List<fl_chart.BarChartGroupData> _buildBarGroups(int high, int medium, int low) {
    return [
      fl_chart.BarChartGroupData(
        x: 0,
        barRods: [
          fl_chart.BarChartRodData(
            toY: high.toDouble(),
            color: mat.Colors.red,
            width: 22,
            borderRadius: const mat.BorderRadius.only(
              topLeft: mat.Radius.circular(6),
              topRight: mat.Radius.circular(6),
            ),
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 1,
        barRods: [
          fl_chart.BarChartRodData(
            toY: medium.toDouble(),
            color: mat.Colors.orange,
            width: 22,
            borderRadius: const mat.BorderRadius.only(
              topLeft: mat.Radius.circular(6),
              topRight: mat.Radius.circular(6),
            ),
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 2,
        barRods: [
          fl_chart.BarChartRodData(
            toY: low.toDouble(),
            color: mat.Colors.green,
            width: 22,
            borderRadius: const mat.BorderRadius.only(
              topLeft: mat.Radius.circular(6),
              topRight: mat.Radius.circular(6),
            ),
          ),
        ],
      ),
    ];
  }

  fl_chart.FlTitlesData _buildTitlesData(mat.BuildContext context) {
    return fl_chart.FlTitlesData(
      show: true,
      bottomTitles: fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            String text;
            switch (value.toInt()) {
              case 0:
                text = 'High';
                break;
              case 1:
                text = 'Medium';
                break;
              case 2:
                text = 'Low';
                break;
              default:
                text = '';
            }
            return mat.Padding(
              padding: const mat.EdgeInsets.only(top: 8),
              child: mat.Text(
                text,
                style: mat.TextStyle(
                  color: mat.Theme.of(context).colorScheme.onSurface,
                  fontWeight: mat.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value == 0) {
              return const mat.SizedBox.shrink();
            }
            return mat.Padding(
              padding: const mat.EdgeInsets.only(right: 8),
              child: mat.Text(
                value.toInt().toString(),
                style: mat.TextStyle(
                  color: mat.Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            );
          },
          reservedSize: 30,
        ),
      ),
      rightTitles: const fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(showTitles: false),
      ),
      topTitles: const fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(showTitles: false),
      ),
    );
  }
}