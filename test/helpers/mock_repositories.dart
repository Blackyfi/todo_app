import 'package:mockito/mockito.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/core/database/repository/category_repository.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockAutoDeleteSettingsRepository extends Mock implements AutoDeleteSettingsRepository {}
class MockWidgetConfigRepository extends Mock implements WidgetConfigRepository {}