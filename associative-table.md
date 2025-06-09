# Todo App Database Schema

## Entity Relationship Diagram

```md
┌───────────────────────────┐       ┌─────────────────────────────┐       ┌─────────────────────────────┐
│        categories         │       │            tasks            │       │    notificationSettings     │
├───────────────────────────┤       ├─────────────────────────────┤       ├─────────────────────────────┤
│ id (PK)                   │◄──┐   │ id (PK)                     │───┐   │ id (PK)                     │
│ name VARCHAR(255) NOT NULL│   │   │ title VARCHAR(255) NOT NULL │   │   │ taskId (FK) INTEGER NOT NULL│
│ color INTEGER NOT NULL    │   │   │ description TEXT            │   │   │ timeOption INTEGER NOT NULL │
└───────────────────────────┘   │   │ dueDate INTEGER             │   │   │ customTime INTEGER          │
                                └───┤ isCompleted INTEGER NOT NULL│   │   └─────────────────────────────┘
                                    │ completedAt INTEGER         │   │
                                    │ categoryId (FK) INTEGER     │   │   ┌─────────────────────────────┐
                                    │ priority INTEGER NOT NULL   │   │   │     autoDeleteSettings      │
                                    └─────────────────────────────┘   │   ├─────────────────────────────┤
                                                                      └──►│ id (PK)                     │
                                                                          │ deleteImmediately INTEGER   │
                                                                          │ deleteAfterDays INTEGER     │
                                                                          └─────────────────────────────┘
```

## Database Configuration

### Platform Support

- **Mobile Platforms**: Native SQLite using sqflite package
- **Desktop Platforms**: SQLite with FFI support using sqflite_common_ffi
- **Database Version**: 1 (with migration support for future versions)
- **Database Name**: `todo_app.db`
- **Location**: Application documents directory with platform-specific paths

### Key Features

- **Foreign Key Support**: Enabled with CASCADE DELETE operations
- **Transaction Support**: ACID compliance for data integrity
- **Automatic Indexing**: Optimized query performance on key fields
- **Error Handling**: Comprehensive error logging and recovery

## Table Definitions

### categories

This table stores the task categories with customizable names and colors for visual organization.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each category |
| name        | TEXT      | NOT NULL    | Name of the category (e.g., "Work", "Personal") |
| color       | INTEGER   | NOT NULL    | Color value stored as 32-bit ARGB integer |

#### Default Categories

The system automatically creates 5 default categories on first launch:

- **Work** (Blue: 0xFF2196F3)
- **Personal** (Green: 0xFF4CAF50)
- **Shopping** (Orange: 0xFFFF9800)
- **Health** (Red: 0xFFF44336)
- **Education** (Purple: 0xFF9C27B0)

#### Category Features

- **Color Coding**: 8 predefined colors available for visual distinction
- **Optional Assignment**: Tasks can exist without categories
- **Cascade Delete**: Deleting a category removes all associated tasks
- **Task Count Tracking**: Display number of tasks per category

### tasks

This table is the core entity storing all task information with flexible categorization and comprehensive tracking.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each task |
| title       | TEXT      | NOT NULL    | Task title (required, minimum 3 characters) |
| description | TEXT      | NULL        | Optional detailed description of the task |
| dueDate     | INTEGER   | NULL        | Due date stored as milliseconds since epoch |
| isCompleted | INTEGER   | NOT NULL DEFAULT 0 | Boolean flag (0=incomplete, 1=completed) |
| completedAt | INTEGER   | NULL        | Timestamp when task was marked complete |
| categoryId  | INTEGER   | FOREIGN KEY (categories.id) ON DELETE CASCADE | Optional category assignment |
| priority    | INTEGER   | NOT NULL DEFAULT 1 | Priority level (0=high, 1=medium, 2=low) |

#### Task Features

- **Flexible Due Dates**: Optional date and time assignment with timezone support
- **Completion Tracking**: Automatic timestamp recording when tasks are completed
- **Priority System**: Three-level priority system with visual indicators
- **Category Integration**: Optional assignment to user-defined categories
- **Auto-Delete Support**: Configurable cleanup of completed tasks

#### Priority Levels

- **0 (High)**: Red indicator for urgent tasks
- **1 (Medium)**: Orange indicator for important tasks (default)
- **2 (Low)**: Green indicator for low-priority tasks

### notificationSettings

This table stores flexible notification preferences for each task, supporting multiple reminders per task.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each notification setting |
| taskId      | INTEGER   | NOT NULL, FOREIGN KEY (tasks.id) ON DELETE CASCADE | Reference to associated task |
| timeOption  | INTEGER   | NOT NULL    | Notification timing option (enum index) |
| customTime  | INTEGER   | NULL        | Custom notification time (milliseconds since epoch) |

#### Notification Time Options

The `timeOption` field stores enum indices corresponding to:

| Index | Option | Description |
|-------|--------|-------------|
| 0 | exactTime | Notification at exact task due time |
| 1 | fifteenMinutesBefore | 15 minutes before due time |
| 2 | thirtyMinutesBefore | 30 minutes before due time |
| 3 | oneHourBefore | 1 hour before due time |
| 4 | oneDayBefore | 24 hours before due time |
| 5 | previousSunday | Previous Sunday at task time |
| 6 | custom | User-defined time (requires customTime field) |

#### Advanced Notification Features

- **Multiple Reminders**: Each task can have unlimited notification settings
- **Timezone Awareness**: Automatic timezone handling for accurate scheduling
- **Custom Timing**: Flexible custom time selection for specific needs
- **Cascade Delete**: Notification settings automatically removed with parent task

### autoDeleteSettings

This table stores application-wide settings for automatic cleanup of completed tasks.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for settings |
| deleteImmediately | INTEGER | NOT NULL DEFAULT 0 | Boolean flag for immediate deletion |
| deleteAfterDays   | INTEGER | NOT NULL DEFAULT 1 | Number of days to retain completed tasks |

#### Auto-Delete Behavior

- **Immediate Mode**: `deleteImmediately = 1` removes completed tasks instantly
- **Delayed Mode**: `deleteImmediately = 0` uses `deleteAfterDays` value
- **Default Settings**: Retain completed tasks for 1 day before deletion
- **User Configurable**: Settings can be modified through the settings interface

## Database Operations & Queries

### Performance Optimizations

#### Indexing Strategy

- **Primary Keys**: Automatic indexing on all PRIMARY KEY columns
- **Foreign Keys**: Automatic indexing on categoryId and taskId for join performance
- **Date Queries**: Optimized for due date range queries and completion filtering

#### Query Optimization

- **Specific Projections**: Select only required columns to minimize data transfer
- **Prepared Statements**: All queries use parameterized statements for security and performance
- **Transaction Grouping**: Related operations grouped in transactions for consistency

### Common Query Patterns

#### Task Filtering Queries

```sql
-- Tasks due today
SELECT * FROM tasks 
WHERE dueDate >= ? AND dueDate <= ? 
ORDER BY dueDate ASC;

-- Overdue incomplete tasks
SELECT * FROM tasks 
WHERE dueDate < ? AND isCompleted = 0 
ORDER BY priority ASC, dueDate ASC;

-- Tasks by category with category info
SELECT t.*, c.name as categoryName, c.color as categoryColor 
FROM tasks t 
LEFT JOIN categories c ON t.categoryId = c.id 
WHERE t.categoryId = ?;
```

#### Statistics Queries

```sql
-- Completion rate by priority
SELECT priority, 
       COUNT(*) as total,
       SUM(isCompleted) as completed
FROM tasks 
GROUP BY priority;

-- Tasks per category
SELECT c.name, c.color, COUNT(t.id) as taskCount
FROM categories c
LEFT JOIN tasks t ON c.id = t.categoryId
GROUP BY c.id, c.name, c.color;
```

## Data Integrity & Constraints

### Referential Integrity

- **Foreign Key Constraints**: Enforced relationships between tables
- **Cascade Operations**: Automatic cleanup when parent records are deleted
- **Null Handling**: Proper handling of optional relationships (tasks without categories)

### Data Validation

- **Required Fields**: NOT NULL constraints on essential data
- **Default Values**: Sensible defaults for optional fields
- **Type Safety**: Proper data type enforcement for all columns
- **Range Validation**: Application-level validation for enum values and ranges

### Backup & Recovery

- **Transaction Safety**: All critical operations wrapped in transactions
- **Error Recovery**: Comprehensive error handling with rollback support
- **Data Validation**: Input validation before database operations
- **Consistency Checks**: Regular validation of data relationships

## Schema Evolution & Migration

### Version Control

- **Current Version**: 1 (initial schema)
- **Migration Support**: Framework in place for future schema changes
- **Backward Compatibility**: Designed to support data migration between versions

### Future Enhancements

The schema is designed to support planned features:

- **User Management**: Ready for multi-user support
- **Attachments**: Extensible for file attachments
- **Collaboration**: Structure supports shared tasks and permissions
- **Sync Support**: Compatible with cloud synchronization requirements

### Migration Strategy

- **Incremental Updates**: Version-based migration system
- **Data Preservation**: Ensure no data loss during schema updates
- **Testing**: Comprehensive migration testing before release
- **Rollback Support**: Safe rollback mechanisms for failed migrations
