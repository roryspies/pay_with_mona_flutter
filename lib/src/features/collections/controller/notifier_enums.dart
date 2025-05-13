enum CollectionsState { idle, loading, success, error }

enum CollectionsMethod { none, subscription, scheduled }

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
