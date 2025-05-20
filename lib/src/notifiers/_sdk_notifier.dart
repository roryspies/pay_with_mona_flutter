class _MonaSDKNotifier {
  _MonaSDKNotifier._();

  static final _MonaSDKNotifier _instance = _MonaSDKNotifier._();

  factory _MonaSDKNotifier() => _instance;

  static bool isInitialized = false;
}
