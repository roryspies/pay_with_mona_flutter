enum CollectionsState { idle, loading, success, error }

enum CollectionsMethod { none, scheduled, subscription }

List<CollectionsMethod> collectionMethods =
    CollectionsMethod.values.where((c) => c != CollectionsMethod.none).toList();

enum SubscriptionFrequency {
  none,
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual
}

List<SubscriptionFrequency> subscriptionFrequencies = SubscriptionFrequency
    .values
    .where((c) => c != SubscriptionFrequency.none)
    .toList();

enum DebitType { none, merchant, mona }

List<DebitType> debitTypes =
    DebitType.values.where((c) => c != DebitType.none).toList();

enum TimeFactor {
  day,
  week,
  month,
}

List<TimeFactor> timeFactors = TimeFactor.values.toList();
