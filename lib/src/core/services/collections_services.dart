import 'dart:convert';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api/api_service.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

class CollectionsService {
  // ignore: unused_field
  final _repoName = "💸 CollectionsService::: ";
  CollectionsService._internal();
  static final CollectionsService _instance = CollectionsService._internal();
  factory CollectionsService() => _instance;

  final _apiService =
      ApiService(baseUrl: 'https://d453-105-113-57-186.ngrok-free.app');

  final token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZDhhOTRlZjgzMmQzMTkzMjBiYjgzMiIsImlhdCI6MTc0NzMxNTUxNSwiZXhwIjoxNzQ3NDAxOTE1fQ.3f1968umsKYflsX583O5Fh6H4LkVyqyFQg9ChUoqQCg';

  /// Initiates a checkout session.
  FutureOutcome<Map<String, dynamic>> createCollections({
    required String bankId,
    required String maximumAmount,
    required String expiryDate,
    required String startDate,
    required String monthlyLimit,
    required String reference,
    required String type,
    required String frequency,
    required String? amount,
    required String merchantId,
    required List<Map<String, dynamic>> scheduleEntries,
  }) async {
    try {
      final response = await _apiService.post('/collections', data: {
        "bankId": bankId,
        "maximumAmount": maximumAmount,
        "expiryDate": expiryDate,
        "startDate": startDate,
        "monthlyLimit": monthlyLimit,
        "reference": reference,
        "debitType": "MERCHANT",
        "schedule": {
          "type": type,
          "frequency": frequency,
          "amount": amount,
          "entries": type == 'SCHEDULED' ? scheduleEntries : []
        }
      }, headers: {
        "x-merchant-Id": merchantId,
        "Authorization": "Bearer $token"
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
    try {
      final response = await _apiService.put(
        '/collections/trigger',
        data: {
          "userId": "67d8a94ef832d319320bb832",
          "timeFactor": timeFactor,
        },
        headers: {
          "x-merchant-Id": merchantId,
          "Authorization": "Bearer $token"
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
