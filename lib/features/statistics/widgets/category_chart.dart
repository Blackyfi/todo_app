import 'package:flutter/material.dart' as mat;
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:todo_app/features/categories/models/category.dart' as category_model;

class CategoryChart extends mat.StatelessWidget {
  final Map<String, int> stats;
  final List<category_model.Category> categories;

  const CategoryChart({
    super.key,
    required this.stats,
    required this.categories,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    if (stats.isEmpty) {
      return _buildEmptyCard(context);
    }
    
    final List<fl_chart.PieChartSectionData> sections = _buildPieSections();
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks by Category',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.SizedBox(
              height: 250,
              child: fl_chart.PieChart(
                fl_chart.PieChartData(
                  sections: sections,
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

  mat.Widget _buildEmptyCard(mat.BuildContext context) {
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks by Category',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            const mat.Center(
              heightFactor: 5,
              child: mat.Text('No data available'),
            ),
          ],
        ),
      ),
    );
  }

  List<fl_chart.PieChartSectionData> _buildPieSections() {
    final Map<String, mat.Color> categoryColors = _getCategoryColors();
    final List<fl_chart.PieChartSectionData> sections = [];
    
    stats.forEach((category, count) {
      sections.add(
        fl_chart.PieChartSectionData(
          value: count.toDouble(),
          title: '$category\n$count',
          color: categoryColors[category] ?? mat.Colors.grey,
          radius: 80,
          titleStyle: const mat.TextStyle(
            color: mat.Colors.white,
            fontWeight: mat.FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    });
    
    return sections;
  }

  Map<String, mat.Color> _getCategoryColors() {
    final Map<String, mat.Color> categoryColors = {};
    for (final category in categories) {
      categoryColors[category.name] = category.color;
    }
    return categoryColors;
  }
}