import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';

class AuthService {
  factory AuthService() => singleInstance;
  AuthService._internal();
  static AuthService singleInstance = AuthService._internal();

  /// ***
  final _apiService = ApiService();

  Future<PaymentUserType?> validatePhoneNumberAsMonaUser({
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        "/login/validate",
        headers: {
          "Content-Type": "application/json",
        },
        data: {
          'phoneNumber': phoneNumber,
        },
      );

      final responseInMap = response.data as Map<String, dynamic>;
      final isMonaUser = responseInMap["success"] as bool? ?? false;

      "Is Mona User: $isMonaUser".log();
      if (!isMonaUser) {
        return PaymentUserType.nonMonaUser;
      }

      return PaymentUserType.monaUser;
    } catch (error) {
      "$error".log();
      if (error.toString().toLowerCase().contains("404")) {
        return PaymentUserType.nonMonaUser;
      }

      return null;
    }
  }

  Future<Map<String, dynamic>?> loginWithStrongAuth({
    required String strongAuthToken,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        "/login",
        headers: {
          //"content-type": "application/json",
          "x-strong-auth-token": strongAuthToken,
          "x-mona-key-exchange": "true",
        },
      );

      final responseInMap = response.data as Map<String, dynamic>;
      responseInMap.log();

      return response.data as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  Future<Map<String, dynamic>?> commitKeys({
    required Map<String, dynamic> strongAuthToken,
  }) async {
    try {
      final response = await _apiService.post(
        "/keys/commit",
        headers: {
          "Content-Type": "application/json",
        },
      );

      final responseInMap = response.data as Map<String, dynamic>;
      responseInMap.log();

      return response.data as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  /* static Future<void> enrolLocalAuth2({
    required BuildContext context,
    required Map<String, dynamic> deviceAuth,
    required WidgetRef callingRef,
    PageController? setUpController,
    Function()? onSuccess,
    Function()? move,
    Function()? onBioError,
  }) async {
    log('_enrolLocalAuth');

    Prefs.setString(Prefs.xClientType, 'bioApp');

    String id = const Uuid().v4();
    Map<String, dynamic> payload = {
      "registrationToken": deviceAuth['registrationToken'],
      "attestationResponse": {
        "id": id,
        "rawId": id,
      }
    };

    try {
      if (Platform.isIOS) {
        //! to give face ID time to cook
        await Future.delayed(1500.milliseconds);
      }
      final String? publicKey = await getPublicKey();

      if (publicKey == null || publicKey.isEmpty) {
        onBioError?.call();
        return;
      }

      payload['attestationResponse']['publicKey'] = publicKey;

      // sign data
      String rawData = base64Encode(
          utf8.encode(jsonEncode(deviceAuth['registrationOptions'])));

      final String? signature = await generateSignature(rawData: rawData);

      if (signature == null || signature.isEmpty) {
        onBioError?.call();
        return;
      }
      payload['attestationResponse']['signature'] = signature;
      move?.call();
      // commit keys
      await getIt<IAuthFacade>().commitKeys(data: payload).then((res) {
        res.fold((failure) async {
          failure.map(
            serverError: (e) =>
                openSnackBar(context, e.msg, AnimatedSnackBarType.error),
            apiFailure: (e) {
              final message = switch (e.msg) {
                String msg => msg,
                Map<String, dynamic> map =>
                  map['errors']?.first ?? map['message'],
                _ => null
              };

              openSnackBar(
                context,
                message,
                AnimatedSnackBarType.error,
              );
              context.router.replaceAll([const LandingRoute()]);
            },
          );
        }, (res) async {
          // ref.read(loadingProvider.notifier).stop();

          if (res['success'] == true) {
            Prefs.setBool(Prefs.hasPasskey, true);

            ///Prefs.setString(Prefs.keyId, res['keyId']);
            Prefs.setString(
              "${callingRef.read(serverEnvironmentToggleProvider).currentEnvironment.label}_keyId",
              res['keyId'],
            );

            onSuccess?.call();

            return;
          }
        });
      });
    } on PlatformException catch (e) {
      log('$e');
      onBioError?.call();
      openSnackBar(context, 'An error occurred while signing keys',
          AnimatedSnackBarType.error);
      // ref.read(loadingProvider.notifier).stop();
    }
  } */
}
