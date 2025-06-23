import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pay_with_mona/src/core/api/api_endpoints.dart';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api/api_headers.dart';
import 'package:pay_with_mona/src/core/api/api_service.dart';
import 'package:pay_with_mona/src/core/events/models/transaction_task_model.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometrics_service.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart';
import 'package:pay_with_mona/src/core/generators/uuid_generator.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/notifier_enums.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/sdk_notifier.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

/// Service to orchestrate payment‐related endpoints.
class PaymentService {
  final _repoName = "💸 PaymentService::: ";
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final _apiService = ApiService();

  final _secureStorage = SecureStorage();

  Future<String?> getMerchantKey() async {
    return await _secureStorage.read(
      key: SecureStorageKeys.merchantKey,
    );
  }

  /// Initiates a checkout session.
  FutureOutcome<Map<String, dynamic>> initiatePayment({
    required String merchantKey,
    String? merchantAPIKey,
    required num tnxAmountInKobo,
    String? phoneNumber,
    String? bvn,
    String? dob,
    String? firstAndLastName,
    String? userKeyID,
  }) async {
    try {
      if (merchantAPIKey == null || merchantAPIKey.isEmpty) {
        throw Failure(
          "To initiate payment, API key cannot be empty",
        );
      }

      final amountIsLessThan20Naira = (tnxAmountInKobo / 100) < 20;
      if (amountIsLessThan20Naira) {
        throw Failure(
          "Cannot initiate payment for less than 20 Naira",
        );
      }

      if (dob != null &&
          (firstAndLastName == null || firstAndLastName.isEmpty)) {
        throw Failure(
          '`Name Value - First and Last` must not be null or empty when `dob` is provided.',
        );
      }

      if (firstAndLastName != null && (dob == null || dob.isEmpty)) {
        throw Failure(
          '`DOB` must not be null when `Name Value - First and Last` is provided.',
        );
      }

      final response = await _apiService.post(
        APIEndpoints.demoCheckout,
        headers: ApiHeaders.initiatePaymentHeader(
          merchantAPIKey: merchantAPIKey,
          merchantKey: merchantKey,
          userKeyID: userKeyID,
        ),
        data: {
          "amount": tnxAmountInKobo,
          if (phoneNumber != null) "phone": phoneNumber,
          if (bvn != null) "bvn": bvn,
          if (dob != null) "dob": dob,
          if (firstAndLastName != null) "name": firstAndLastName,
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
        APIEndpoints.pay,
        headers: ApiHeaders.getPaymentMethods(
          userEnrolledCheckoutID: userEnrolledCheckoutID,
        ),
        queryParams: {
          'transactionId': transactionId,
        },
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
    TransactionPaymentTypes? paymentType = TransactionPaymentTypes.bank,
    Function? onPayComplete,
  }) async {
    final paymentNotifier = MonaSDKNotifier();
    final secureStorage = SecureStorage();
    final payload = switch (paymentType) {
      TransactionPaymentTypes.card =>
        await paymentNotifier.buildCardPaymentPayload(),
      _ => await paymentNotifier.buildBankPaymentPayload(),
    };

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
        paymentType ?? TransactionPaymentTypes.bank,
        payload,
        onPayComplete: onPayComplete,
        monaKeyId: monaKeyID,
        monaCheckoutID: userCheckoutID,
        signature: signature,
        nonce: nonce,
        timestamp: timestamp,
        checkoutType: paymentType == TransactionPaymentTypes.card
            ? paymentType?.name
            : null,
      );
      return;
    }

    await submitPaymentRequest(
      paymentType ?? TransactionPaymentTypes.bank,
      payload,
      onPayComplete: onPayComplete,
      monaKeyId: monaKeyID,
      monaCheckoutID: userCheckoutID,
      checkoutType: paymentType == TransactionPaymentTypes.card
          ? paymentType?.name
          : null,
    );
  }

  Future<void> submitPaymentRequest(
    TransactionPaymentTypes paymentType,
    Map<String, dynamic> payload, {
    required Function? onPayComplete,
    String? checkoutType,
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
      checkoutType: checkoutType,
    );

    if (failure != null) {
      "$_repoName submitPaymentRequest FAILED ::: ${failure.message}".log();
      MonaSDKNotifier().resetPinAndOTP();
      return;
    }

    if (res!["success"] == true) {
      if (onPayComplete != null) {
        onPayComplete(res, payload);
      }

      return;
    } else {
      "submitPaymentRequest ==>> RESPONSE[SUCCESS] ==>> FALSE ==>> $res".log();

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
        } else {
          final monaSDK = MonaSDKNotifier();
          monaSDK.resetPinAndOTP();

          switch (task["fieldType"].toString().toLowerCase()) {
            case "pin":
              final pin = await monaSDK.triggerPinOrOTPFlow(
                pinOrOtpType: PaymentTaskType.pin,
                taskModel: TransactionTaskModel.fromJSON(
                  json: task,
                ),
              );

              if (pin != null && pin.isNotEmpty) {
                monaSDK.setTransactionPIN(receivedPIN: pin);

                await makePaymentRequest(
                  paymentType: paymentType,
                  onPayComplete: onPayComplete,
                );
              } else {
                "User cancelled PIN entry".log();
              }
              break;

            case "otp":
              final otp = await monaSDK.triggerPinOrOTPFlow(
                pinOrOtpType: PaymentTaskType.otp,
                taskModel: TransactionTaskModel.fromJSON(
                  json: task,
                ),
              );

              "🥰 PaymentService OTP WAS ENTERED ::: $otp".log();

              if (otp != null && otp.isNotEmpty) {
                monaSDK.setTransactionOTP(receivedOTP: otp);

                await makePaymentRequest(
                  paymentType: paymentType,
                  onPayComplete: onPayComplete,
                );
              } else {
                "User cancelled OTP entry".log();
              }
              break;

            default:
              "PAYMENT TASK FIELD".log();
              break;
          }
        }
      }
    }
  }

  ///
  /// ***
  FutureOutcome<Map<String, dynamic>> sendPaymentToServer({
    required Map<String, dynamic> payload,
    String? checkoutType,
    String? monaKeyId,
    String? monaCheckoutID,
    String? signature,
    String? nonce,
    String? timestamp,
  }) async {
    try {
      final response = await _apiService.post(
        APIEndpoints.pay,
        headers: ApiHeaders.paymentHeader(
          monaKeyID: monaKeyId,
          monaCheckoutID: monaCheckoutID,
          signature: signature,
          nonce: nonce,
          timestamp: timestamp,
          checkoutType: checkoutType,
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
    String userKeyID,
  ) async {
    final encodedPayload = base64Encode(utf8.encode(jsonEncode(payload)));

    Map<String, dynamic> data = {
      "method": base64Encode(utf8.encode("POST")),
      "uri": base64Encode(utf8.encode("/pay")),
      "body": encodedPayload,
      "params": base64Encode(utf8.encode(jsonEncode({}))),
      "nonce": base64Encode(utf8.encode(nonce)),
      "timestamp": base64Encode(utf8.encode(timestamp)),
      "keyId": base64Encode(utf8.encode(userKeyID)),
    };

    final dataString = base64Encode(utf8.encode(json.encode(data)));
    final hash = sha256.convert(utf8.encode(dataString)).toString();

    final String? signature = await BiometricService().signTransaction(
      hashedTXNData: hash,
    );

    return signature;
  }
}

enum TransactionPaymentTypes {
  bank('bank'),
  card('card');

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
