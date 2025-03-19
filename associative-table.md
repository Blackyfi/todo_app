# Todo App Database Schema

## Tables

### categories

This table stores the task categories.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each category |
| name        | TEXT      | NOT NULL    | Name of the category |
| color       | INTEGER   | NOT NULL    | Color value of the category (stored as an integer) |

### tasks

This table stores the task information.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each task |
| title       | TEXT      | NOT NULL    | Title of the task |
| description | TEXT      |             | Description of the task (optional) |
| dueDate     | INTEGER   |             | Due date and time of the task in milliseconds since epoch (optional) |
| isCompleted | INTEGER   | NOT NULL DEFAULT 0 | Task completion status (0 = incomplete, 1 = complete) |
| categoryId  | INTEGER   | NOT NULL, FOREIGN KEY | Reference to categories.id |
| priority    | INTEGER   | NOT NULL DEFAULT 1 | Priority level (0 = high, 1 = medium, 2 = low) |

### notificationSettings

This table stores notification settings for tasks.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each notification setting |
| taskId      | INTEGER   | NOT NULL, FOREIGN KEY | Reference to tasks.id |
| timeOption  | INTEGER   | NOT NULL    | Notification time option (enum value) |
| customTime  | INTEGER   |             | Custom notification time in milliseconds since epoch (only used when timeOption is custom) |

## Relationships

### One-to-Many: categories to tasks
- Each category can have multiple tasks
- Each task belongs to exactly one category
- Foreign key: `tasks.categoryId` references `categories.id`
- ON DELETE CASCADE: When a category is deleted, all associated tasks are also deleted

### One-to-Many: tasks to notificationSettings
- Each task can have multiple notification settings
- Each notification setting belongs to exactly one task
- Foreign key: `notificationSettings.taskId` references `tasks.id`
- ON DELETE CASCADE: When a task is deleted, all associated notification settings are also deleted

## Enum Values

### Priority (tasks.priority)
- 0: HIGH
- 1: MEDIUM
- 2: LOW

### NotificationTimeOption (notificationSettings.timeOption)
- 0: EXACT_TIME (At exact task time)
- 1: FIFTEEN_MINUTES_BEFORE (15 minutes before)
- 2: THIRTY_MINUTES_BEFORE (30 minutes before)
- 3: ONE_HOUR_BEFORE (1 hour before)
- 4: ONE_DAY_BEFORE (1 day before)
- 5: PREVIOUS_SUNDAY (Previous Sunday)
- 6: CUSTOM (Custom time specified in customTime field)

## Default Data

### Default Categories
The database is initialized with the following default categories:

1. Work (Color: Blue)
2. Personal (Color: Green)
3. Shopping (Color: Orange)
4. Health (Color: Red)
5. Education (Color: Purple)
