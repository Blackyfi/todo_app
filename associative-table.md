# Todo App Database Schema

## Entity Relationship Diagram

```
┌───────────────┐       ┌───────────────┐       ┌─────────────────────┐
│   categories  │       │     tasks     │       │ notificationSettings │
├───────────────┤       ├───────────────┤       ├─────────────────────┤
│ id (PK)       │◄──┐   │ id (PK)       │───┐   │ id (PK)             │
│ name          │   │   │ title         │   │   │ taskId (FK)         │
│ color         │   │   │ description   │   │   │ timeOption          │
└───────────────┘   │   │ dueDate       │   │   │ customTime          │
                    └───┤ isCompleted   │   │   └─────────────────────┘
                        │ completedAt   │   │
                        │ categoryId(FK)│   │   ┌─────────────────────┐
                        │ priority      │   │   │  autoDeleteSettings  │
                        └───────────────┘   │   ├─────────────────────┤
                                            └──►│ id (PK)             │
                                                │ deleteImmediately   │
                                                │ deleteAfterDays     │
                                                └─────────────────────┘
```

## Tables

### categories

This table stores the task categories with customizable names and colors.

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| id          | INTEGER   | PRIMARY KEY AUTOINCREMENT | Unique identifier for each category |
| name        | TEXT      | NOT NULL    | Name of the category |
| color       | INTEGER   | NOT NULL    | Color value of the category (stored as an integer representing a color) |