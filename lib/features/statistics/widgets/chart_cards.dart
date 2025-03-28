import 'package:flutter/material.dart' as mat;
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:intl/intl.dart' as intl;

import 'package:todo_app/features/statistics/widgets/completion_chart.dart';
import 'package:todo_app/features/statistics/widgets/priority_chart.dart';
import 'package:todo_app/features/statistics/widgets/category_chart.dart';
import 'package:todo_app/features/statistics/widgets/weekly_tasks_card.dart';
import 'package:todo_app/features/statistics/widgets/weekly_completion_chart.dart';

// This file now just exports the individual chart widgets
// All actual implementations have been moved to separate files
export 'package:todo_app/features/statistics/widgets/completion_chart.dart';
export 'package:todo_app/features/statistics/widgets/priority_chart.dart';
export 'package:todo_app/features/statistics/widgets/category_chart.dart';
export 'package:todo_app/features/statistics/widgets/weekly_tasks_card.dart';
export 'package:todo_app/features/statistics/widgets/weekly_completion_chart.dart';