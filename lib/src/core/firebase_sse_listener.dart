import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pay_with_mona/src/utils/extensions.dart';

/// Enum to represent different states of the SSE connection
enum SSEConnectionState { disconnected, connecting, connected, error }

/// Enhanced Firebase Server-Sent Events (SSE) Listener
/// Provides robust real-time event listening for Firebase Realtime Database
class FirebaseSSEListener {
  /// Singleton instance
  static final FirebaseSSEListener _instance = FirebaseSSEListener._internal();

  /// Factory constructor for singleton access
  factory FirebaseSSEListener() => _instance;

  FirebaseSSEListener._internal();

  /// HTTP client for making network requests
  final http.Client _httpClient = http.Client();

  /// Firebase Realtime Database URL
  final String _databaseUrl =
      'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app';

  /// Current active stream subscription
  StreamSubscription<String>? _subscription;

  /// Current transaction ID being listened to
  String? _currentTransactionId;

  /// Current authn event ID being listened to
  String? _currentAuthNSessionID;

  /// Current connection state
  SSEConnectionState _connectionState = SSEConnectionState.disconnected;

  /// Stream controller for broadcasting connection state changes
  final StreamController<SSEConnectionState> _stateController =
      StreamController<SSEConnectionState>.broadcast();

  /// Getter for current connection state
  SSEConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes
  Stream<SSEConnectionState> get connectionStateStream =>
      _stateController.stream;

  /// Checks if currently listening to events
  bool get isListening => _subscription != null;

  /// Initialize the SSE listener with a Firebase Realtime Database URL
  ///
  /// [databaseUrl] The base URL of the Firebase Realtime Database
  void initialize(/* {required String databaseUrl} */) {
    //ArgumentError.checkNotNull(databaseUrl, 'databaseUrl');

    //_databaseUrl = databaseUrl.trim();
    _logMessage('Initialized with database URL: $_databaseUrl');
  }

  /// Constructs the Firebase database path for a specific transaction
  String _path(String transactionId) =>
      '/public/paymentUpdate/$transactionId.json';

  /// Constructs the Firebase database path for a specific transaction
  String _transactionMessagePath(String transactionId) =>
      '/public/transaction-messages/$transactionId.json';

  /// Constructs the Firebase database path for a specific transaction
  String _authNPath(String sessionID) =>
      '/public/login_success/authn_$sessionID.json';

  /// Start listening to SSE events for a given transaction
  ///
  /// [transactionId] Unique identifier for the transaction
  /// [onDataChange] Callback for received data
  /// [onError] Callback for handling errors
  Future<void> listenForPaymentUpdates({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
  }) async {
    try {
      // Validate initialization
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'FirebaseSSE not initialized. Call initialize() first.');
      }

      // Stop any existing listener if listening to a different transaction
      if (_currentTransactionId == transactionId && isListening) {
        _logMessage('Already listening to: $transactionId');
        await _stopListening();
      }

      // Ensure previous listener is stopped
      await _stopListening();

      _currentTransactionId = transactionId;
      final uri = Uri.parse('$_databaseUrl${_path(transactionId)}');

      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream';
      _updateConnectionState(SSEConnectionState.connecting);

      final response = await _httpClient.send(request);
      _logMessage('Connection established. Listening for events...');
      _logMessage('listenForPaymentUpdates ::: Firebase Connection URL: $uri');

      _subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          _logMessage('Raw event received: $event');
          _processEvent(event, onDataChange, onError);
        },
        onError: (error) {
          _logMessage('Connection error: $error');
          _handleError(error, onError);
        },
        onDone: () {
          _logMessage('Connection closed.');
          _stopListening();
        },
        cancelOnError: true,
      );

      _updateConnectionState(SSEConnectionState.connected);
    } catch (e) {
      _logMessage('Connection failed');
      _handleError(e, onError);
      await _stopListening();
    }
  }

  Future<void> listenForTransactionMessages({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
  }) async {
    try {
      // Validate initialization
      if (_databaseUrl.isEmpty) {
        throw StateError(
          'FirebaseSSE not initialized. Call initialize() first.',
        );
      }

      final uri =
          Uri.parse('$_databaseUrl${_transactionMessagePath(transactionId)}');

      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream';
      _updateConnectionState(SSEConnectionState.connecting);

      final response = await _httpClient.send(request);
      _logMessage('Connection established. Listening for events...');
      _logMessage(
          'listenForTransactionMessages ::: Firebase Connection URL: $uri');

      _subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          _logMessage('Raw event received: $event');
          _processEvent(event, onDataChange, onError);
        },
        onError: (error) {
          _logMessage('Connection error: $error');
          _handleError(error, onError);
        },
        onDone: () {
          _logMessage('Connection closed.');
          _stopListening();
        },
        cancelOnError: true,
      );

      _updateConnectionState(SSEConnectionState.connected);
    } catch (e) {
      _logMessage('Connection failed');
      _handleError(e, onError);
      await _stopListening();
    }
  }

  Future<void> listenToCustomEvents({
    required String sessionID,
    Function(String)? onDataChange,
    Function(Object)? onError,
  }) async {
    try {
      // Validate initialization
      if (_databaseUrl.isEmpty) {
        throw StateError(
            'FirebaseSSE not initialized. Call initialize() first.');
      }

      // Stop any existing listener if listening to a different transaction
      if (_currentAuthNSessionID == sessionID && isListening) {
        _logMessage('Already listening to: $sessionID');
        await _stopListening();
      }

      // Ensure previous listener is stopped
      await _stopListening();

      _currentAuthNSessionID = sessionID;
      final uri = Uri.parse('$_databaseUrl${_authNPath(sessionID)}');

      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream';
      _updateConnectionState(SSEConnectionState.connecting);

      final response = await _httpClient.send(request);
      _logMessage('Connection established. Listening for events...');

      _logMessage('listenToCustomEvents ::: Firebase Connection URL: $uri');

      _subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          _logMessage('Raw event received: $event');
          _processEvent(event, onDataChange, onError);
        },
        onError: (error) {
          _logMessage('Connection error: $error');
          _handleError(error, onError);
        },
        onDone: () {
          _logMessage('Connection closed.');
          _stopListening();
        },
        cancelOnError: true,
      );

      _updateConnectionState(SSEConnectionState.connected);
    } catch (e) {
      _logMessage('Connection failed');
      _handleError(e, onError);
      await _stopListening();
    }
  }

  /// Process individual SSE events
  void _processEvent(
    String event,
    Function(String)? onDataChange,
    Function(Object)? onError,
  ) {
    final lines = event.split('\n');
    for (var line in lines) {
      if (line.startsWith('data: ')) {
        _processDataLine(line, onDataChange, onError);
      }
    }
  }

  /// Parse and process data lines from SSE events
  void _processDataLine(
    String line,
    Function(String)? onDataChange,
    Function(Object)? onError,
  ) {
    final jsonData = line.substring(6).trim();
    _logMessage('Extracted JSON: $jsonData');

    if (jsonData.isEmpty || jsonData == 'null') {
      _logMessage('Skipping null or empty data');
      return;
    }

    try {
      final data = json.decode(jsonData);
      if (data is Map<String, dynamic>) {
        _logMessage('Parsed data: $data');

        final eventData = data['data'];
        _logMessage('Event data: $eventData');

        if (eventData is String) {
          _logMessage('Emitting event: $eventData');
          onDataChange?.call(eventData);
        } else if (eventData is Map<String, dynamic>) {
          if (eventData.containsKey('strongAuthToken')) {
            final strongAuthToken = eventData['strongAuthToken'];
            _logMessage('Strong Auth Token: $strongAuthToken');
            onDataChange?.call(strongAuthToken);
          } else {
            _logMessage('Event data does not contain strongAuthToken');
            onDataChange?.call((jsonEncode(eventData)));
          }
        } else {
          _logMessage('Unexpected event structure: $eventData');
        }
      } else {
        _logMessage('Unexpected data type: ${data.runtimeType}');
      }
    } catch (e) {
      _logMessage('JSON decode error: $e');
      onError?.call(e);
    }
  }

  /// Handle errors and update connection state
  void _handleError(Object error, Function(Object)? onError) {
    _updateConnectionState(SSEConnectionState.error);
    onError?.call(error);
  }

  /// Update the connection state and broadcast changes
  void _updateConnectionState(SSEConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _logMessage(_connectionState.toString());

      // Only add if the controller is still open
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Stop listening and clean up resources
  Future<void> _stopListening() async {
    if (_subscription != null) {
      _logMessage('Stopping listener...');
      await _subscription!.cancel();
      _subscription = null;
      _currentTransactionId = null;

      // Safely update connection state
      if (!_stateController.isClosed) {
        _updateConnectionState(SSEConnectionState.disconnected);
      }
    } else {
      _logMessage('No active listener.');
    }
  }

  /// Dispose the SSE service when no longer needed
  void dispose() {
    _logMessage('Disposing resources...');

    // Stop listening first
    _stopListening();

    // Close the state controller only if it's not already closed
    if (!_stateController.isClosed) {
      _stateController.close();
    }
  }

  /// Logging utility
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
    } else {
      emoji = '📝'; // Memo for general messages
    }

    '$emoji [SSEListener] $message'.log();
  }
}
