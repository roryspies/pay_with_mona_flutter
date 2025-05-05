import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/core/signatures.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> signAndCommitAuthKeys({
    required Map<String, dynamic> deviceAuth,
    Function()? onSuccess,
    Function()? move,
    Function()? onBioError,
  }) async {
    final signatureService = BiometricSignatureHelper();
    ('_enrolLocalAuth').log();

    final id = const Uuid().v4();
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
        await Future.delayed(Duration(seconds: 1));
      }
      final publicKey = await signatureService.generatePublicKey();

      if (publicKey == null || publicKey.isEmpty) {
        onBioError?.call();
        return;
      }

      payload['attestationResponse']['publicKey'] = publicKey;

      // sign data
      final rawData = base64Encode(
        utf8.encode(
          jsonEncode(
            deviceAuth['registrationOptions'],
          ),
        ),
      );

      final signature = await signatureService.createSignature(
        rawData: rawData,
      );

      if (signature == null || signature.isEmpty) {
        onBioError?.call();
        return;
      }

      payload['attestationResponse']['signature'] = signature;
      move?.call();

      // commit keys
      final response = await commitKeys(
        data: payload,
      );

      if (response == null) {
        onBioError?.call();
        return;
      }

      if (response['success'] == true) {
        //Prefs.setBool(Prefs.hasPasskey, true);

        ///Prefs.setString(Prefs.keyId, res['keyId']);
        /* Prefs.setString(
          "${callingRef.read(serverEnvironmentToggleProvider).currentEnvironment.label}_keyId",
          res['keyId'],
        ); */

        onSuccess?.call();

        return;
      }
    } on PlatformException catch (e) {
      ('$e').log();
      onBioError?.call();
    }
  }

  Future<Map<String, dynamic>?> commitKeys({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiService.post(
        "/keys/commit",
        headers: {
          "Content-Type": "application/json",
        },
        data: data,
      );

      final responseInMap = response.data as Map<String, dynamic>;
      responseInMap.log();

      return response.data as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  /* static Future<void> enrolPasskey2({
    required BuildContext context,
    required WidgetRef ref,
    PageController? setupPageController,
    Function()? onEnrol,
    Function()? onError,
  }) async {
    ref.read(loadingProvider.notifier).start("Please wait....");

    FlutterSecureStorage storage = const FlutterSecureStorage();

    try {
      var onboarding = ref.watch(onboardingProvider);
      String registrationToken = onboarding.registrationToken;
      var registrationOptions = onboarding.registrationOptions;

      Prefs.setString(Prefs.xClientType, 'fidoApp');

      // Initialize Pusher
      var pusher = await PusherUtil.init();
      bool registrationSuccess = false;

      await pusher.subscribe(
        channelName: 'authn_$registrationToken',
        onEvent: (pusherEvent) async {
          try {
            PusherEvent event = pusherEvent as PusherEvent;
            log('event::: $event');

            if (event.eventName == 'pusher:subscription_succeeded') {
              ref.read(loadingProvider.notifier).stop();

              Map options = {
                'registrationToken': registrationToken,
                'registrationOptions': registrationOptions
              };
              String url =
                  '${ref.read(serverEnvironmentToggleProvider).currentEnvironment.payUrl}/register?passkey=${Uri.encodeQueryComponent(jsonEncode(options))}';
              /* String url =
                  '${ENV.payUrl}/register?passkey=${Uri.encodeQueryComponent(jsonEncode(options))}'; */

              final theme = Theme.of(context);
              try {
                await launchUrl(
                  Uri.parse(url),
                  customTabsOptions: CustomTabsOptions.partial(
                    configuration: PartialCustomTabsConfiguration(
                      initialHeight: 20.h,
                      activityHeightResizeBehavior:
                          CustomTabsActivityHeightResizeBehavior.fixed,
                    ),
                    colorSchemes: CustomTabsColorSchemes.defaults(
                      toolbarColor: theme.colorScheme.surface,
                    ),
                    showTitle: true,
                  ),
                  safariVCOptions: SafariViewControllerOptions.pageSheet(
                    configuration:
                        const SheetPresentationControllerConfiguration(
                      detents: {
                        SheetPresentationControllerDetent.large,
                        SheetPresentationControllerDetent.medium,
                      },
                      prefersScrollingExpandsWhenScrolledToEdge: true,
                      prefersGrabberVisible: true,
                      prefersEdgeAttachedInCompactHeight: true,
                    ),
                    preferredBarTintColor: theme.colorScheme.surface,
                    preferredControlTintColor: theme.colorScheme.onSurface,
                    dismissButtonStyle:
                        SafariViewControllerDismissButtonStyle.close,
                  ),
                );

                Future.delayed(const Duration(seconds: 2), () async {
                  onError?.call();
                });
              } catch (e) {
                debugPrint("Launch URL failed: ${e.toString()}");
                onError?.call();
              }
            }

            if (event.eventName == 'registration_success') {
              registrationSuccess = true;
              ref.read(loadingProvider.notifier).stop();
              onEnrol?.call();
              await closeCustomTabs();

              Map<String, dynamic> eventData = jsonDecode(event.data);
              String strongAuthToken = eventData['strongAuthToken'];

              pusher.disconnect();

              String? phone = await storage.read(
                key: Prefs.PHONE,
                iOptions: AppUtil.getIOSOptions(),
                aOptions: AppUtil.getAndroidOptions(),
              );

              await doLoginExistingNN(
                context: context,
                ref: ref,
                strongAuthToken: strongAuthToken,
                setupPageController: setupPageController,
                payload: {
                  'phone': phone,
                },
              );
            }
          } catch (e) {
            debugPrint("Error in Pusher event handler: ${e.toString()}");
            onError?.call();
          }
        },
      );

      await pusher.connect();
    } catch (e) {
      debugPrint("Error in enrolPasskey2: ${e.toString()}");
      onError?.call();
      ref.read(loadingProvider.notifier).stop();
    }
  } */
}
