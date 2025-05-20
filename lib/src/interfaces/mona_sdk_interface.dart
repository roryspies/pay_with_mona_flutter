/// Public interface for the Mona SDK
///
/// This is the only class that should be directly exposed to clients.
abstract class IMonaSDK {
  Future<void> initialize({
    required String apiKey,
    required String merchantId,
    bool enableDebugLogs = false,
  });

  /// Set up checkout details
  void setupCheckout(
      /* {
    required MonaCheckOut checkoutDetails,
    required BuildContext context,
  } */
      );

  /// Start a payment flow
  Future<bool> startPayment(
      /* {
    required num amountInKobo,
    required PaymentMethod method,
  } */
      );

  /// Get available payment methods for the user
  Future<List /* <PaymentMethod> */ > getAvailablePaymentMethods();

  /// Handle authentication flow
  Future<bool> authenticate({
    String? phoneNumber,
    String? bvn,
    String? dob,
  });

  /// Create a new collection
  Future /* <CollectionResult> */ createCollection(
      /* {
    required CollectionRequest request,
  } */
      );

  /// Trigger a collection
  Future /* <TransactionResult> */ triggerCollection({
    required String merchantId,
    required int timeFactor,
  });

  /// Get current SDK state
  Stream /* <SdkState> */ get stateStream;

  /// Get transaction state updates
  Stream /* <TransactionState> */ get transactionStream;

  /// Get authentication state updates
  Stream /* <AuthState> */ get authStateStream;

  /// Reset the SDK state
  void reset();

  /// Clean up resources
  void dispose();
}
