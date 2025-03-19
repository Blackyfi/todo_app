# Todo App Database Schema

## Tables

### categories

This table stores the task categories with customizable names and colors.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each category |
| name        | TEXT      | NOT NULL    | Name of the category |
| color       | INTEGER   | NOT NULL    | Color value of the category (stored as an integer representing a color) |

### tasks

This table stores all task information including completion status and metadata.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each task |
| title       | TEXT      | NOT NULL    | Title of the task |
| description | TEXT      |             | Description of the task (optional) |
| dueDate     | INTEGER   |             | Due date and time of the task in milliseconds since epoch (optional) |
| isCompleted | INTEGER   | NOT NULL DEFAULT 0 | Task completion status (0 = incomplete, 1 = complete) |
| categoryId  | INTEGER   |             | Reference to categories.id (optional) |
| priority    | INTEGER   | NOT NULL DEFAULT 1 | Priority level (0 = high, 1 = medium, 2 = low) |

### notificationSettings

This table stores notification preferences for each task with flexible timing options.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each notification setting |
| taskId      | INTEGER   | NOT NULL, FOREIGN KEY | Reference to tasks.id |
| timeOption  | INTEGER   | NOT NULL    | Notification time option (enum value) |
| customTime  | INTEGER   |             | Custom notification time in milliseconds since epoch (only used when timeOption is custom) |

## Relationships

### One-to-Many: categories to tasks
- Each category can have multiple tasks
- Each task may belong to one category or have no category
- Foreign key: `tasks.categoryId` references `categories.id`
- ON DELETE CASCADE: When a category is deleted, all associated tasks are also deleted

### One-to-Many: tasks to notificationSettings
- Each task can have multiple notification settings
- Each notification setting belongs to exactly one task
- Foreign key: `notificationSettings.taskId` references `tasks.id`
- ON DELETE CASCADE: When a task is deleted, all associated notification settings are also deleted

## Enum Values

### Priority (tasks.priority)
- 0: HIGH - Represented with red color
- 1: MEDIUM - Represented with orange color
- 2: LOW - Represented with green color

### NotificationTimeOption (notificationSettings.timeOption)
- 0: EXACT_TIME - Notify at the exact task due time
- 1: FIFTEEN_MINUTES_BEFORE - Notify 15 minutes before due time
- 2: THIRTY_MINUTES_BEFORE - Notify 30 minutes before due time
- 3: ONE_HOUR_BEFORE - Notify 1 hour before due time
- 4: ONE_DAY_BEFORE - Notify 1 day before due time
- 5: PREVIOUS_SUNDAY - Notify on the Sunday before the task's due date
- 6: CUSTOM - Notify at a custom time specified in the customTime field

## Default Data

### Default Categories
The database is initialized with the following default categories:

1. Work (Color: Blue - 0xFF2196F3)
2. Personal (Color: Green - 0xFF4CAF50)
3. Shopping (Color: Orange - 0xFFFF9800)
4. Health (Color: Red - 0xFFF44336)
5. Education (Color: Purple - 0xFF9C27B0)

## Database Initialization

Database creation includes:
- Table creation with proper constraints
- Default category insertion
- Foreign key support enabling
- Database version management (current version: 1)

## Query Examples

### Tasks by Category
```sql
SELECT * FROM tasks WHERE categoryId = ?
```

### Tasks by Priority
```sql
SELECT * FROM tasks WHERE priority = ?
```

### Tasks by Completion Status
```sql
SELECT * FROM tasks WHERE isCompleted = ?
```

### Tasks by Due Date
```sql
SELECT * FROM tasks WHERE dueDate >= ? AND dueDate <= ?
```

### Upcoming Tasks
```sql
SELECT * FROM tasks WHERE dueDate >= ? AND isCompleted = 0 ORDER BY dueDate ASC
```

### Notification Settings for Task
```sql
SELECT * FROM notificationSettings WHERE taskId = ?
```