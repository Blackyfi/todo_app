import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/core/database/repository/category_repository.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/features/tasks/models/task.dart';
import 'package:todo_app/features/categories/models/category.dart';
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';

// Generate mocks
@GenerateMocks([
  TaskRepository,
  CategoryRepository,
  AutoDeleteSettingsRepository,
  WidgetConfigRepository,
])
import 'mock_repositories.mocks.dart';

// Export the generated mocks
export 'mock_repositories.mocks.dart';

// Helper methods to set up common mock behaviors
class MockRepositoryHelpers {
  static void setupTaskRepositoryDefaults(MockTaskRepository mock) {
    when(mock.getAllTasks()).thenAnswer((_) async => <Task>[]);
    when(mock.getTask(any)).thenAnswer((_) async => null);
    when(mock.insertTask(any)).thenAnswer((_) async => 1);
    when(mock.updateTask(any)).thenAnswer((_) async => 1);
    when(mock.deleteTask(any)).thenAnswer((_) async => 1);
    when(mock.getTasksByCompletionStatus(any)).thenAnswer((_) async => <Task>[]);
    when(mock.toggleTaskCompletion(any, any)).thenAnswer((_) async => 1);
  }

  static void setupCategoryRepositoryDefaults(MockCategoryRepository mock) {
    when(mock.getAllCategories()).thenAnswer((_) async => <Category>[]);
    when(mock.getCategory(any)).thenAnswer((_) async => null);
    when(mock.insertCategory(any)).thenAnswer((_) async => 1);
    when(mock.updateCategory(any)).thenAnswer((_) async => 1);
    when(mock.deleteCategory(any)).thenAnswer((_) async => 1);
  }

  static void setupAutoDeleteSettingsRepositoryDefaults(MockAutoDeleteSettingsRepository mock) {
    when(mock.getSettings()).thenAnswer((_) async => AutoDeleteSettings(
      id: 1,
      deleteImmediately: false,
      deleteAfterDays: 1,
    ));
    when(mock.insertSettings(any)).thenAnswer((_) async => 1);
    when(mock.updateSettings(any)).thenAnswer((_) async => 1);
  }
}