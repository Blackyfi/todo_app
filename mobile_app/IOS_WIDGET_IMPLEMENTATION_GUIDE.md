# iOS Widget Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing iOS home screen widgets for the Todo App using WidgetKit and SwiftUI.

## Prerequisites

- **Xcode 14+** (for iOS 16+ support)
- **macOS** development machine
- **Swift 5.7+**
- **iOS 16.0+** target
- **Apple Developer Account** (for App Groups)

---

## Step 1: Create Widget Extension

### 1.1 Add Widget Extension Target

1. Open project in Xcode: `ios/Runner.xcworkspace`
2. File → New → Target
3. Select **Widget Extension**
4. Name: `TodoWidget`
5. Check **Include Configuration Intent** (for widget customization)
6. Finish

### 1.2 Configure App Groups

**Why**: Widgets run in separate processes and need shared data access.

**Setup:**

1. In Xcode, select **Runner** target
2. Signing & Capabilities → **+ Capability** → **App Groups**
3. Add: `group.com.example.todoapp`

4. Select **TodoWidget** target
5. Signing & Capabilities → **+ Capability** → **App Groups**
6. Add: `group.com.example.todoapp` (same group)

---

## Step 2: Swift Data Models

Create `ios/TodoWidget/Models/TaskData.swift`:

```swift
import Foundation

struct TaskData: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let isCompleted: Bool
    let priority: Int
    let priorityLabel: String
    let priorityColor: UInt32
    let dueDate: Int64?
    let formattedDueDate: String?
    let category: CategoryData?
    let completedAt: Int64?
}

struct CategoryData: Codable {
    let name: String
    let color: UInt32
}

struct WidgetData: Codable {
    let config: WidgetConfigData
    let tasks: [TaskData]
    let updatedAt: Int64
    let taskCount: Int
    let completedCount: Int
    let overdueCount: Int
}

struct WidgetConfigData: Codable {
    let id: Int?
    let name: String
    let size: Int
    let showCompleted: Bool
    let showCategories: Bool
    let showPriority: Bool
    let categoryFilter: String?
    let maxTasks: Int
}
```

---

## Step 3: Data Provider

Create `ios/TodoWidget/Services/WidgetDataProvider.swift`:

```swift
import Foundation
import WidgetKit

class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let appGroupIdentifier = "group.com.example.todoapp"
    private let widgetDataKey = "widget_data"

    func getWidgetData() -> WidgetData? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Failed to access UserDefaults for app group")
            return nil
        }

        guard let jsonString = userDefaults.string(forKey: widgetDataKey) else {
            print("No widget data found")
            return nil
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let widgetData = try decoder.decode(WidgetData.self, from: jsonData)
            return widgetData
        } catch {
            print("Failed to decode widget data: \\(error)")
            return nil
        }
    }
}
```

---

## Step 4: Timeline Provider

Create `ios/TodoWidget/TodoWidgetTimelineProvider.swift`:

```swift
import WidgetKit
import SwiftUI

struct TodoEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData?
}

struct TodoWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), widgetData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let entry = TodoEntry(
            date: Date(),
            widgetData: WidgetDataProvider.shared.getWidgetData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let currentDate = Date()
        let widgetData = WidgetDataProvider.shared.getWidgetData()

        let entry = TodoEntry(date: currentDate, widgetData: widgetData)

        // Update every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}
```

---

## Step 5: Widget Views

### 5.1 Small Widget View

Create `ios/TodoWidget/Views/SmallWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        if let data = entry.widgetData {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(data.config.name)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                }

                // Progress
                ProgressView(value: Double(data.completedCount), total: Double(data.taskCount))
                    .tint(.green)

                // Stats
                HStack {
                    Text("\\(data.taskCount) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\\(percentage(completed: data.completedCount, total: data.taskCount))%")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                Spacer()

                // Top tasks (max 2)
                ForEach(data.tasks.prefix(2)) { task in
                    TaskRowCompact(task: task)
                }
            }
            .padding()
        } else {
            PlaceholderView(size: "Small")
        }
    }

    private func percentage(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return (completed * 100) / total
    }
}
```

### 5.2 Medium Widget View

Create `ios/TodoWidget/Views/MediumWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        if let data = entry.widgetData {
            HStack(spacing: 12) {
                // Left side - Header and progress
                VStack(alignment: .leading, spacing: 8) {
                    Text(data.config.name)
                        .font(.headline)
                        .lineLimit(1)

                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: CGFloat(data.completedCount) / CGFloat(max(data.taskCount, 1)))
                            .stroke(Color.green, lineWidth: 8)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\\(data.completedCount)")
                                .font(.system(size: 16, weight: .bold))
                            Text("of \\(data.taskCount)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if data.overdueCount > 0 {
                        Label("\\(data.overdueCount) overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right side - Task list
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(data.tasks.prefix(3)) { task in
                        TaskRowDetailed(task: task, showCategory: data.config.showCategories)
                    }

                    if data.tasks.count > 3 {
                        Text("+\\(data.tasks.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        } else {
            PlaceholderView(size: "Medium")
        }
    }
}
```

### 5.3 Large Widget View

Create `ios/TodoWidget/Views/LargeWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: TodoEntry

    var body: some View {
        if let data = entry.widgetData {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.config.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label("\\(data.taskCount) tasks", systemImage: "checkmark.circle")
                                .font(.caption)
                            Label("\\(data.completedCount) done", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            if data.overdueCount > 0 {
                                Label("\\(data.overdueCount) overdue", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    Spacer()

                    // Large circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 70, height: 70)

                        Circle()
                            .trim(from: 0, to: CGFloat(data.completedCount) / CGFloat(max(data.taskCount, 1)))
                            .stroke(Color.green, lineWidth: 10)
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))

                        Text("\\(percentage(completed: data.completedCount, total: data.taskCount))%")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }

                Divider()

                // Task list
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data.tasks.prefix(data.config.maxTasks)) { task in
                            TaskRowLarge(
                                task: task,
                                showCategory: data.config.showCategories,
                                showPriority: data.config.showPriority
                            )
                        }
                    }
                }
            }
            .padding()
        } else {
            PlaceholderView(size: "Large")
        }
    }

    private func percentage(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return (completed * 100) / total
    }
}
```

---

## Step 6: Task Row Components

Create `ios/TodoWidget/Views/TaskRowComponents.swift`:

```swift
import SwiftUI

struct TaskRowCompact: View {
    let task: TaskData

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .font(.system(size: 12))

            Text(task.title)
                .font(.caption)
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
        }
    }
}

struct TaskRowDetailed: View {
    let task: TaskData
    let showCategory: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Priority color bar
            Rectangle()
                .fill(priorityColor)
                .frame(width: 3, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .lineLimit(1)
                    .strikethrough(task.isCompleted)

                if showCategory, let category = task.category {
                    Text(category.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .font(.system(size: 14))
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case 0: return .red
        case 1: return .orange
        default: return .green
        }
    }
}

struct TaskRowLarge: View {
    let task: TaskData
    let showCategory: Bool
    let showPriority: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Priority indicator
            if showPriority {
                Rectangle()
                    .fill(priorityColor)
                    .frame(width: 4, height: 40)
            }

            // Checkbox
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .font(.system(size: 18))

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .strikethrough(task.isCompleted)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if showCategory, let category = task.category {
                        Text(category.name)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: category.color).opacity(0.2))
                            .cornerRadius(8)
                    }

                    if let dueDate = task.formattedDueDate {
                        Label(dueDate, systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch task.priority {
        case 0: return .red
        case 1: return .orange
        default: return .green
        }
    }
}

// Helper for color conversion
extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
```

---

## Step 7: Main Widget Configuration

Update `ios/TodoWidget/TodoWidget.swift`:

```swift
import WidgetKit
import SwiftUI

@main
struct TodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
    }
}

struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoWidgetTimelineProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Todo Tasks")
        .description("View your tasks at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodoWidgetEntryView: View {
    @Environment(\\.widgetFamily) var family
    let entry: TodoEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct PlaceholderView: View {
    let size: String

    var body: some View {
        VStack {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("\\(size) Widget")
                .font(.headline)
            Text("Loading tasks...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

---

## Step 8: Flutter Integration

Update Flutter's `WidgetService` to write iOS-compatible data:

```dart
Future<void> _saveWidgetDataForIOS(WidgetData data) async {
  try {
    // Use home_widget package to save to App Group
    await HomeWidget.saveWidgetData<String>(
      'widget_data',
      jsonEncode(data.toMap()),
    );

    await HomeWidget.updateWidget(
      iOSName: 'TodoWidget',
    );

    await _logger.logInfo('iOS widget data saved and updated');
  } catch (e, stackTrace) {
    await _logger.logError('Error saving iOS widget data', e, stackTrace);
  }
}
```

---

## Step 9: Widget Intents (Optional - Advanced)

For interactive widgets (iOS 17+), create `ios/TodoWidget/Intents/ToggleTaskIntent.swift`:

```swift
import AppIntents

@available(iOS 17.0, *)
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"

    @Parameter(title: "Task ID")
    var taskId: Int

    func perform() async throws -> some IntentResult {
        // Send command to Flutter via EventChannel
        // Implementation similar to Android EventChannel
        return .result()
    }
}
```

---

## Step 10: Testing

### 10.1 Run Widget in Simulator
1. Select **TodoWidget** scheme in Xcode
2. Run on iOS Simulator
3. Long-press home screen → Add Widget → TodoWidget

### 10.2 Test Data Flow
```dart
// In Flutter, trigger a widget update
await WidgetService().updateAllWidgets();
```

### 10.3 Debug Widget
```swift
// Add logging in Timeline Provider
print("Widget data: \\(String(describing: widgetData))")
```

---

## Troubleshooting

### Issue: Widget shows "Loading..."
**Solution:** Verify App Group ID matches in both targets and home_widget package

### Issue: Data not updating
**Solution:** Ensure `HomeWidget.updateWidget(iOSName: 'TodoWidget')` is called after saving data

### Issue: Widget not found
**Solution:** Clean build folder (Cmd+Shift+K) and rebuild

---

## Performance Optimization

1. **Limit data size**: Max 20 tasks in widget data
2. **Efficient JSON**: Minimize nested objects
3. **Timeline frequency**: Update every 5-15 minutes
4. **Background refresh**: Use BackgroundTasks framework for proactive updates

---

## Resources

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [home_widget Package](https://pub.dev/packages/home_widget)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

---

## Next Steps

1. Implement widget configuration UI in Flutter
2. Add widget deep linking (tap widget → open specific task)
3. Support iOS 17 interactive widgets
4. Add widget animations and transitions
5. Implement Lock Screen widgets (iOS 16+)

---

**Estimated Implementation Time:** 8-12 hours for full iOS widget support

**Status:** Ready for implementation (requires macOS + Xcode)
