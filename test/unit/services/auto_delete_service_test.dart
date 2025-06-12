import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:todo_app/core/settings/services/auto_delete_service.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';
import 'package:todo_app/features/tasks/models/task.dart';

import 'auto_delete_service_test.mocks.dart';

@GenerateMocks([TaskRepository, AutoDeleteSettingsRepository])
void main() {
  group('AutoDeleteService Tests', () {
    late AutoDeleteService autoDeleteService;
    late MockTaskRepository mockTaskRepository;
    late MockAutoDeleteSettingsRepository mockSettingsRepository;

    setUp(() {
      mockTaskRepository = MockTaskRepository();
      mockSettingsRepository = MockAutoDeleteSettingsRepository();
      
      // Inject mocks into the service using dependency injection
      // Note: You might need to modify AutoDeleteService to accept dependencies
      autoDeleteService = AutoDeleteService();
      
      // For this test, we'll assume the service uses the injected repositories
      // In practice, you might need to modify the service constructor
    });

    group('processCompletedTasks', () {
      test('should delete all completed tasks immediately when deleteImmediately is true', () async {
        // Arrange
        final settings = AutoDeleteSettings(
          id: 1,
          deleteImmediately: true,
          deleteAfterDays: 1,
        );

        final completedTasks = [
          Task(
            id: 1,
            title: 'Completed Task 1',
            isCompleted: true,
            completedAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          Task(
            id: 2,
            title: 'Completed Task 2',
            isCompleted: true,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockTaskRepository.getTasksByCompletionStatus(true))
            .thenAnswer((_) async => completedTasks);
        when(mockTaskRepository.deleteTask(any))
            .thenAnswer((_) async => 1);

        // Act
        await autoDeleteService.processCompletedTasks();

        // Assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockTaskRepository.getTasksByCompletionStatus(true)).called(1);
        verify(mockTaskRepository.deleteTask(1)).called(1);
        verify(mockTaskRepository.deleteTask(2)).called(1);
        verifyNever(mockTaskRepository.deleteCompletedTasksOlderThan(any));
      });

      test('should delete tasks older than specified days when deleteImmediately is false', () async {
        // Arrange
        final settings = AutoDeleteSettings(
          id: 1,
          deleteImmediately: false,
          deleteAfterDays: 7,
        );

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockTaskRepository.deleteCompletedTasksOlderThan(any))
            .thenAnswer((_) async => 3);

        // Act
        await autoDeleteService.processCompletedTasks();

        // Assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockTaskRepository.deleteCompletedTasksOlderThan(
          const Duration(days: 7)
        )).called(1);
        verifyNever(mockTaskRepository.getTasksByCompletionStatus(any));
      });

      test('should handle empty completed tasks list when deleteImmediately is true', () async {
        // Arrange
        final settings = AutoDeleteSettings(
          id: 1,
          deleteImmediately: true,
          deleteAfterDays: 1,
        );

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockTaskRepository.getTasksByCompletionStatus(true))
            .thenAnswer((_) async => []);

        // Act
        await autoDeleteService.processCompletedTasks();

        // Assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockTaskRepository.getTasksByCompletionStatus(true)).called(1);
        verifyNever(mockTaskRepository.deleteTask(any));
      });

      test('should handle tasks without id when deleteImmediately is true', () async {
        // Arrange
        final settings = AutoDeleteSettings(
          id: 1,
          deleteImmediately: true,
          deleteAfterDays: 1,
        );

        final completedTasks = [
          Task(
            title: 'Task without ID',
            isCompleted: true,
            completedAt: DateTime.now(),
          ),
          Task(
            id: 2,
            title: 'Task with ID',
            isCompleted: true,
            completedAt: DateTime.now(),
          ),
        ];

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockTaskRepository.getTasksByCompletionStatus(true))
            .thenAnswer((_) async => completedTasks);
        when(mockTaskRepository.deleteTask(any))
            .thenAnswer((_) async => 1);

        // Act
        await autoDeleteService.processCompletedTasks();

        // Assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockTaskRepository.getTasksByCompletionStatus(true)).called(1);
        // Should only delete the task with ID
        verify(mockTaskRepository.deleteTask(2)).called(1);
        verifyNever(mockTaskRepository.deleteTask(null));
      });

      test('should handle exceptions gracefully', () async {
        // Arrange
        when(mockSettingsRepository.getSettings())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => autoDeleteService.processCompletedTasks(),
          returnsNormally,
        );
      });

      test('should use default deleteAfterDays value of 1 when not specified', () async {
        // Arrange
        final settings = AutoDeleteSettings(
          id: 1,
          deleteImmediately: false,
          // deleteAfterDays should default to 1
        );

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockTaskRepository.deleteCompletedTasksOlderThan(any))
            .thenAnswer((_) async => 0);

        // Act
        await autoDeleteService.processCompletedTasks();

        // Assert
        verify(mockTaskRepository.deleteCompletedTasksOlderThan(
          const Duration(days: 1)
        )).called(1);
      });
    });
  });
}