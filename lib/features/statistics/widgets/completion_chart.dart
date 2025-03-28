import 'package:flutter/material.dart' as mat;
import 'package:fl_chart/fl_chart.dart' as fl_chart;

class CompletionChart extends mat.StatelessWidget {
  final Map<String, int> stats;

  const CompletionChart({
    super.key,
    required this.stats,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final completedCount = stats['Completed'] ?? 0;
    final incompleteCount = stats['Incomplete'] ?? 0;
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Task Completion',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 8),
            mat.SizedBox(
              height: 200,
              child: completedCount == 0 && incompleteCount == 0
                  ? const mat.Center(child: mat.Text('No data available'))
                  : fl_chart.PieChart(
                      fl_chart.PieChartData(
                        sections: [
                          fl_chart.PieChartSectionData(
                            value: completedCount.toDouble(),
                            title: 'Completed\n$completedCount',
                            color: mat.Colors.green,
                            radius: 80,
                            titleStyle: const mat.TextStyle(
                              color: mat.Colors.white,
                              fontWeight: mat.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          fl_chart.PieChartSectionData(
                            value: incompleteCount.toDouble(),
                            title: 'Incomplete\n$incompleteCount',
                            color: mat.Colors.orange,
                            radius: 80,
                            titleStyle: const mat.TextStyle(
                              color: mat.Colors.white,
                              fontWeight: mat.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}