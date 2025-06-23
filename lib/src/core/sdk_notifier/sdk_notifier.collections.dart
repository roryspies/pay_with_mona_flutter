part of "sdk_notifier.dart";

extension SDKNotifierCollections on MonaSDKNotifier {
  Future<void> createCollections({
    required String bankId,
    required String accessRequestId,
    void Function(Map<String, dynamic>?)? onSuccess,
    void Function()? onFailure,
  }) async {
    _updateState(MonaSDKState.loading);

    _firebaseSSE.initialize();
    try {
      await _collectionsService.createCollectionRequest(
        bankId: bankId,
        accessRequestId: accessRequestId,
        onComplete: (res, p) {
          final success = res as Map<String, dynamic>;
          success.log();
          onSuccess?.call(success);
        },
        onError: () {
          _updateState(MonaSDKState.error);
          onFailure?.call();
        },
      );
    } catch (e) {
      onFailure?.call();
      e.toString().log();
      _handleError(e.toString());
    } finally {
      _updateState(MonaSDKState.success);
    }
  }

  Future<void> triggerCollection({
    required String merchantId,
    required int timeFactor,
    void Function(Map<String, dynamic>?)? onSuccess,
    void Function(String)? onError,
  }) async {
    _updateState(MonaSDKState.loading);
    try {
      final (Map<String, dynamic>? success, failure) =
          await _collectionsService.triggerCollection(
        merchantId: merchantId,
        timeFactor: timeFactor,
      );

      if (failure != null) {
        _handleError('Collection trigger failed.');
        onError?.call('Collection trigger failed.');
        // throw (failure.message);
      }

      if (success != null) {
        success.log();

        // Extract transaction ID from the nested response
        String? transactionId;
        if (success['success'] == true &&
            success['data'] is List &&
            (success['data'] as List).isNotEmpty) {
          final firstTransaction = (success['data'] as List).first;
          if (firstTransaction is Map<String, dynamic>) {
            // Get the transactionRef which appears to be the transaction ID
            transactionId = firstTransaction['transactionRef'] as String?;
          }
        }

        if (transactionId != null) {
          _handleTransactionId(transactionId);
          //_listenForTransactionUpdateEvents();
          _listenForCustomTabEvents();
        }

        onSuccess?.call(success);
      }

      _updateState(MonaSDKState.success);
    } catch (e) {
      e.toString().log();
      _handleError(e.toString());
      onError?.call('Collection trigger failed.');
    }
  }

  Future<void> validateCreateCollectionFields({
    required String maximumAmount,
    required String expiryDate,
    required String startDate,
    required String monthlyLimit,
    required String reference,
    required String type,
    required String frequency,
    required String? amount,
    required String merchantName,
    required CollectionsMethod method,
    required String debitType,
    required List<Map<String, dynamic>> scheduleEntries,
    void Function(String)? onError,
    void Function()? onSuccess,
    required String secretKey,
  }) async {
    _updateState(MonaSDKState.loading);
    final (Map<String, dynamic>? success, failure) =
        await _collectionsService.validateCreateCollectionFields(
            maximumAmount: maximumAmount,
            expiryDate: expiryDate,
            startDate: startDate,
            monthlyLimit: monthlyLimit,
            reference: reference,
            type: type,
            frequency: frequency,
            amount: amount,
            debitType: debitType,
            scheduleEntries: scheduleEntries,
            secretKey: secretKey);

    if (failure != null) {
      final errorMsg = failure.message;
      _handleError(errorMsg);
      onError?.call(errorMsg);
      return;
    }

    if (success != null) {
      success.log();

      final requestsMap = success['data'] as Map<String, dynamic>;

      final accessRequestId = requestsMap['id'] as String;

      final monthlyLimit = requestsMap['collection']['monthlyLimit'] ?? '';

      SDKUtils.showSDKModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        callingContext: callingContext,
        onCancelButtonTap: () {
          Navigator.of(callingContext).pop();
        },
        child: CollectionsCheckoutSheet(
          accessRequestId: accessRequestId,
          debitType: debitType,
          scheduleEntries: scheduleEntries,
          method: method,
          details: Collection(
            maxAmount: maximumAmount,
            expiryDate: expiryDate,
            startDate: startDate,
            monthlyLimit: divideBy100NoDecimal(monthlyLimit),
            schedule: Schedule(
              frequency: frequency,
              type: type,
              amount: amount,
              entries: [],
            ),
            reference: reference,
            status: '',
            nextCollectionAt: '',
          ),
          merchantName: merchantName,
        ),
      );

      /* showModalBottomSheet(
        context: _callingBuildContext!,
        isScrollControlled: true,
        builder: (_) => Wrap(
          children: [
            CollectionsCheckoutSheet(
              accessRequestId: accessRequestId,
              debitType: debitType,
              scheduleEntries: scheduleEntries,
              method: method,
              details: Collection(
                maxAmount: maximumAmount,
                expiryDate: expiryDate,
                startDate: startDate,
                monthlyLimit: divideBy100NoDecimal(monthlyLimit),
                schedule: Schedule(
                  frequency: frequency,
                  type: type,
                  amount: amount,
                  entries: [],
                ),
                reference: reference,
                status: '',
                nextCollectionAt: '',
              ),
              merchantName: merchantName,
            ),
          ],
        ),
      ); */

      _updateState(MonaSDKState.success);
      return;
    }
  }

  Future<void> collectionHandOffToAuth({
    required Function()? onAuthComplete,
  }) async {
    _updateState(MonaSDKState.loading);

    // Initialize SSE listener for real-time events
    _firebaseSSE.initialize();

    _updateState(MonaSDKState.loading);

    /// *** If the user doesn't have a keyID and they want to use a saved payment method,
    /// *** Key exchange needs to be done, so handle first.
    final doKeyExchange = await checkIfUserHasKeyID() == null;

    /// *** Payment process will be handled here on the web, if there is no checkout ID / Key Exchange done
    /// *** previously
    if (doKeyExchange) {
      await initKeyExchange(
        withRedirect: false,
        isFromCollections: true,
      );
    }

    /// *** Hold up to ensure that user saved methods have been set in the SDK.
    await Future.delayed(Duration(seconds: 1));

    final userKeyID = await checkIfUserHasKeyID();

    if (userKeyID != null) {
      await validatePII(userKeyID: userKeyID);
    }

    _updateState(MonaSDKState.idle);

    onAuthComplete?.call();
  }

  Future<Map<String, dynamic>> fetchCollectionsForBank({
    required String bankId,
    void Function(String)? onError,
  }) async {
    _updateState(MonaSDKState.loading);
    try {
      final (Map<String, dynamic>? success, failure) =
          await _collectionsService.fetchCollections(bankId: bankId);

      if (failure != null) {
        final errorMsg = failure.message;
        _handleError(errorMsg);
        onError?.call(errorMsg);
        return {};
      }

      if (success != null) {
        success.log();
        _updateState(MonaSDKState.success);
        return success;
      }

      // Just in case both success and failure are null
      _handleError('Unknown error occurred.');
      onError?.call('Unknown error occurred.');
      return {};
    } catch (e) {
      final err = e.toString();
      err.log();
      _handleError(err);
      onError?.call('Something went wrong');
      return {};
    }
  }
}
