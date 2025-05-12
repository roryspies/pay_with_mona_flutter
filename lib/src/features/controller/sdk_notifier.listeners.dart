part of "sdk_notifier.dart";

extension SDKNotifierListeners on MonaSDKNotifier {
  /// *** MARK: Event Listeners
  Future<void> _listenForPaymentUpdates(bool errorFlag) async {
    await _firebaseSSE.listenForPaymentUpdates(
      transactionId: _currentTransactionId ?? "",
      onDataChange: (event) {
        "PAYMENT UPDATE EVENT $event".log();
      },
      onError: (error) {
        _handleError("Error listening for transaction updates.");
        errorFlag = true;
      },
    );
  }

  Future<void> _listenForTransactionUpdateEvents(bool errorFlag) async {
    await _firebaseSSE.listenForTransactionMessages(
      transactionId: _currentTransactionId ?? "",
      onDataChange: (event) async {
        "_listenForTransactionUpdateEvents ::: EVENT $event".log();
        final eventData = jsonDecode(event) as Map<String, dynamic>;
        final theEvent = eventData["event"];

        if (theEvent == "transaction_initiated") {
          "🥰 _listenForTransactionUpdateEvents ::: transaction_initiated"
              .log();
          _txnStateStream.emit(state: TransactionState.initiated);
        }

        if (theEvent == "transaction_failed") {
          "😭 _listenForTransactionUpdateEvents ::: transaction_initiated"
              .log();
          _txnStateStream.emit(state: TransactionState.failed);
        }

        if (theEvent == "transaction_completed") {
          "✅ _listenForTransactionUpdateEvents ::: transaction_initiated".log();
          _txnStateStream.emit(state: TransactionState.completed);
        }
      },
      onError: (error) {
        _handleError("Error during strong authentication.");
        errorFlag = true;
      },
    );
  }

  Future<void> _listenForAuthEvents(String sessionId) async {
    await _firebaseSSE.listenToAuthNEvents(
      sessionID: sessionId,
      onDataChange: (event) async {
        if (event.contains("strongAuthToken")) {
          _strongAuthToken =
              (jsonDecode(event) as Map<String, dynamic>)["strongAuthToken"];

          _authStream.emit(state: AuthState.performingLogin);
        }

        await closeCustomTabs();
        await loginWithStrongAuth();
      },
      onError: (error) {
        _handleError("Error during strong authentication.");
      },
    );
  }
}
