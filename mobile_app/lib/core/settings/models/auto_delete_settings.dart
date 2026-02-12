class AutoDeleteSettings {
  final int? id;
  final bool deleteImmediately;
  final int deleteAfterDays;

  AutoDeleteSettings({
    this.id,
    this.deleteImmediately = false,
    this.deleteAfterDays = 1,
  });

  AutoDeleteSettings copyWith({
    int? id,
    bool? deleteImmediately,
    int? deleteAfterDays,
  }) {
    return AutoDeleteSettings(
      id: id ?? this.id,
      deleteImmediately: deleteImmediately ?? this.deleteImmediately,
      deleteAfterDays: deleteAfterDays ?? this.deleteAfterDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deleteImmediately': deleteImmediately ? 1 : 0,
      'deleteAfterDays': deleteAfterDays,
    };
  }

  factory AutoDeleteSettings.fromMap(Map<String, dynamic> map) {
    return AutoDeleteSettings(
      id: map['id'],
      deleteImmediately: map['deleteImmediately'] == 1,
      deleteAfterDays: map['deleteAfterDays'],
    );
  }
}