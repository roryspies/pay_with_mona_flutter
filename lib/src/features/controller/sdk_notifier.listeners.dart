part of "sdk_notifier.dart";

extension SDKNotifierListeners on MonaSDKNotifier {
  void handleTransactionEvents({
    required String listenerName,
    required String eventName,
  }) {
    if (["transaction_initiated", "progress_update"].contains(eventName)) {
      "🥰 $listenerName ::: transaction_initiated".log();

      _txnStateStream.emit(
        state: TransactionStateInitiated(
          transactionID: _currentTransactionId,
          amount: _monaCheckOut?.amount,
        ),
      );
    }

    if (eventName == "transaction_failed") {
      "😭 $listenerName ::: transaction_failed".log();

      _txnStateStream.emit(
        state: TransactionStateFailed(
          transactionID: _currentTransactionId,
          amount: _monaCheckOut?.amount,
        ),
      );
    }

    if (eventName == "transaction_completed") {
      "✅ $listenerName ::: transaction_completed".log();

      _txnStateStream.emit(
        state: TransactionStateCompleted(
          transactionID: _currentTransactionId,
          amount: _monaCheckOut?.amount,
        ),
      );
    }

    _updateState(MonaSDKState.idle);
  }

  ///
  /// *** MARK: Event Listeners
  Future<void> _listenForPaymentUpdates() async {
    try {
      await _firebaseSSE.listenForPaymentUpdates(
        transactionId: _currentTransactionId ?? "",
        onDataChange: (event) {
          "_listenForPaymentUpdates ::: EVENT $event".log();
          final eventData = jsonDecode(event) as Map<String, dynamic>;
          final theEvent = eventData["event"];

          handleTransactionEvents(
            eventName: theEvent,
            listenerName: "_listenForPaymentUpdates()",
          );
        },
        onError: (error) {
          _handleError("Error listening for transaction updates.");
          throw error;
        },
      );
    } catch (error) {
      "_listenForPaymentUpdates error: $error".log();
      rethrow;
    }
  }

  Future<void> _listenForTransactionUpdateEvents() async {
    try {
      await _firebaseSSE.listenForTransactionMessages(
        transactionId: _currentTransactionId ?? "",
        onDataChange: (event) async {
          "_listenForTransactionUpdateEvents ::: EVENT $event".log();
          final eventData = jsonDecode(event) as Map<String, dynamic>;
          final theEvent = eventData["event"];

          handleTransactionEvents(
            eventName: theEvent,
            listenerName: "_listenForTransactionUpdateEvents()",
          );

          /* if (theEvent == "transaction_initiated") {
            "🥰 _listenForTransactionUpdateEvents ::: transaction_initiated"
                .log();

            _txnStateStream.emit(
              state: TransactionStateInitiated(
                transactionID: _currentTransactionId,
              ),
            );
          }

          if (theEvent == "transaction_failed") {
            "😭 _listenForTransactionUpdateEvents ::: transaction_failed".log();

            _txnStateStream.emit(
              state: TransactionStateFailed(),
            );
          }

          if (theEvent == "transaction_completed") {
            "✅ _listenForTransactionUpdateEvents ::: transaction_completed"
                .log();

            _txnStateStream.emit(
              state: TransactionStateCompleted(
                transactionID: _currentTransactionId,
              ),
            );
          } */
        },
        onError: (error) {
          _handleError("Error during transaction updates.");
          throw error;
        },
      );
    } catch (error) {
      "_listenForTransactionUpdateEvents error: $error".log();
      rethrow;
    }
  }

  Future<void> _listenForAuthEvents(
    String sessionId,
    Completer<void> authCompleter,
  ) async {
    try {
      await _firebaseSSE.listenToAuthNEvents(
        sessionID: sessionId,
        onDataChange: (event) async {
          try {
            "_listenForAuthEvents received event: $event".log();
            if (event.contains("strongAuthToken")) {
              _strongAuthToken = (jsonDecode(event)
                  as Map<String, dynamic>)["strongAuthToken"];
              _authStream.emit(state: AuthState.performingLogin);

              await closeCustomTabs();
              await loginWithStrongAuth();
              authCompleter.complete();
            }
          } catch (error, stackTrace) {
            "_listenForAuthEvents error: $error".log();
            authCompleter.completeError(error, stackTrace);
          }
        },
        onError: (error) {
          _handleError("Error during strong authentication.");
          authCompleter.completeError(error);
        },
      );
    } catch (error) {
      "_listenForTransactionUpdateEvents error: $error".log();
      rethrow;
    }
  }
}
