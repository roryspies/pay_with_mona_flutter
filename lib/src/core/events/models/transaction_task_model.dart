class TransactionTaskModel {
  final String? taskDescription;
  final String? taskType;
  final String? fieldType;
  final String? fieldName;
  final bool? encrypted;
  final int? fieldLength;

  TransactionTaskModel({
    this.taskDescription,
    this.taskType,
    this.fieldType,
    this.fieldName,
    this.encrypted,
    this.fieldLength,
  });

  factory TransactionTaskModel.fromJSON({required Map<String, dynamic> json}) {
    return TransactionTaskModel(
      taskDescription: json['taskDescription'] as String?,
      taskType: json['taskType'] as String?,
      fieldType: json['fieldType'] as String?,
      fieldName: json['fieldName'] as String?,
      encrypted: json['encrypted'] as bool?,
      fieldLength: json['fieldLength'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (taskDescription != null) 'taskDescription': taskDescription,
        if (taskType != null) 'taskType': taskType,
        if (fieldType != null) 'fieldType': fieldType,
        if (fieldName != null) 'fieldName': fieldName,
        if (encrypted != null) 'encrypted': encrypted,
        if (fieldLength != null) 'fieldLength': fieldLength,
      };

  TransactionTaskModel copyWith({
    String? taskDescription,
    String? taskType,
    String? fieldType,
    String? fieldName,
    bool? encrypted,
    int? fieldLength,
  }) {
    return TransactionTaskModel(
      taskDescription: taskDescription ?? this.taskDescription,
      taskType: taskType ?? this.taskType,
      fieldType: fieldType ?? this.fieldType,
      fieldName: fieldName ?? this.fieldName,
      encrypted: encrypted ?? this.encrypted,
      fieldLength: fieldLength ?? this.fieldLength,
    );
  }

  @override
  String toString() {
    return 'TransactionTaskModel(taskDescription: $taskDescription, '
        'taskType: $taskType, fieldType: $fieldType, '
        'fieldName: $fieldName, encrypted: $encrypted, '
        'fieldLength: $fieldLength)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTaskModel &&
          runtimeType == other.runtimeType &&
          taskDescription == other.taskDescription &&
          taskType == other.taskType &&
          fieldType == other.fieldType &&
          fieldName == other.fieldName &&
          encrypted == other.encrypted &&
          fieldLength == other.fieldLength;

  @override
  int get hashCode =>
      taskDescription.hashCode ^
      taskType.hashCode ^
      fieldType.hashCode ^
      fieldName.hashCode ^
      encrypted.hashCode ^
      fieldLength.hashCode;
}
