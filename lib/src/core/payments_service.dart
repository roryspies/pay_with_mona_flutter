import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api/api_header_model.dart';
import 'package:pay_with_mona/src/core/api/api_service.dart';
import 'package:pay_with_mona/src/core/secure_storage.dart';
import 'package:pay_with_mona/src/core/secure_storage_keys.dart';
import 'package:pay_with_mona/src/core/signatures.dart';
import 'package:pay_with_mona/src/core/uuid_generator.dart';
import 'package:pay_with_mona/src/features/payments/controller/payment_notifier.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

/// Service to orchestrate payment‐related endpoints.
class PaymentService {
  final _repoName = "💸 PaymentService::: ";
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final _apiService = ApiService();

  /// Initiates a checkout session.
  FutureOutcome<Map<String, dynamic>> initiatePayment() async {
    try {
      final response = await _apiService.post(
        '/demo/checkout',
        data: {
          'amount': 2000,
        },
      );

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ initiatePayment() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  /// Retrieves available payment methods for a transaction.
  FutureOutcome<PendingPaymentResponseModel> getPaymentMethods({
    required String transactionId,
    required String userEnrolledCheckoutID,
  }) async {
    try {
      final response = await _apiService.get(
        '/pay',
        headers: {
          'cookie': 'mona_checkoutId=$userEnrolledCheckoutID',
        },
        queryParams: {'transactionId': transactionId},
      );

      return right(
        PendingPaymentResponseModel.fromJSON(
          json: jsonDecode(response.body) as Map<String, dynamic>,
        ),
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ getPaymentMethods() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  Future<void> makePaymentRequest({
    bool sign = false,
    TransactionPaymentTypes paymentType = TransactionPaymentTypes.bank,
    Function? onPayComplete,
  }) async {
    final paymentNotifier = PaymentNotifier();
    final secureStorage = SecureStorage();
    final payload = await paymentNotifier.buildBankPaymentPayload();
    final monaKeyID = await secureStorage.read(
          key: SecureStorageKeys.keyID,
        ) ??
        "";
    final userCheckoutID = await secureStorage.read(
          key: SecureStorageKeys.monaCheckoutID,
        ) ??
        "";

    if (sign) {
      final nonce = UUIDGenerator.v4();
      final timestamp =
          DateTime.now().toLocal().millisecondsSinceEpoch.toString();

      "$_repoName makePaymentRequest REQUESTING TO SIGN PAYMENT ==>> PAY LOAD TO BE SIGNED ==>> $payload"
          .log();

      String? signature = await _signRequest(
        payload,
        nonce,
        timestamp,
        monaKeyID,
      );

      if (signature == null) {
        "$_repoName completePaymentRequest SIGNATURE IS NULL OR CANCELLED"
            .log();

        return;
      }

      await submitPaymentRequest(
        paymentType,
        payload,
        onPayComplete: onPayComplete,
        monaKeyId: monaKeyID,
        monaCheckoutID: userCheckoutID,
        signature: signature,
        nonce: nonce,
        timestamp: timestamp,
      );
      return;
    }

    await submitPaymentRequest(
      paymentType,
      payload,
      onPayComplete: onPayComplete,
      monaKeyId: monaKeyID,
      monaCheckoutID: userCheckoutID,
    );
  }

  Future<void> submitPaymentRequest(
    TransactionPaymentTypes paymentType,
    Map<String, dynamic> payload, {
    required Function? onPayComplete,
    String? monaKeyId,
    String? monaCheckoutID,
    String? signature,
    String? nonce,
    String? timestamp,
  }) async {
    "$_repoName submitPaymentRequest REACHED SUBMISSION".log();

    final (res, failure) = await sendPaymentToServer(
      payload: payload,
      monaKeyId: monaKeyId,
      monaCheckoutID: monaCheckoutID,
      signature: signature,
      nonce: nonce,
      timestamp: timestamp,
    );

    if (failure != null) {
      "$_repoName submitPaymentRequest FAILED ::: ${failure.message}".log();
      return;
    }

    if (res!["success"] == true) {
      "Payment Successful".log();
      if (onPayComplete != null) {
        onPayComplete();
      }

      return;
    } else {
      " submitPaymentRequest ==>> RESPONSE[SUCCESS] ==>> FALSE ==>> $res".log();

      if (res.containsKey("task") &&
          (res["task"] as Map<String, dynamic>).isNotEmpty) {
        final task = res["task"] as Map<String, dynamic>;

        "submitPaymentRequest RESPONSE TASK ==>> $task ==>> SERVER GOTTEN TRANSACTION ID ==>> ${res["transactionId"]}"
            .log();

        ///
        /// *** SINGING REQUESTS START HERE
        if (task["taskType"] == "sign") {
          return await makePaymentRequest(
            paymentType: paymentType,
            sign: true,
            onPayComplete: onPayComplete,
          );
        }
      }
    }
  }

  ///
  /// ***
  FutureOutcome<Map<String, dynamic>> sendPaymentToServer({
    required Map<String, dynamic> payload,
    String? monaKeyId,
    String? monaCheckoutID,
    String? signature,
    String? nonce,
    String? timestamp,
  }) async {
    try {
      final response = await _apiService.post(
        "/pay",
        headers: ApiHeaderModel.paymentHeaders(
          monaKeyID: monaKeyId,
          monaCheckoutID: monaCheckoutID,
          signature: signature,
          nonce: nonce,
          timestamp: timestamp,
        ),
        data: payload,
      );

      return right(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ sendPaymentToServer() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  ///
  /// *** SIGN A TRANSACTION / PAYMENT REQUEST USING BIOMETRICS
  Future<String?> _signRequest(
    Map<String, dynamic> payload,
    String nonce,
    String timestamp,
    String userCheckoutID,
  ) async {
    "$_repoName _signRequest".log();

    final encodedPayload = base64Encode(utf8.encode(jsonEncode(payload)));

    Map<String, dynamic> data = {
      "method": base64Encode(utf8.encode("POST")),
      "uri": base64Encode(utf8.encode("/pay")),
      "body": encodedPayload,
      "params": base64Encode(utf8.encode(jsonEncode({}))),
      "nonce": base64Encode(utf8.encode(nonce)),
      "timestamp": base64Encode(utf8.encode(timestamp)),
      "keyId": base64Encode(utf8.encode(userCheckoutID)),
    };

    final dataString = base64Encode(utf8.encode(json.encode(data)));
    final hash = sha256.convert(utf8.encode(dataString)).toString();

    final String? signature = await BiometricSignatureHelper().createSignature(
      rawData: hash,
      title: "Scan your fingerprint",
    );

    return signature;
  }
}

enum TransactionPaymentTypes {
  bank('bank');

  const TransactionPaymentTypes(this.jsonString);
  final String jsonString;
}

extension TransactionPaymentTypesFromString on String? {
  TransactionPaymentTypes? get transactionPaymentTypes {
    return TransactionPaymentTypes.values.firstWhere(
      (element) => element.jsonString == this,
      orElse: () => TransactionPaymentTypes.bank,
    );
  }
}
