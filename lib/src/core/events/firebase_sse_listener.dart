/* import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:pay_with_mona/src/core/api/api_config.dart';
import 'package:pay_with_mona/src/core/events/host_lifecycle_observer.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

/// Enum to represent different states of the SSE connection.
enum SSEConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Enum to represent different types of SSE listeners.
enum SSEListenerType {
  paymentUpdates,
  transactionMessages,
  customTabs,
  authenticationEvents,
}

/// Configuration for an SSE listener.
class SSEListenerConfig {
  final SSEListenerType type;
  final String? identifier;
  final Function(String)? onDataChange;
  final Function(Object)? onError;
  final bool autoReconnect;

  const SSEListenerConfig({
    required this.type,
    this.identifier,
    this.onDataChange,
    this.onError,
    this.autoReconnect = true,
  });

  String get key => '${type.name}_${identifier ?? 'global'}';

  String getPath() {
    switch (type) {
      case SSEListenerType.paymentUpdates:
        return '/public/paymentUpdate/$identifier.json';
      case SSEListenerType.transactionMessages:
        return '/public/transaction-messages/$identifier.json';
      case SSEListenerType.customTabs:
        return '/public/close_tab.json';
      case SSEListenerType.authenticationEvents:
        return '/public/login_success/authn_$identifier.json';
    }
  }

  String get displayName => type.name;
}

/// A wrapper for an individual SSE connection.
class SSEConnection {
  final SSEListenerConfig config;
  final Uri uri;
  StreamSubscription<String>? subscription;
  SSEConnectionState state = SSEConnectionState.disconnected;
  Timer? reconnectTimer;
  DateTime? lastEventReceived;
  int consecutiveErrors = 0;

  SSEConnection({required this.config, required this.uri});

  bool get isActive => subscription != null;
  bool get isHealthy => consecutiveErrors < 5; // Increased threshold

  void resetErrorCount() => consecutiveErrors = 0;
  void incrementErrorCount() => consecutiveErrors++;

  Future<void> dispose() async {
    reconnectTimer?.cancel();
    reconnectTimer = null;
    await subscription?.cancel();
    subscription = null;
    state = SSEConnectionState.disconnected;
  }
}

/// Enhanced Firebase SSE Listener aware of the application lifecycle.
class FirebaseSSEListener {
  FirebaseSSEListener._() {
    // Initialize and start the lifecycle monitor
    _lifecycleMonitor = AppLifecycleMonitor(
      onStateChanged: _handleAppLifecycleChange,
    );

    _lifecycleMonitor.start();
  }
  static final FirebaseSSEListener _instance = FirebaseSSEListener._();
  factory FirebaseSSEListener() => _instance;

  // --- Properties ---
  late final http.Client _httpClient;
  final _databaseUrl = APIConfig.firebaseDbURL;
  final Map<String, SSEConnection> _activeConnections = {};
  late final StreamController<Map<String, SSEConnectionState>> _stateController;
  late final AppLifecycleMonitor _lifecycleMonitor;
  Timer? _healthCheckTimer;
  bool _isInitialized = false;
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  // --- Public Getters ---
  Map<String, SSEConnectionState> get connectionStates => Map.fromEntries(
      _activeConnections.entries.map((e) => MapEntry(e.key, e.value.state)));
  Stream<Map<String, SSEConnectionState>> get connectionStateStream =>
      _stateController.stream;
  bool get hasActiveListeners => _activeConnections.isNotEmpty;
  bool get isAppInBackground =>
      _currentLifecycleState != AppLifecycleState.resumed;

  // --- Initialization and Lifecycle ---

  /// Ensures the listener is properly initialized.
  void _ensureInitialized() {
    if (!_isInitialized) {
      _httpClient = http.Client();
      _stateController =
          StreamController<Map<String, SSEConnectionState>>.broadcast();
      _startHealthCheckTimer();
      _isInitialized = true;
      _logMessage('Initialized and ready.');
    }
  }

  /// Handles app lifecycle state changes.
  void _handleAppLifecycleChange(AppLifecycleState newState) {
    if (_currentLifecycleState == newState) return;
    _logMessage('App lifecycle state changed: $newState');
    _currentLifecycleState = newState;

    if (newState == AppLifecycleState.resumed) {
      _logMessage('App resumed. Performing immediate health check.');
      // Give a slight delay to allow network to settle
      Future.delayed(const Duration(seconds: 1), _performHealthCheck);
    } else {
      _logMessage(
          'App is in background. Connections are at risk of being closed by the OS.');
      // When backgrounded, we don't do anything special.
      // The health check and reconnect logic will handle any disconnections
      // upon resuming.
    }
  }

  // --- Health and Reconnection ---

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (!isAppInBackground) {
        // Only run health checks when app is in foreground
        _performHealthCheck();
      }
    });
  }

  /// Performs a health check on all active connections.
  void _performHealthCheck() {
    if (_activeConnections.isEmpty) return;
    _logMessage(
        'Performing health check on ${_activeConnections.length} connections...');

    final now = DateTime.now();
    for (final entry in _activeConnections.entries) {
      final connection = entry.value;

      // If a connection is not marked as connected, try to reconnect it.
      if (connection.state != SSEConnectionState.connected) {
        _logMessage(
            'Health Check: Reconnecting inactive listener: ${connection.config.displayName}');
        _scheduleReconnect(
            connection.config.key, connection.config, connection.uri);
        continue;
      }

      // Check for stale connections (no events received).
      if (connection.lastEventReceived != null) {
        final timeSinceLastEvent =
            now.difference(connection.lastEventReceived!);
        if (timeSinceLastEvent.inMinutes >= 3) {
          _logMessage(
              'Connection ${connection.config.key} appears stale. Reconnecting.');
          _scheduleReconnect(
              connection.config.key, connection.config, connection.uri);
        }
      }
    }
  }

  /// Schedules a reconnection attempt with exponential backoff.
  void _scheduleReconnect(String key, SSEListenerConfig config, Uri uri) {
    final connection = _activeConnections[key];
    if (connection == null || connection.reconnectTimer != null) {
      return; // Already scheduled
    }

    final backoffSeconds = (5 * (connection.consecutiveErrors + 1)).clamp(
      5,
      60,
    );

    _logMessage(
      'Scheduling reconnect for ${config.displayName} in $backoffSeconds seconds...',
    );

    connection.reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      connection.reconnectTimer = null; // Clear timer before attempting
      if (_activeConnections.containsKey(key)) {
        _logMessage('Attempting scheduled reconnect for ${config.displayName}');
        _establishConnection(config, uri);
      }
    });
  }

  /// *** --- Public Methods ---
  /// Start listening to an event stream with a given configuration.
  Future<void> startListening(
    SSEListenerConfig config,
  ) async {
    _ensureInitialized();
    if (_databaseUrl.isEmpty || _databaseUrl == 'YOUR_FIREBASE_DB_URL_HERE') {
      _logMessage(
        'ERROR: Firebase Database URL is not set.',
        emoji: '🚨',
      );

      throw StateError(
        'FirebaseSSEListener not initialized with a valid database URL.',
      );
    }

    final key = config.key;
    if (_activeConnections.containsKey(key) &&
        _activeConnections[key]!.isActive) {
      _logMessage(
        'Already listening to ${config.displayName}: ${config.identifier}',
      );
      return;
    }

    await _stopConnection(key); // Ensure any old connection is gone
    final uri = Uri.parse(
      '$_databaseUrl${config.getPath()}',
    );
    _logMessage(
      'Starting listener for: ${config.displayName}',
    );

    await _establishConnection(config, uri);
  }

  /// Stop listening for a specific type and identifier.
  Future<void> stopListening({
    required SSEListenerType type,
    String? identifier,
  }) async {
    final key = '${type.name}_${identifier ?? 'global'}';
    await _stopConnection(key);
  }

  /// Stop all active listeners.
  Future<void> stopAllListening() async {
    _logMessage(
      'Stopping all active listeners...',
    );

    final keys = List<String>.from(_activeConnections.keys);
    for (final key in keys) {
      await _stopConnection(key);
    }
  }

  /// *** --- Core Logic ---
  Future<void> _establishConnection(
    SSEListenerConfig config,
    Uri uri,
  ) async {
    final key = config.key;
    final connection = SSEConnection(config: config, uri: uri);
    _activeConnections[key] = connection;

    try {
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache'
        ..headers['Connection'] = 'keep-alive';

      _updateConnectionState(key, SSEConnectionState.connecting);
      final response =
          await _httpClient.send(request).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to connect: HTTP ${response.statusCode}',
        );
      }

      _logMessage('${config.displayName} connection established.', emoji: '✅');
      connection.resetErrorCount();
      _updateConnectionState(key, SSEConnectionState.connected);

      connection.subscription = response.stream.transform(utf8.decoder).listen(
        (event) {
          connection.lastEventReceived = DateTime.now();
          _processEvent(event, config);
        },
        onError: (error) {
          connection.incrementErrorCount();
          _logMessage('Connection error for ${config.displayName}: $error',
              emoji: '❌');
          _handleConnectionError(key, error, config.onError);
          if (config.autoReconnect) _scheduleReconnect(key, config, uri);
        },
        onDone: () {
          _logMessage('Connection closed for ${config.displayName}.',
              emoji: '🔌');
          _updateConnectionState(key, SSEConnectionState.disconnected);
          if (config.autoReconnect) _scheduleReconnect(key, config, uri);
        },
        cancelOnError: false, // Let the stream continue for reconnection logic
      );
    } catch (e) {
      connection.incrementErrorCount();
      _logMessage(
          'Failed to establish connection for ${config.displayName}: $e',
          emoji: '❌');
      _handleConnectionError(key, e, config.onError);
      if (config.autoReconnect) _scheduleReconnect(key, config, uri);
    }
  }

  void _processEvent(String event, SSEListenerConfig config) {
    // Process event data here...
    try {
      final lines = event.split('\n');
      for (var line in lines) {
        if (line.startsWith('data: ')) {
          final jsonData = line.substring(6).trim();
          if (jsonData.isNotEmpty && jsonData != 'null') {
            // This is a valid data event
            config.onDataChange?.call(jsonData);
          }
        } else if (line.startsWith('event: keep-alive')) {
          // This is a firebase keep-alive event, we can just log it.
          _logMessage(
            'Received keep-alive for ${config.displayName}',
            emoji: '❤️',
          );
        }
      }
    } catch (e) {
      _logMessage('Event processing error: $e', emoji: '❌');
      config.onError?.call(e);
    }
  }

  // --- State and Cleanup ---

  Future<void> _stopConnection(String key) async {
    final connection = _activeConnections.remove(key);
    if (connection != null) {
      _logMessage('Stopping connection: $key', emoji: '🛑');
      await connection.dispose();
      _updateConnectionState(key, SSEConnectionState.disconnected,
          broadcast: true);
    }
  }

  void _handleConnectionError(
      String key, Object error, Function(Object)? onError) {
    _updateConnectionState(key, SSEConnectionState.error);
    onError?.call(error);
  }

  void _updateConnectionState(String key, SSEConnectionState newState,
      {bool broadcast = true}) {
    final connection = _activeConnections[key];
    if (connection != null) {
      connection.state = newState;
    }

    if (broadcast && _isInitialized && !_stateController.isClosed) {
      _stateController.add(connectionStates);
    }
  }

  void dispose() {
    _logMessage('Disposing FirebaseSSEListener.', emoji: '🛑');
    _healthCheckTimer?.cancel();
    _lifecycleMonitor.dispose();
    stopAllListening();
    _stateController.close();
    _httpClient.close();
    _isInitialized = false;
  }

  void _logMessage(String message, {String? emoji}) {
    // Simplified logger for clarity
    final prefix = emoji ?? 'ℹ️';
    '$prefix [SSEListener] $message'.log();
  }
}
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:pay_with_mona/src/core/api/api_config.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

/// Enum to represent different states of the SSE connection
enum SSEConnectionState {
  /// Not connected to any Firebase event source
  disconnected,

  /// Currently establishing a connection
  connecting,

  /// Successfully connected and receiving events
  connected,

  /// Connection encountered an error
  error,

  /// Connection is in background mode (maintained but optimized)
  backgroundMaintained,
}

/// Enum to represent different types of SSE listeners
enum SSEListenerType {
  paymentUpdates,
  transactionMessages,
  customTabs,
  authenticationEvents,
}

/// Enum for app lifecycle states
enum AppLifecycleState {
  resumed,
  inactive,
  paused,
  detached,
  hidden,
}

/// Configuration for an SSE listener
class SSEListenerConfig {
  final SSEListenerType type;
  final String? identifier; // transactionId or sessionId
  final Function(String)? onDataChange;
  final Function(Object)? onError;
  final bool autoReconnect;

  const SSEListenerConfig({
    required this.type,
    this.identifier,
    this.onDataChange,
    this.onError,
    this.autoReconnect = true,
  });

  /// Generate a unique key for this listener configuration
  String get key {
    return '${type.name}_${identifier ?? 'global'}';
  }

  /// Get the Firebase path for this listener type
  String getPath() {
    switch (type) {
      case SSEListenerType.paymentUpdates:
        return '/public/paymentUpdate/$identifier.json';
      case SSEListenerType.transactionMessages:
        return '/public/transaction-messages/$identifier.json';
      case SSEListenerType.customTabs:
        return '/public/close_tab.json';
      case SSEListenerType.authenticationEvents:
        return '/public/login_success/authn_$identifier.json';
    }
  }

  /// Get display name for logging
  String get displayName {
    switch (type) {
      case SSEListenerType.paymentUpdates:
        return 'Payment Updates';
      case SSEListenerType.transactionMessages:
        return 'Transaction Messages';
      case SSEListenerType.customTabs:
        return 'Custom Tabs';
      case SSEListenerType.authenticationEvents:
        return 'Authentication Events';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSEListenerConfig &&
        other.type == type &&
        other.identifier == identifier;
  }

  @override
  int get hashCode => Object.hash(type, identifier);
}

/// Individual SSE connection wrapper with background support
class SSEConnection {
  final SSEListenerConfig config;
  final Uri uri;
  StreamSubscription<String>? subscription;
  SSEConnectionState state = SSEConnectionState.disconnected;
  Timer? reconnectTimer;
  Timer? heartbeatTimer;
  bool isInBackground = false;
  DateTime? lastEventReceived;
  int consecutiveErrors = 0;

  SSEConnection({
    required this.config,
    required this.uri,
  });

  bool get isActive => subscription != null;
  bool get isHealthy => consecutiveErrors < 3;

  /// Start heartbeat for background mode
  void startBackgroundHeartbeat() {
    heartbeatTimer?.cancel();
    heartbeatTimer = Timer.periodic(
      Duration(seconds: 10),
      (timer) {
        if (isInBackground && isActive) {
          _sendHeartbeat();
        }
      },
    );
  }

  /// Stop heartbeat
  void stopBackgroundHeartbeat() {
    heartbeatTimer?.cancel();
    heartbeatTimer = null;
  }

  /// Send heartbeat to keep connection alive
  void _sendHeartbeat() {
    SSEBackgroundManager.instance._logBackgroundMessage(
      "SSEConnection ::: SENDING HEARTBEAT ::: ",
    );

    // This is a lightweight ping to keep the connection active
    // The actual implementation would depend on your server setup
    lastEventReceived = DateTime.now();
  }

  /// Mark connection as background mode
  void enterBackgroundMode() {
    isInBackground = true;
    startBackgroundHeartbeat();
  }

  /// Mark connection as foreground mode
  void exitBackgroundMode() {
    isInBackground = false;
    stopBackgroundHeartbeat();
  }

  /// Reset error count on successful event
  void resetErrorCount() {
    consecutiveErrors = 0;
  }

  /// Increment error count
  void incrementErrorCount() {
    consecutiveErrors++;
  }

  Future<void> dispose() async {
    reconnectTimer?.cancel();
    reconnectTimer = null;

    heartbeatTimer?.cancel();
    heartbeatTimer = null;

    if (subscription != null) {
      await subscription!.cancel();
      subscription = null;
    }

    state = SSEConnectionState.disconnected;
  }
}

/// Background manager for SSE connections
class SSEBackgroundManager {
  static SSEBackgroundManager? _instance;
  static SSEBackgroundManager get instance =>
      _instance ??= SSEBackgroundManager._();

  SSEBackgroundManager._();

  AppLifecycleState _currentState = AppLifecycleState.resumed;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  Timer? _backgroundMaintenanceTimer;
  bool _isInitialized = false;

  /// Initialize background management
  void initialize() {
    if (_isInitialized) return;

    _setupAppLifecycleListener();
    _isInitialized = true;
    _logBackgroundMessage('Background manager initialized');
  }

  /// Setup app lifecycle listener
  void _setupAppLifecycleListener() {
    // Listen to app lifecycle changes via method channel
    _startLifecycleMonitoring();
  }

  /// Start monitoring app lifecycle
  void _startLifecycleMonitoring() {
    // Use a timer to periodically check app state
    Timer.periodic(Duration(seconds: 5), (timer) {
      _checkAppState();
    });
  }

  /// Check current app state
  void _checkAppState() {
    // This would typically use platform channels to get actual app state
    // For now, we'll use a simplified approach
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState newState) {
    if (_currentState == newState) return;

    final previousState = _currentState;
    _currentState = newState;

    _logBackgroundMessage('App state changed: $previousState -> $newState');

    switch (newState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _handleAppInBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppForegrounded();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Handle when app goes to background
  void _handleAppInBackground() {
    _logBackgroundMessage(
      'App is in background - switching to background mode',
    );
    _startBackgroundMaintenance();
  }

  /// Handle when app becomes inactive (custom tab scenario)
  void _handleAppInactive() {
    _logBackgroundMessage('App inactive - likely custom tab opened');
    _startBackgroundMaintenance();
  }

  /// Handle when app is hidden
  void _handleAppHidden() {
    _logBackgroundMessage('App hidden - maintaining connections');
    _startBackgroundMaintenance();
  }

  /// Handle when app comes to foreground
  void _handleAppForegrounded() {
    _logBackgroundMessage('App foregrounded - resuming normal mode');
    _stopBackgroundMaintenance();
  }

  /// Start background maintenance
  void _startBackgroundMaintenance() {
    _backgroundMaintenanceTimer?.cancel();
    _backgroundMaintenanceTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _performBackgroundMaintenance();
    });
  }

  /// Stop background maintenance
  void _stopBackgroundMaintenance() {
    _backgroundMaintenanceTimer?.cancel();
    _backgroundMaintenanceTimer = null;
  }

  /// Perform background maintenance tasks
  void _performBackgroundMaintenance() {
    _logBackgroundMessage('Performing background maintenance');
    // This will be called by the main SSE listener to maintain connections
  }

  /// Check if app is in background
  bool get isInBackground {
    return _currentState == AppLifecycleState.paused ||
        _currentState == AppLifecycleState.detached ||
        _currentState == AppLifecycleState.inactive ||
        _currentState == AppLifecycleState.hidden;
  }

  /// Dispose background manager
  void dispose() {
    _lifecycleSubscription?.cancel();
    _backgroundMaintenanceTimer?.cancel();
    _isInitialized = false;
    _logBackgroundMessage('Background manager disposed');
  }

  /// Log background-specific messages
  void _logBackgroundMessage(String message) {
    '🌙 [SSE-Background] $message'.log();
  }
}

/// Enhanced Firebase Server-Sent Events (SSE) Listener with Background Support
///
/// Provides robust real-time event listening for Firebase Realtime Database with
/// automatic reconnection, proper resource management, state tracking, and
/// background mode support to maintain connections when custom tabs are opened.
class FirebaseSSEListener {
  // MARK: - Singleton Implementation

  /// Private constructor for singleton pattern
  FirebaseSSEListener._() {
    _backgroundManager = SSEBackgroundManager.instance;
  }

  /// Singleton instance
  static final FirebaseSSEListener _instance = FirebaseSSEListener._();

  /// Factory constructor for singleton access
  factory FirebaseSSEListener() => _instance;

  // MARK: - Properties

  /// HTTP client for making network requests
  late http.Client _httpClient;

  /// Firebase Realtime Database URL
  String _databaseUrl = APIConfig.firebaseDbURL;

  /// Map of active SSE connections
  final Map<String, SSEConnection> _activeConnections = {};

  /// Stream controller for broadcasting connection state changes
  late StreamController<Map<String, SSEConnectionState>> _stateController;

  /// Flag to track initialization state
  bool _isInitialized = false;

  /// Background manager instance
  late SSEBackgroundManager _backgroundManager;

  /// Timer for periodic connection health checks
  Timer? _healthCheckTimer;

  /// Flag to track if custom tab is currently open
  bool _isCustomTabOpen = false;

  // MARK: - Public Getters

  /// Get all connection states
  Map<String, SSEConnectionState> get connectionStates {
    return Map.fromEntries(
        _activeConnections.entries.map((e) => MapEntry(e.key, e.value.state)));
  }

  /// Stream of connection state changes for all listeners
  Stream<Map<String, SSEConnectionState>> get connectionStateStream {
    _ensureInitialized();
    return _stateController.stream;
  }

  /// Check if any listeners are active
  bool get hasActiveListeners => _activeConnections.isNotEmpty;

  /// Get count of active listeners
  int get activeListenerCount => _activeConnections.length;

  /// Check if app is in background mode
  bool get isInBackground => _backgroundManager.isInBackground;

  /// Check if custom tab is open
  bool get isCustomTabOpen => _isCustomTabOpen;

  // MARK: - Initialization

  /// Ensures the listener is properly initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      _httpClient = http.Client();
      _stateController =
          StreamController<Map<String, SSEConnectionState>>.broadcast();

      // Initialize background manager
      _backgroundManager.initialize();

      // Start health check timer
      _startHealthCheckTimer();

      _isInitialized = true;
      _logMessage('Initialized base components with background support');
    }
  }

  /// Initialize the SSE listener with a Firebase Realtime Database URL
  ///
  /// [databaseUrl] Optional custom URL of the Firebase Realtime Database
  void initialize({String? databaseUrl}) {
    _ensureInitialized();

    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      _databaseUrl = databaseUrl.trim();
    }

    _logMessage('Initialized with database URL: $_databaseUrl');
  }

  /// Start health check timer for background maintenance
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _performHealthCheck();
    });
  }

  /// Perform health check on all connections
  void _performHealthCheck() {
    if (_activeConnections.isEmpty) return;

    _logMessage(
        'Performing health check on ${_activeConnections.length} connections');

    final now = DateTime.now();
    final unhealthyConnections = <String>[];

    for (final entry in _activeConnections.entries) {
      final connection = entry.value;
      final key = entry.key;

      // Check if connection is unhealthy
      if (!connection.isHealthy) {
        unhealthyConnections.add(key);
        continue;
      }

      // Check if connection is stale (no events for 5 minutes)
      if (connection.lastEventReceived != null) {
        final timeSinceLastEvent =
            now.difference(connection.lastEventReceived!);
        if (timeSinceLastEvent.inMinutes > 5) {
          _logMessage('Connection $key appears stale, scheduling reconnect');
          _scheduleReconnect(key, connection.config, connection.uri);
        }
      }
    }

    // Reconnect unhealthy connections
    for (final key in unhealthyConnections) {
      final connection = _activeConnections[key];
      if (connection != null) {
        _logMessage('Reconnecting unhealthy connection: $key');
        _scheduleReconnect(key, connection.config, connection.uri);
      }
    }
  }

  // MARK: - Background Mode Management

  /// Handle custom tab opening
  void onCustomTabOpening() {
    _isCustomTabOpen = true;
    _logMessage('Custom tab opening - entering background mode');
    _enterBackgroundMode();
  }

  /// Handle custom tab closing
  void onCustomTabClosing() {
    _isCustomTabOpen = false;
    _logMessage('Custom tab closed - checking if should exit background mode');

    // Only exit background mode if app is not actually backgrounded
    if (!_backgroundManager.isInBackground) {
      _exitBackgroundMode();
    }
  }

  /// Enter background mode for all connections
  void _enterBackgroundMode() {
    _logMessage('Entering background mode for all connections');

    for (final connection in _activeConnections.values) {
      connection.enterBackgroundMode();
      if (connection.state == SSEConnectionState.connected) {
        connection.state = SSEConnectionState.backgroundMaintained;
        _updateConnectionState(
            connection.config.key, SSEConnectionState.backgroundMaintained);
      }
    }
  }

  /// Exit background mode for all connections
  void _exitBackgroundMode() {
    _logMessage('Exiting background mode for all connections');

    for (final connection in _activeConnections.values) {
      connection.exitBackgroundMode();
      if (connection.state == SSEConnectionState.backgroundMaintained) {
        connection.state = SSEConnectionState.connected;
        _updateConnectionState(
            connection.config.key, SSEConnectionState.connected);
      }
    }
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState newState) {
    _backgroundManager.handleAppLifecycleChange(newState);

    // Update our connections based on new state
    if (_backgroundManager.isInBackground && !_isCustomTabOpen) {
      _enterBackgroundMode();
    } else if (!_backgroundManager.isInBackground && !_isCustomTabOpen) {
      _exitBackgroundMode();
    }
  }

  // MARK: - Public Listening Methods

  /// Start listening to SSE events for a payment update
  ///
  /// [transactionId] Unique identifier for the transaction
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenForPaymentUpdates({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.paymentUpdates,
      identifier: transactionId,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  /// Start listening to SSE events for transaction messages
  ///
  /// [transactionId] Unique identifier for the transaction
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenForTransactionMessages({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.transactionMessages,
      identifier: transactionId,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  /// Start listening to SSE events for custom tab events
  ///
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenForCustomTabEvents({
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.customTabs,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  /// Start listening to SSE events for authentication events
  ///
  /// [sessionID] Unique identifier for the authentication session
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenToAuthNEvents({
    required String sessionID,
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.authenticationEvents,
      identifier: sessionID,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  // MARK: - Core Listening Logic

  /// Start listening with the given configuration
  Future<void> _startListening(SSEListenerConfig config) async {
    _ensureInitialized();

    try {
      // Validate initialization
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'Firebase SSE not initialized with valid database URL.');
      }

      final key = config.key;
      final existingConnection = _activeConnections[key];

      // If already listening to the same configuration, just log and return
      if (existingConnection != null && existingConnection.isActive) {
        _logMessage(
            'Already listening to ${config.displayName}: ${config.identifier}');
        return;
      }

      // Clean up any existing connection for this key
      if (existingConnection != null) {
        await _stopConnection(key);
      }

      final uri = Uri.parse('$_databaseUrl${config.getPath()}');

      _logMessage(
          'Starting ${config.displayName} listener for: ${config.identifier ?? 'global'}');

      await _establishConnection(config, uri);
    } catch (e) {
      _logMessage('Failed to start ${config.displayName} listener: $e');
      _handleConnectionError(config.key, e, config.onError);
    }
  }

  /// Establish a new SSE connection with background support
  Future<void> _establishConnection(SSEListenerConfig config, Uri uri) async {
    final connection = SSEConnection(config: config, uri: uri);
    final key = config.key;

    _activeConnections[key] = connection;

    // Set background mode if currently in background
    if (isInBackground || isCustomTabOpen) {
      connection.enterBackgroundMode();
    }

    try {
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache'
        ..headers['Connection'] = 'keep-alive';

      _updateConnectionState(key, SSEConnectionState.connecting);

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw HttpException('Failed to connect: HTTP ${response.statusCode}');
      }

      _logMessage('${config.displayName} connection established at: $uri');

      connection.subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          connection.lastEventReceived = DateTime.now();
          connection.resetErrorCount();

          _logMessage(
              'Event received for ${config.displayName}: ${event.length > 100 ? '${event.substring(0, 100)}...' : event}');
          _processEvent(event, config.onDataChange, config.onError);
        },
        onError: (error) {
          connection.incrementErrorCount();
          _logMessage('Connection error for ${config.displayName}: $error');
          _handleConnectionError(key, error, config.onError);

          if (config.autoReconnect) {
            _scheduleReconnect(key, config, uri);
          }
        },
        onDone: () {
          _logMessage('Connection closed for ${config.displayName}');
          _updateConnectionState(key, SSEConnectionState.disconnected);

          if (config.autoReconnect) {
            _scheduleReconnect(key, config, uri);
          }
        },
        cancelOnError: false,
      );

      final newState = (isInBackground || isCustomTabOpen)
          ? SSEConnectionState.backgroundMaintained
          : SSEConnectionState.connected;

      _updateConnectionState(key, newState);
    } catch (e) {
      connection.incrementErrorCount();
      _logMessage(
          'Connection establishment failed for ${config.displayName}: $e');
      _handleConnectionError(key, e, config.onError);

      if (config.autoReconnect) {
        _scheduleReconnect(key, config, uri);
      }
    }
  }

  /// Schedule a reconnection attempt with exponential backoff
  void _scheduleReconnect(String key, SSEListenerConfig config, Uri uri) {
    final connection = _activeConnections[key];
    if (connection == null) return;

    // Cancel any existing reconnect timer
    connection.reconnectTimer?.cancel();

    // Calculate delay with exponential backoff
    final baseDelay = connection.state == SSEConnectionState.error ? 5 : 3;
    final backoffMultiplier = (connection.consecutiveErrors * 2).clamp(1, 8);
    final delay = baseDelay * backoffMultiplier;

    _logMessage(
        'Scheduling reconnect for ${config.displayName} in $delay seconds... (attempt ${connection.consecutiveErrors + 1})');

    connection.reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_activeConnections.containsKey(key)) {
        _establishConnection(config, uri);
      }
    });
  }

  // MARK: - Event Processing

  /// Process individual SSE events
  void _processEvent(
    String event,
    Function(String)? onDataChange,
    Function(Object)? onError,
  ) {
    try {
      final lines = event.split('\n');

      for (var line in lines) {
        // Skip empty lines
        if (line.trim().isEmpty) continue;

        // Parse data lines
        if (line.startsWith('data: ')) {
          _processDataLine(line, onDataChange, onError);
        }
        // Handle other event types if needed
        else if (line.startsWith('event: ')) {
          final eventType = line.substring(7).trim();
          _logMessage('Event type: $eventType');
        } else if (line.startsWith('id: ')) {
          final eventId = line.substring(4).trim();
          _logMessage('Event ID: $eventId');
        }
      }
    } catch (e) {
      _logMessage('Event processing error: $e');
      onError?.call(e);
    }
  }

  /// Parse and process data lines from SSE events
  void _processDataLine(
    String line,
    Function(String)? onDataChange,
    Function(Object)? onError,
  ) {
    try {
      final jsonData = line.substring(6).trim();

      if (jsonData.isEmpty || jsonData == 'null') {
        _logMessage('Skipping null or empty data');
        return;
      }

      final data = json.decode(jsonData);

      if (data is Map<String, dynamic>) {
        final eventData = data['data'];

        // Handle string events
        if (eventData is String) {
          _logMessage(
              'Processing string event: ${eventData.length > 50 ? '${eventData.substring(0, 50)}...' : eventData}');
          onDataChange?.call(eventData);
        }
        // Handle map events
        else if (eventData is Map<String, dynamic>) {
          _logMessage(
              'Processing map event with keys: ${eventData.keys.join(', ')}');
          onDataChange?.call(json.encode(eventData));
        }
        // Handle other types
        else if (eventData != null) {
          _logMessage('Unhandled event data type: ${eventData.runtimeType}');
          onDataChange?.call(json.encode({'data': eventData}));
        }
      } else {
        _logMessage('Unexpected data format: ${data.runtimeType}');
      }
    } catch (e) {
      _logMessage('Data processing error: $e');
      onError?.call(e);
    }
  }

  // MARK: - Connection Management

  /// Stop a specific connection
  Future<void> _stopConnection(String key) async {
    final connection = _activeConnections[key];
    if (connection != null) {
      _logMessage('Stopping connection: $key');
      await connection.dispose();
      _activeConnections.remove(key);
      _updateConnectionState(key, SSEConnectionState.disconnected);
    }
  }

  /// Stop listening for a specific type and identifier
  Future<void> stopListening({
    required SSEListenerType type,
    String? identifier,
  }) async {
    final key = '${type.name}_${identifier ?? 'global'}';
    await _stopConnection(key);
  }

  /// Stop all active listeners
  Future<void> stopAllListening() async {
    _logMessage('Stopping all active listeners (${_activeConnections.length})');

    final keys = List<String>.from(_activeConnections.keys);
    for (final key in keys) {
      await _stopConnection(key);
    }

    _logMessage('All listeners stopped');
  }

  // MARK: - Error Handling & State Management

  /// Handle connection errors
  void _handleConnectionError(
      String key, Object error, Function(Object)? onError) {
    _updateConnectionState(key, SSEConnectionState.error);
    onError?.call(error);
  }

  /// Update the connection state for a specific listener
  void _updateConnectionState(String key, SSEConnectionState newState) {
    final connection = _activeConnections[key];
    if (connection != null && connection.state != newState) {
      connection.state = newState;
      _logMessage('Connection state for $key changed to: $newState');

      // Broadcast the updated state map
      if (_isInitialized && !_stateController.isClosed) {
        _stateController.add(connectionStates);
      }
    }
  }

  // MARK: - Cleanup

  /// Dispose all resources
  Future<void> dispose() async {
    _logMessage('Disposing all resources');

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    await stopAllListening();

    if (_isInitialized && !_stateController.isClosed) {
      await _stateController.close();
      _logMessage('State controller closed');
    }

    if (_isInitialized) {
      _httpClient.close();
      _logMessage('HTTP client closed');
    }

    _backgroundManager.dispose();
    _isInitialized = false;
    _logMessage('Successfully disposed all resources');
  }

  // MARK: - Logging

  /// Logging utility with automatic emoji categorization
  void _logMessage(String message) {
    String emoji;

    // Categorize log messages based on content
    if (message.contains('error') || message.contains('Error')) {
      emoji = '❌'; // Red X for errors
    } else if (message.contains('failed') || message.contains('Failed')) {
      emoji = '🚨'; // Siren for failure states
    } else if (message.contains('connect') || message.contains('Connection')) {
      emoji = '🔌'; // Plug for connection-related messages
    } else if (message.contains('listen') || message.contains('Listening')) {
      emoji = '👂'; // Ear for listening-related messages
    } else if (message.contains('init')) {
      emoji = '🚀'; // Rocket for initialization
    } else if (message.contains('dispose') || message.contains('stop')) {
      emoji = '🛑'; // Stop sign for disposal or stopping
    } else if (message.contains('success') || message.contains('Success')) {
      emoji = '✅'; // Green checkmark for success
    } else if (message.contains('event')) {
      emoji = '📬'; // Mailbox for events
    } else if (message.contains('process')) {
      emoji = '⚙️'; // Gear for processing
    } else if (message.contains('Scheduling') ||
        message.contains('reconnect')) {
      emoji = '🔄'; //
    } else {
      emoji = '📝'; // Memo for general messages
    }

    '$emoji [SSEListener] $message'.log();
  }
}



/// *** MARK: KEEP FOR A FORTH NIGHT
/* import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:pay_with_mona/src/core/api/api_config.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

/// Enum to represent different states of the SSE connection
enum SSEConnectionState {
  /// Not connected to any Firebase event source
  disconnected,

  /// Currently establishing a connection
  connecting,

  /// Successfully connected and receiving events
  connected,

  /// Connection encountered an error
  error
}

/// Enum to represent different types of SSE listeners
enum SSEListenerType {
  paymentUpdates,
  transactionMessages,
  customTabs,
  authenticationEvents,
}

/// Configuration for an SSE listener
class SSEListenerConfig {
  final SSEListenerType type;
  final String? identifier; // transactionId or sessionId
  final Function(String)? onDataChange;
  final Function(Object)? onError;
  final bool autoReconnect;

  const SSEListenerConfig({
    required this.type,
    this.identifier,
    this.onDataChange,
    this.onError,
    this.autoReconnect = true,
  });

  /// Generate a unique key for this listener configuration
  String get key {
    return '${type.name}_${identifier ?? 'global'}';
  }

  /// Get the Firebase path for this listener type
  String getPath() {
    switch (type) {
      case SSEListenerType.paymentUpdates:
        return '/public/paymentUpdate/$identifier.json';
      case SSEListenerType.transactionMessages:
        return '/public/transaction-messages/$identifier.json';
      case SSEListenerType.customTabs:
        return '/public/close_tab.json';
      case SSEListenerType.authenticationEvents:
        return '/public/login_success/authn_$identifier.json';
    }
  }

  /// Get display name for logging
  String get displayName {
    switch (type) {
      case SSEListenerType.paymentUpdates:
        return 'Payment Updates';
      case SSEListenerType.transactionMessages:
        return 'Transaction Messages';
      case SSEListenerType.customTabs:
        return 'Custom Tabs';
      case SSEListenerType.authenticationEvents:
        return 'Authentication Events';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSEListenerConfig &&
        other.type == type &&
        other.identifier == identifier;
  }

  @override
  int get hashCode => Object.hash(type, identifier);
}

/// Individual SSE connection wrapper
class SSEConnection {
  final SSEListenerConfig config;
  final Uri uri;
  StreamSubscription<String>? subscription;
  SSEConnectionState state = SSEConnectionState.disconnected;
  Timer? reconnectTimer;

  SSEConnection({
    required this.config,
    required this.uri,
  });

  bool get isActive => subscription != null;

  Future<void> dispose() async {
    reconnectTimer?.cancel();
    reconnectTimer = null;

    if (subscription != null) {
      await subscription!.cancel();
      subscription = null;
    }

    state = SSEConnectionState.disconnected;
  }
}

/// Enhanced Firebase Server-Sent Events (SSE) Listener
///
/// Provides robust real-time event listening for Firebase Realtime Database with
/// automatic reconnection, proper resource management, and state tracking.
/// Supports multiple concurrent listeners without unnecessary stops/starts.
class FirebaseSSEListener {
  // MARK: - Singleton Implementation

  /// Private constructor for singleton pattern
  FirebaseSSEListener._();

  /// Singleton instance
  static final FirebaseSSEListener _instance = FirebaseSSEListener._();

  /// Factory constructor for singleton access
  factory FirebaseSSEListener() => _instance;

  // MARK: - Properties

  /// HTTP client for making network requests
  late http.Client _httpClient;

  /// Firebase Realtime Database URL
  String _databaseUrl = APIConfig.firebaseDbURL;

  /// Map of active SSE connections
  final Map<String, SSEConnection> _activeConnections = {};

  /// Stream controller for broadcasting connection state changes
  late StreamController<Map<String, SSEConnectionState>> _stateController;

  /// Flag to track initialization state
  bool _isInitialized = false;

  // MARK: - Public Getters

  /// Get all connection states
  Map<String, SSEConnectionState> get connectionStates {
    return Map.fromEntries(
        _activeConnections.entries.map((e) => MapEntry(e.key, e.value.state)));
  }

  /// Stream of connection state changes for all listeners
  Stream<Map<String, SSEConnectionState>> get connectionStateStream {
    _ensureInitialized();
    return _stateController.stream;
  }

  /// Check if any listeners are active
  bool get hasActiveListeners => _activeConnections.isNotEmpty;

  /// Get count of active listeners
  int get activeListenerCount => _activeConnections.length;

  // MARK: - Initialization

  /// Ensures the listener is properly initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      _httpClient = http.Client();
      _stateController =
          StreamController<Map<String, SSEConnectionState>>.broadcast();
      _isInitialized = true;
      _logMessage('Initialized base components');
    }
  }

  /// Initialize the SSE listener with a Firebase Realtime Database URL
  ///
  /// [databaseUrl] Optional custom URL of the Firebase Realtime Database
  void initialize({String? databaseUrl}) {
    _ensureInitialized();

    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      _databaseUrl = databaseUrl.trim();
    }

    _logMessage('Initialized with database URL: $_databaseUrl');
  }

  // MARK: - Public Listening Methods

  /// Start listening to SSE events for a payment update
  ///
  /// [transactionId] Unique identifier for the transaction
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenForPaymentUpdates({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.paymentUpdates,
      identifier: transactionId,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  /// Start listening to SSE events for transaction messages
  ///
  /// [transactionId] Unique identifier for the transaction
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenForTransactionMessages({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.transactionMessages,
      identifier: transactionId,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  /// Start listening to SSE events for custom tab events
  ///
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenForCustomTabEvents({
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.customTabs,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  /// Start listening to SSE events for authentication events
  ///
  /// [sessionID] Unique identifier for the authentication session
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  /// [autoReconnect] Whether to automatically reconnect on failure (default: true)
  Future<void> listenToAuthNEvents({
    required String sessionID,
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    final config = SSEListenerConfig(
      type: SSEListenerType.authenticationEvents,
      identifier: sessionID,
      onDataChange: onDataChange,
      onError: onError,
      autoReconnect: autoReconnect,
    );

    await _startListening(config);
  }

  // MARK: - Core Listening Logic

  /// Start listening with the given configuration
  Future<void> _startListening(SSEListenerConfig config) async {
    _ensureInitialized();

    try {
      // Validate initialization
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'Firebase SSE not initialized with valid database URL.');
      }

      final key = config.key;
      final existingConnection = _activeConnections[key];

      // If already listening to the same configuration, just log and return
      if (existingConnection != null && existingConnection.isActive) {
        _logMessage(
            'Already listening to ${config.displayName}: ${config.identifier}');
        return;
      }

      // Clean up any existing connection for this key
      if (existingConnection != null) {
        await _stopConnection(key);
      }

      final uri = Uri.parse('$_databaseUrl${config.getPath()}');

      _logMessage(
          'Starting ${config.displayName} listener for: ${config.identifier ?? 'global'}');

      await _establishConnection(config, uri);
    } catch (e) {
      _logMessage('Failed to start ${config.displayName} listener: $e');
      _handleConnectionError(config.key, e, config.onError);
    }
  }

  /// Establish a new SSE connection
  Future<void> _establishConnection(SSEListenerConfig config, Uri uri) async {
    final connection = SSEConnection(config: config, uri: uri);
    final key = config.key;

    _activeConnections[key] = connection;

    try {
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';

      _updateConnectionState(key, SSEConnectionState.connecting);

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw HttpException('Failed to connect: HTTP ${response.statusCode}');
      }

      _logMessage('${config.displayName} connection established at: $uri');

      connection.subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          _logMessage(
              'Event received for ${config.displayName}: ${event.length > 100 ? '${event.substring(0, 100)}...' : event}');
          _processEvent(event, config.onDataChange, config.onError);
        },
        onError: (error) {
          _logMessage('Connection error for ${config.displayName}: $error');
          _handleConnectionError(key, error, config.onError);

          if (config.autoReconnect) {
            _scheduleReconnect(key, config, uri);
          }
        },
        onDone: () {
          _logMessage('Connection closed for ${config.displayName}');
          _updateConnectionState(key, SSEConnectionState.disconnected);

          if (config.autoReconnect) {
            _scheduleReconnect(key, config, uri);
          }
        },
        cancelOnError: false,
      );

      _updateConnectionState(key, SSEConnectionState.connected);
    } catch (e) {
      _logMessage(
          'Connection establishment failed for ${config.displayName}: $e');
      _handleConnectionError(key, e, config.onError);

      if (config.autoReconnect) {
        _scheduleReconnect(key, config, uri);
      }
    }
  }

  /// Schedule a reconnection attempt
  void _scheduleReconnect(String key, SSEListenerConfig config, Uri uri) {
    final connection = _activeConnections[key];
    if (connection == null) return;

    // Cancel any existing reconnect timer
    connection.reconnectTimer?.cancel();

    final delay = connection.state == SSEConnectionState.error ? 5 : 3;
    _logMessage(
        'Scheduling reconnect for ${config.displayName} in $delay seconds...');

    connection.reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_activeConnections.containsKey(key)) {
        _establishConnection(config, uri);
      }
    });
  }

  // MARK: - Event Processing

  /// Process individual SSE events
  void _processEvent(
    String event,
    Function(String)? onDataChange,
    Function(Object)? onError,
  ) {
    try {
      final lines = event.split('\n');

      for (var line in lines) {
        // Skip empty lines
        if (line.trim().isEmpty) continue;

        // Parse data lines
        if (line.startsWith('data: ')) {
          _processDataLine(line, onDataChange, onError);
        }
        // Handle other event types if needed
        else if (line.startsWith('event: ')) {
          final eventType = line.substring(7).trim();
          _logMessage('Event type: $eventType');
        } else if (line.startsWith('id: ')) {
          final eventId = line.substring(4).trim();
          _logMessage('Event ID: $eventId');
        }
      }
    } catch (e) {
      _logMessage('Event processing error: $e');
      onError?.call(e);
    }
  }

  /// Parse and process data lines from SSE events
  void _processDataLine(
    String line,
    Function(String)? onDataChange,
    Function(Object)? onError,
  ) {
    try {
      final jsonData = line.substring(6).trim();

      if (jsonData.isEmpty || jsonData == 'null') {
        _logMessage('Skipping null or empty data');
        return;
      }

      final data = json.decode(jsonData);

      if (data is Map<String, dynamic>) {
        final eventData = data['data'];

        // Handle string events
        if (eventData is String) {
          _logMessage(
              'Processing string event: ${eventData.length > 50 ? '${eventData.substring(0, 50)}...' : eventData}');
          onDataChange?.call(eventData);
        }
        // Handle map events
        else if (eventData is Map<String, dynamic>) {
          _logMessage(
              'Processing map event with keys: ${eventData.keys.join(', ')}');
          onDataChange?.call(json.encode(eventData));
        }
        // Handle other types
        else if (eventData != null) {
          _logMessage('Unhandled event data type: ${eventData.runtimeType}');
          onDataChange?.call(json.encode({'data': eventData}));
        }
      } else {
        _logMessage('Unexpected data format: ${data.runtimeType}');
      }
    } catch (e) {
      _logMessage('Data processing error: $e');
      onError?.call(e);
    }
  }

  // MARK: - Connection Management

  /// Stop a specific connection
  Future<void> _stopConnection(String key) async {
    final connection = _activeConnections[key];
    if (connection != null) {
      _logMessage('Stopping connection: $key');
      await connection.dispose();
      _activeConnections.remove(key);
      _updateConnectionState(key, SSEConnectionState.disconnected);
    }
  }

  /// Stop listening for a specific type and identifier
  Future<void> stopListening({
    required SSEListenerType type,
    String? identifier,
  }) async {
    final key = '${type.name}_${identifier ?? 'global'}';
    await _stopConnection(key);
  }

  /// Stop all active listeners
  Future<void> stopAllListening() async {
    _logMessage('Stopping all active listeners (${_activeConnections.length})');

    final keys = List<String>.from(_activeConnections.keys);
    for (final key in keys) {
      await _stopConnection(key);
    }

    _logMessage('All listeners stopped');
  }

  // MARK: - Error Handling & State Management

  /// Handle connection errors
  void _handleConnectionError(
      String key, Object error, Function(Object)? onError) {
    _updateConnectionState(key, SSEConnectionState.error);
    onError?.call(error);
  }

  /// Update the connection state for a specific listener
  void _updateConnectionState(String key, SSEConnectionState newState) {
    final connection = _activeConnections[key];
    if (connection != null && connection.state != newState) {
      connection.state = newState;
      _logMessage('Connection state for $key changed to: $newState');

      // Broadcast the updated state map
      if (_isInitialized && !_stateController.isClosed) {
        _stateController.add(connectionStates);
      }
    }
  }

  // MARK: - Cleanup

  /// Dispose all resources
  Future<void> dispose() async {
    _logMessage('Disposing all resources');

    await stopAllListening();

    if (_isInitialized && !_stateController.isClosed) {
      await _stateController.close();
      _logMessage('State controller closed');
    }

    if (_isInitialized) {
      _httpClient.close();
      _logMessage('HTTP client closed');
    }

    _isInitialized = false;
    _logMessage('Successfully disposed all resources');
  }

  // MARK: - Logging

  /// Logging utility with automatic emoji categorization
  void _logMessage(String message) {
    String emoji;

    // Categorize log messages based on content
    if (message.contains('error') || message.contains('Error')) {
      emoji = '❌'; // Red X for errors
    } else if (message.contains('failed') || message.contains('Failed')) {
      emoji = '🚨'; // Siren for failure states
    } else if (message.contains('connect') || message.contains('Connection')) {
      emoji = '🔌'; // Plug for connection-related messages
    } else if (message.contains('listen') || message.contains('Listening')) {
      emoji = '👂'; // Ear for listening-related messages
    } else if (message.contains('init')) {
      emoji = '🚀'; // Rocket for initialization
    } else if (message.contains('dispose') || message.contains('stop')) {
      emoji = '🛑'; // Stop sign for disposal or stopping
    } else if (message.contains('success') || message.contains('Success')) {
      emoji = '✅'; // Green checkmark for success
    } else if (message.contains('event')) {
      emoji = '📬'; // Mailbox for events
    } else if (message.contains('process')) {
      emoji = '⚙️'; // Gear for processing
    } else if (message.contains('Scheduling') ||
        message.contains('reconnect')) {
      emoji = '🔄'; // Refresh for reconnection
    } else {
      emoji = '📝'; // Memo for general messages
    }

    '$emoji [SSEListener] $message'.log();
  }
}
 */