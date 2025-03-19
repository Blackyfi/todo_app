class NotificationSetting {
  final int? id;
  final int taskId;
  final NotificationTimeOption timeOption;
  final DateTime? customTime;  // Only used when timeOption is custom

  NotificationSetting({
    this.id,
    required this.taskId,
    required this.timeOption,
    this.customTime,
  });

  NotificationSetting copyWith({
    int? id,
    int? taskId,
    NotificationTimeOption? timeOption,
    DateTime? customTime,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      timeOption: timeOption ?? this.timeOption,
      customTime: customTime ?? this.customTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'timeOption': timeOption.index,
      'customTime': customTime?.millisecondsSinceEpoch,
    };
  }

  factory NotificationSetting.fromMap(Map<String, dynamic> map) {
    return NotificationSetting(
      id: map['id'],
      taskId: map['taskId'],
      timeOption: NotificationTimeOption.values[map['timeOption']],
      customTime: map['customTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['customTime'])
          : null,
    );
  }
}

enum NotificationTimeOption {
  exactTime,
  fifteenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  oneDayBefore,
  previousSunday,
  custom,
}

extension NotificationTimeOptionExtension on NotificationTimeOption {
  String get label {
    switch (this) {
      case NotificationTimeOption.exactTime:
        return 'At exact task time';
      case NotificationTimeOption.fifteenMinutesBefore:
        return '15 minutes before';
      case NotificationTimeOption.thirtyMinutesBefore:
        return '30 minutes before';
      case NotificationTimeOption.oneHourBefore:
        return '1 hour before';
      case NotificationTimeOption.oneDayBefore:
        return '1 day before';
      case NotificationTimeOption.previousSunday:
        return 'Previous Sunday';
      case NotificationTimeOption.custom:
        return 'Custom time';
    }
  }

  DateTime calculateNotificationTime(DateTime taskTime, DateTime? customTime) {
    switch (this) {
      case NotificationTimeOption.exactTime:
        return taskTime;
      case NotificationTimeOption.fifteenMinutesBefore:
        return taskTime.subtract(const Duration(minutes: 15));
      case NotificationTimeOption.thirtyMinutesBefore:
        return taskTime.subtract(const Duration(minutes: 30));
      case NotificationTimeOption.oneHourBefore:
        return taskTime.subtract(const Duration(hours: 1));
      case NotificationTimeOption.oneDayBefore:
        return taskTime.subtract(const Duration(days: 1));
      case NotificationTimeOption.previousSunday:
        // Find the previous Sunday
        final daysToSubtract = taskTime.weekday == 7 ? 7 : taskTime.weekday;
        return DateTime(
          taskTime.year,
          taskTime.month,
          taskTime.day - daysToSubtract,
          taskTime.hour,
          taskTime.minute,
        );
      case NotificationTimeOption.custom:
        return customTime ?? taskTime;
    }
  }
}
