import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api/api_service.dart';
import 'package:pay_with_mona/src/core/generators/uuid_generator.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometrics_service.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

class CollectionsService {
  // ignore: unused_field
  final _repoName = "💸 CollectionsService::: ";
  CollectionsService._internal();
  static final CollectionsService _instance = CollectionsService._internal();
  factory CollectionsService() => _instance;

  final _apiService = ApiService();

  final _merchantId = "67e41f884126830aded0b43c";

  final _secureStorage = SecureStorage();

  Future<String?> getMerchantKey() async {
    return await _secureStorage.read(
      key: SecureStorageKeys.merchantKey,
    );
  }

  FutureOutcome<Map<String, dynamic>> validateCreateCollectionFields({
    Function? onComplete,
    void Function()? onError,
    required String maximumAmount,
    required String expiryDate,
    required String startDate,
    required String monthlyLimit,
    required String reference,
    required String type,
    required String frequency,
    required String? amount,
    required String debitType,
    required List<Map<String, dynamic>> scheduleEntries,
    required String scrtK,
  }) async {
    final payload = {
      "maximumAmount": multiplyBy100(maximumAmount),
      "expiryDate": expiryDate,
      "startDate": startDate,
      // "monthlyLimit": multiplyBy100(monthlyLimit),
      "reference": reference,
      "debitType": debitType,
      "schedule": {
        "type": type,
        "frequency": frequency,
        "amount": amount != null ? multiplyBy100(amount) : null,
        "entries": type == 'SCHEDULED' ? scheduleEntries : []
      }
    };

    try {
      final response = await _apiService.post(
        '/collections',
        data: payload,
        headers: {
          "x-secret-key": scrtK,
        },
      );

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ validateCreateCollectionFields() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  /// Initiates a checkout session.
  FutureOutcome<Map<String, dynamic>> createCollections({
    required Map<String, dynamic> payload,
    String? monaKeyId,
    String? signature,
    String? nonce,
    String? timestamp,
  }) async {
    try {
      final response = await _apiService
          .post('/collections/consent', data: payload, headers: {
        "x-merchant-Id": _merchantId,
        "x-client-type": "bioApp",
        if (monaKeyId != null) 'x-mona-key-id': monaKeyId,
        if (signature != null) 'x-mona-pay-auth': signature,
        if (nonce != null) 'x-mona-nonce': nonce,
        if (timestamp != null) 'x-mona-timestamp': timestamp,
      });

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ createCollections() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  FutureOutcome<Map<String, dynamic>> triggerCollection({
    required String merchantId,
    required int timeFactor,
  }) async {
    final secureStorage = SecureStorage();
    final monaKeyID = await secureStorage.read(
          key: SecureStorageKeys.keyID,
        ) ??
        "";
    try {
      final response = await _apiService.put(
        '/collections/trigger',
        data: {
          "userId": "67d8a94ef832d319320bb832",
          "timeFactor": timeFactor,
        },
        headers: {
          "x-merchant-Id": merchantId,
          'x-mona-key-id': monaKeyID,
        },
      );

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ createCollections() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  Future<String?> _signRequest(
    Map<String, dynamic> payload,
    String nonce,
    String timestamp,
    String keyId,
  ) async {
    "$_repoName _signCreateCollectionRequest".log();

    final encodedPayload = base64Encode(utf8.encode(jsonEncode(payload)));

    Map<String, dynamic> data = {
      "method": base64Encode(utf8.encode("POST")),
      "uri": base64Encode(utf8.encode("/collections/consent")),
      "body": encodedPayload,
      "params": base64Encode(utf8.encode(jsonEncode({}))),
      "nonce": base64Encode(utf8.encode(nonce)),
      "timestamp": base64Encode(utf8.encode(timestamp)),
      "keyId": base64Encode(utf8.encode(keyId)),
    };

    final dataString = base64Encode(utf8.encode(json.encode(data)));
    final hash = sha256.convert(utf8.encode(dataString)).toString();

    final String? signature = await BiometricService().signTransaction(
      hashedTXNData: hash,
    );

    return signature;
  }

  Future<void> createCollectionRequest({
    bool sign = false,
    Function? onComplete,
    void Function()? onError,
    required String bankId,
    required String accessRequestId,
  }) async {
    try {
      final secureStorage = SecureStorage();
      final payload = {
        "bankId": bankId,
        "accessRequestId": accessRequestId,
      };
      final monaKeyID = await secureStorage.read(
            key: SecureStorageKeys.keyID,
          ) ??
          "";

      final nonce = UUIDGenerator.v4();
      final timestamp =
          DateTime.now().toLocal().millisecondsSinceEpoch.toString();

      "$_repoName createCollectionRequest REQUESTING TO SIGN Create collection ==>> PAY LOAD TO BE SIGNED ==>> $payload"
          .log();

      String? signature = await _signRequest(
        payload,
        nonce,
        timestamp,
        monaKeyID,
      );

      if (signature == null) {
        "$_repoName createCollectionRequest SIGNATURE IS NULL OR CANCELLED"
            .log();

        return;
      }

      await submitCreateCollectionRequest(
        payload,
        onComplete: onComplete,
        monaKeyId: monaKeyID,
        signature: signature,
        nonce: nonce,
        timestamp: timestamp,
      );
    } catch (e) {
      onError?.call();
      return;
    }
  }

  Future<void> submitCreateCollectionRequest(
    Map<String, dynamic> payload, {
    required Function? onComplete,
    String? monaKeyId,
    String? signature,
    String? nonce,
    String? timestamp,
  }) async {
    "$_repoName submitPaymentRequest REACHED SUBMISSION".log();

    final (res, failure) = await createCollections(
      payload: payload,
      monaKeyId: monaKeyId,
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
      if (onComplete != null) {
        onComplete(res, payload);
      }

      return;
    }
  }

  FutureOutcome<Map<String, dynamic>> fetchCollections({
    required String bankId,
  }) async {
    final secureStorage = SecureStorage();
    final monaKeyID = await secureStorage.read(
          key: SecureStorageKeys.keyID,
        ) ??
        "";
    try {
      final response = await _apiService.get(
        '/collections',
        queryParams: {
          "bankId": bankId,
        },
        headers: {
          "x-merchant-Id": _merchantId,
          'x-mona-key-id': monaKeyID,
        },
      );

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ createCollections() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }
}

String multiplyBy100(String value) {
  final number = double.tryParse(value) ?? 0;
  final result = number * 100;
  return result.toStringAsFixed(0);
}

String divideBy100(String value) {
  final number = double.tryParse(value) ?? 0;
  final result = number / 100;
  return result.toStringAsFixed(2);
}

String divideBy100NoDecimal(String value) {
  final number = double.tryParse(value) ?? 0;
  final result = number / 100;
  return result.toStringAsFixed(0);
}
