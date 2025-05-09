import 'dart:convert';

import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api/api_service.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

class CollectionsService {
  final _repoName = "💸 CollectionsService::: ";
  CollectionsService._internal();
  static final CollectionsService _instance = CollectionsService._internal();
  factory CollectionsService() => _instance;

  final _apiService =
      ApiService(baseUrl: 'https://3dab-105-113-103-231.ngrok-free.app//');

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
  }) async {
    try {
      final response = await _apiService.post(
        '/collections',
        data: {
          "bankId": bankId,
          "maximumAmount": maximumAmount,
          "expiryDate": expiryDate,
          "startDate": startDate,
          "monthlyLimit": monthlyLimit,
          "reference": reference,
          "schedule": {
            "type": type,
            "frequency": frequency,
            "amount": amount,
            if (type == 'VARIABLE')
              "entries": [
                {
                  "date": "2025-06-15T00:00:00.000Z",
                  "amount": "2000",
                },
                {
                  "date": "2025-07-01T00:00:00.000Z",
                  "amount": "3000",
                }
              ]
          }
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
