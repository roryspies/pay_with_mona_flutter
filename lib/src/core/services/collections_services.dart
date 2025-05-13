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
      ApiService(baseUrl: 'https://1214-102-89-46-165.ngrok-free.app');

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
        "Authorization":
            "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZDhhOTRlZjgzMmQzMTkzMjBiYjgzMiIsImlhdCI6MTc0NzE0OTgyNSwiZXhwIjoxNzQ3MjM2MjI1fQ.lobAONjFB2KTJxSl72RSbBBlebgBxTh5R03CQZyH8O8"
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
  }) async {
    try {
      final response = await _apiService.put(
        '/collections/trigger',
        data: {
          "userId": "67d8a94ef832d319320bb832",
        },
        headers: {
          "x-merchant-Id": merchantId,
          "Authorization":
              "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZDhhOTRlZjgzMmQzMTkzMjBiYjgzMiIsImlhdCI6MTc0NzA2MzE2OSwiZXhwIjoxNzQ3MTQ5NTY5fQ.ngrLdmQr6Got7-H-zpSWnzPQ0ApPl7apW0utFO3aghQ"
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
