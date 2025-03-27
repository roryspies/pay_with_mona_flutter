import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pay_with_mona/src/utils/extensions.dart';

class FirebaseSSEListener {
  static final FirebaseSSEListener _instance = FirebaseSSEListener._internal();

  factory FirebaseSSEListener() => _instance;

  FirebaseSSEListener._internal();

  final http.Client _httpClient = http.Client();
  String _databaseUrl =
      'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app';

  StreamSubscription<String>? _subscription;
  String? _currentTransactionId;

  bool get isListening => _subscription != null;

  //! Initialize the SSE listener with a Firebase Realtime Database URL**
  void initialize({required String databaseUrl}) {
    _databaseUrl = databaseUrl;
    '✅ [SSE] Initialized with database URL: $_databaseUrl'.log();
  }

  String _path(String transactionId) =>
      '/public/paymentUpdate/$transactionId.json';

  //! Start listening to SSE events for a given transaction**
  Future<void> startListening({
    required String transactionId,
    Function(String)? onDataChange,
    Function(Object)? onError,
  }) async {
    if (_databaseUrl.isEmpty) {
      throw ArgumentError(
          'FirebaseSSE not initialized. Call initialize() first.');
    }

    if (_currentTransactionId == transactionId && isListening) {
      '⚠️ [SSE] Already listening to: $transactionId'.log();
      await stopListening();
    }

    await stopListening(); //! Ensure previous listener is stopped

    _currentTransactionId = transactionId;
    final uri = Uri.parse('$_databaseUrl${_path(transactionId)}');

    final request = http.Request('GET', uri)
      ..headers['Accept'] = 'text/event-stream';

    try {
      final response = await _httpClient.send(request);
      '🟢 [SSE] Connection established. Listening for events...'.log();

      _subscription = response.stream.transform(utf8.decoder).listen(
        (String event) {
          '📩 [SSE] Raw event received: $event'.log();

          final lines = event.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6).trim();
              '📦 [SSE] Extracted JSON: $jsonData'.log();

              if (jsonData.isEmpty || jsonData == 'null') {
                '⚠️ [SSE] Skipping null or empty data'.log();
                return;
              }

              try {
                final data = json.decode(jsonData);
                if (data is Map<String, dynamic>) {
                  '✅ [SSE] Parsed data: $data'.log();

                  final eventData = data['data'];

                  if (eventData is String) {
                    '🚀 [SSE] Emitting event: $eventData'.log();

                    onDataChange?.call(eventData);
                  } else {
                    '⚠️ [SSE] Unexpected event structure: $eventData'.log();
                  }
                } else {
                  '⚠️ [SSE] Unexpected data type: ${data.runtimeType}'.log();
                }
              } catch (e) {
                '❌ [SSE] JSON decode error: $e'.log();
                onError?.call(e);
              }
            }
          }
        },
        onError: (error) {
          '⚠️ [SSE] Error: $error'.log();
          onError?.call(error);
          stopListening();
        },
        onDone: () {
          '🔴 [SSE] Connection closed.'.log();
          stopListening();
        },
        cancelOnError: true,
      );
    } catch (e) {
      '❌ [SSE] Connection failed: $e'.log();
      onError?.call(e);
      stopListening();
    }
  }

  //! Stop listening and clean up resources**
  Future<void> stopListening() async {
    if (_subscription != null) {
      '🛑 [SSE] Stopping listener...'.log();
      await _subscription!.cancel();
      _subscription = null;
      _currentTransactionId = null;
    } else {
      '⚠️ [SSE] No active listener to stop.'.log();
    }
  }

  //! Dispose the SSE service when no longer needed**
  void dispose() {
    '🛑 [SSE] Disposing resources...'.log();
    stopListening();
    _httpClient.close();
  }
}
