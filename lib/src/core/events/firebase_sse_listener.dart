import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
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

/// Enhanced Firebase Server-Sent Events (SSE) Listener
///
/// Provides robust real-time event listening for Firebase Realtime Database with
/// automatic reconnection, proper resource management, and state tracking.
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
  String _databaseUrl =
      'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app';

  /// Current active stream subscription
  StreamSubscription<String>? _subscription;

  /// Current transaction ID being listened to
  String? _currentTransactionId;

  /// Current authentication event ID being listened to
  String? _currentAuthNSessionID;

  /// Current connection state
  SSEConnectionState _connectionState = SSEConnectionState.disconnected;

  /// Stream controller for broadcasting connection state changes
  late StreamController<SSEConnectionState> _stateController;

  /// Flag to track initialization state
  bool _isInitialized = false;

  // MARK: - Public Getters

  /// Getter for current connection state
  SSEConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes
  Stream<SSEConnectionState> get connectionStateStream {
    _ensureInitialized();
    return _stateController.stream;
  }

  /// Checks if currently listening to events
  bool get isListening => _subscription != null;

  // MARK: - Initialization

  /// Ensures the listener is properly initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      _httpClient = http.Client();
      _stateController = StreamController<SSEConnectionState>.broadcast();
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

  // MARK: - URL Path Helpers

  /// Constructs the Firebase database path for a payment update
  String _path(String transactionId) =>
      '/public/paymentUpdate/$transactionId.json';

  /// Constructs the Firebase database path for transaction messages
  String _transactionMessagePath(String transactionId) =>
      '/public/transaction-messages/$transactionId.json';

  String _customTabsPath() => '/public/close_tab.json';

  /// Constructs the Firebase database path for authentication events
  String _authNPath(String sessionID) =>
      '/public/login_success/authn_$sessionID.json';

  // MARK: - Listening Methods

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
    _ensureInitialized();

    try {
      // Validate initialization
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'Firebase SSE not initialized with valid database URL.');
      }

      // Stop any existing listener if listening to a different transaction
      if (_currentTransactionId != transactionId && isListening) {
        _logMessage(
            'Switching from transaction $_currentTransactionId to $transactionId');
        await _stopListening();
      } else if (_currentTransactionId == transactionId && isListening) {
        _logMessage('Already listening to transaction: $transactionId');
        return;
      }

      _currentTransactionId = transactionId;
      final uri = Uri.parse('$_databaseUrl${_path(transactionId)}');

      await _establishConnection(
        uri: uri,
        onDataChange: onDataChange,
        onError: onError,
        connectionType: 'Payment Updates',
        autoReconnect: autoReconnect,
      );
    } catch (e) {
      _logMessage('Failed to listen for payment updates: $e');
      _handleError(e, onError);
      await _stopListening();
    }
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
    _ensureInitialized();

    try {
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'Firebase SSE not initialized with valid database URL.');
      }

      // Check if already listening to this transaction
      if (_currentTransactionId == transactionId && isListening) {
        _logMessage(
            'Already listening to transaction messages: $transactionId');
        return;
      }

      // Stop any existing listener
      await _stopListening();

      _currentTransactionId = transactionId;
      final uri =
          Uri.parse('$_databaseUrl${_transactionMessagePath(transactionId)}');

      await _establishConnection(
        uri: uri,
        onDataChange: onDataChange,
        onError: onError,
        connectionType: 'Transaction Messages',
        autoReconnect: autoReconnect,
      );
    } catch (e) {
      _logMessage('Failed to listen for transaction messages: $e');
      _handleError(e, onError);
      await _stopListening();
    }
  }

  Future<void> listenForCustomTabEvents({
    Function(String)? onDataChange,
    Function(Object)? onError,
    bool autoReconnect = true,
  }) async {
    _ensureInitialized();

    try {
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'Firebase SSE not initialized with valid database URL.');
      }

      final uri = Uri.parse('$_databaseUrl${_customTabsPath()}');

      await _establishConnection(
        uri: uri,
        onDataChange: onDataChange,
        onError: onError,
        connectionType: 'Custom Tabs',
        autoReconnect: autoReconnect,
      );
    } catch (e) {
      _logMessage('Failed to listen for transaction messages: $e');
      _handleError(e, onError);
      await _stopListening();
    }
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
    _ensureInitialized();

    try {
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'Firebase SSE not initialized with valid database URL.');
      }

      // Check if already listening to this session
      if (_currentAuthNSessionID == sessionID && isListening) {
        _logMessage('Already listening to authentication events: $sessionID');
        return;
      }

      // Stop any existing listener
      await _stopListening();

      _currentAuthNSessionID = sessionID;
      final uri = Uri.parse('$_databaseUrl${_authNPath(sessionID)}');

      await _establishConnection(
        uri: uri,
        onDataChange: onDataChange,
        onError: onError,
        connectionType: 'Authentication Events',
        autoReconnect: autoReconnect,
      );
    } catch (e) {
      _logMessage('Failed to listen for authentication events: $e');
      _handleError(e, onError);
      await _stopListening();
    }
  }

  // MARK: - Connection Management

  /// Establishes an SSE connection to the specified URI
  Future<void> _establishConnection({
    required Uri uri,
    required Function(String)? onDataChange,
    required Function(Object)? onError,
    required String connectionType,
    bool autoReconnect = true,
  }) async {
    try {
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';

      _updateConnectionState(SSEConnectionState.connecting);

      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw HttpException('Failed to connect: HTTP ${response.statusCode}');
      }

      _logMessage('$connectionType connection established at: $uri');

      _subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          _logMessage(
              'Event received: ${event.length > 100 ? '${event.substring(0, 100)}...' : event}');
          _processEvent(event, onDataChange, onError);
        },
        onError: (error) {
          _logMessage('Connection error: $error');
          _handleError(error, onError);

          if (autoReconnect) {
            _logMessage('Attempting to reconnect in 3 seconds...');
            Future.delayed(Duration(seconds: 3), () {
              _establishConnection(
                uri: uri,
                onDataChange: onDataChange,
                onError: onError,
                connectionType: connectionType,
                autoReconnect: autoReconnect,
              );
            });
          }
        },
        onDone: () {
          _logMessage('Connection closed.');
          _updateConnectionState(SSEConnectionState.disconnected);

          if (autoReconnect) {
            _logMessage('Attempting to reconnect in 3 seconds...');
            Future.delayed(Duration(seconds: 3), () {
              _establishConnection(
                uri: uri,
                onDataChange: onDataChange,
                onError: onError,
                connectionType: connectionType,
                autoReconnect: autoReconnect,
              );
            });
          }
        },
        cancelOnError: false, // We handle errors explicitly for reconnection
      );

      _updateConnectionState(SSEConnectionState.connected);
    } catch (e) {
      _logMessage('Connection establishment failed: $e');
      _handleError(e, onError);

      if (autoReconnect) {
        _logMessage('Attempting to reconnect in 5 seconds...');
        Future.delayed(Duration(seconds: 5), () {
          _establishConnection(
            uri: uri,
            onDataChange: onDataChange,
            onError: onError,
            connectionType: connectionType,
            autoReconnect: autoReconnect,
          );
        });
      }
    }
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
      _handleError(e, onError);
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

  // MARK: - Error Handling

  /// Handle errors and update connection state
  void _handleError(Object error, Function(Object)? onError) {
    _updateConnectionState(SSEConnectionState.error);
    onError?.call(error);
  }

  /// Update the connection state and broadcast changes
  void _updateConnectionState(SSEConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _logMessage('Connection state changed to: $newState');

      // Only add if the controller is initialized and not closed
      if (_isInitialized && !_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  // MARK: - Cleanup

  /// Stop listening and clean up resources
  Future<void> _stopListening() async {
    if (_subscription != null) {
      _logMessage('Stopping active listener');
      await _subscription!.cancel();
      _subscription = null;
      _currentTransactionId = null;
      _currentAuthNSessionID = null;

      // Update connection state
      _updateConnectionState(SSEConnectionState.disconnected);
    }
  }

  /// Stop listening to all events and close the connection
  Future<void> stopAllListening() async {
    await _stopListening();
    _logMessage('All listeners stopped');
  }

  /// Dispose the SSE service when no longer needed
  Future<void> dispose() async {
    _logMessage('Disposing all resources');

    await _stopListening();

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
    } else {
      emoji = '📝'; // Memo for general messages
    }

    '$emoji [SSEListener] $message'.log();
  }
}
