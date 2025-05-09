class ConfirmTransactionDbEventModel {
  ConfirmTransactionDbEventModel({
    required this.id,
    required this.eventType,
    required this.event,
    required this.transactionId,
    required this.timestamp,
    this.detail,
    this.redirect,
  });

  factory ConfirmTransactionDbEventModel.fromJSON({
    required String id,
    required Map<String, dynamic> json,
  }) {
    return ConfirmTransactionDbEventModel(
      id: id,
      eventType: json['eventType'] ?? '',
      event: json['event'] ?? '',
      transactionId: json['transactionId'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      detail: json['detail'],
      redirect: json['redirect'],
    );
  }

  factory ConfirmTransactionDbEventModel.init() {
    return ConfirmTransactionDbEventModel(
      id: "event_id",
      eventType: "payment_update",
      event: "transaction_initiated",
      transactionId: "transactionId",
      timestamp: 1739953644513,
    );
  }

  final String id;
  final String eventType;
  final String event;
  final String transactionId;
  final num timestamp;
  final String? detail;
  final String? redirect;

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'eventType': eventType,
      'event': event,
      'transactionId': transactionId,
      'timestamp': timestamp,
      if (detail != null) 'detail': detail,
      if (redirect != null) 'redirect': redirect,
    };
  }

  ConfirmTransactionDbEventModel copyWith({
    String? id,
    String? eventType,
    String? event,
    String? transactionId,
    num? timestamp,
    String? detail,
    String? redirect,
  }) {
    return ConfirmTransactionDbEventModel(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      event: event ?? this.event,
      transactionId: transactionId ?? this.transactionId,
      timestamp: timestamp ?? this.timestamp,
      detail: detail ?? this.detail,
      redirect: redirect ?? this.redirect,
    );
  }

  @override
  String toString() {
    return 'ConfirmTransactionDbEventModel(id: $id, eventType: $eventType, event: $event, transactionId: $transactionId, timestamp: $timestamp, detail: $detail, redirect: $redirect)';
  }
}
