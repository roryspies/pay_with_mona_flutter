enum CollectionsState { idle, loading, success, error }

enum CollectionsMethod { none, subscription, scheduled }

List<CollectionsMethod> collectionMethods =
    CollectionsMethod.values.where((c) => c != CollectionsMethod.none).toList();
