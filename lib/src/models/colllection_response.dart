class CollectionResponse {
  final List<CollectionRequest> requests;

  CollectionResponse({required this.requests});

  factory CollectionResponse.fromJson(Map<String, dynamic> json) {
    return CollectionResponse(
      requests: (json['data']['requests'] as List)
          .map((e) => CollectionRequest.fromJson(e))
          .toList(),
    );
  }
}

class CollectionRequest {
  final String id;
  final bool isConsented;
  final Collection collection;

  CollectionRequest({
    required this.id,
    required this.isConsented,
    required this.collection,
  });

  factory CollectionRequest.fromJson(Map<String, dynamic> json) {
    return CollectionRequest(
      id: json['id'],
      isConsented: json['isConsented'],
      collection: Collection.fromJson(json['collection']),
    );
  }
}

class Collection {
  final String maxAmount;
  final String? expiryDate;
  final String? startDate;
  final String? monthlyLimit;
  final Schedule schedule;
  final String reference;
  final String status;
  final String? nextCollectionAt;

  Collection({
    required this.maxAmount,
    required this.expiryDate,
    required this.startDate,
    required this.monthlyLimit,
    required this.schedule,
    required this.reference,
    required this.status,
    required this.nextCollectionAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      maxAmount: json['maxAmount'],
      expiryDate: json['expiryDate'],
      startDate: json['startDate'],
      monthlyLimit: json['monthlyLimit'],
      schedule: Schedule.fromJson(json['schedule']),
      reference: json['reference'],
      status: json['status'],
      nextCollectionAt: json['nextCollectionAt'],
    );
  }
}

class Schedule {
  final String type; // SCHEDULED or SUBSCRIPTION
  final String? frequency; // Only for SUBSCRIPTION
  final String? amount; // Only for SUBSCRIPTION
  final List<ScheduleEntry> entries;

  Schedule({
    required this.type,
    this.frequency,
    this.amount,
    required this.entries,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      type: json['type'],
      frequency: json['frequency'],
      amount: json['amount'],
      entries: (json['entries'] as List)
          .map((e) => ScheduleEntry.fromJson(e))
          .toList(),
    );
  }
}

class ScheduleEntry {
  final String date;
  final String amount;

  ScheduleEntry({required this.date, required this.amount});

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      date: json['date'],
      amount: json['amount'],
    );
  }
}
