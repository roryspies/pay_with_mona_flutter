// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
// import 'package:mobile_device_identifier/mobile_device_identifier.dart';
// import 'package:pay_with_mona/src/core/device_Info/app_device_information.dart';
// import 'package:pay_with_mona/src/core/firebase_sse_listener.dart';
// import 'package:pay_with_mona/src/features/auth/auth_service.dart';
// import 'package:pay_with_mona/src/models/mona_checkout.dart';
// import 'package:pay_with_mona/src/utils/extensions.dart';
// import 'package:pay_with_mona/src/utils/size_config.dart';
// import 'package:platform_device_id_plus/platform_device_id.dart';
// import 'dart:math' as math;

// enum AuthState { idle, loading, success, error }

// class AuthNotifier extends ChangeNotifier {
//   AuthState _state = AuthState.idle;
//   String? _errorMessage;
//   String? _deviceId;

//   final AuthService _authService;
//   final FirebaseSSEListener _firebaseSSE = FirebaseSSEListener();

//   AuthState get state => _state;
//   String? get errorMessage => _errorMessage;
//   String? get deviceId => _deviceId;

//   AuthNotifier({AuthService? authService})
//       : _authService = authService ?? AuthService();

//   AppBaseDeviceInfo deviceInfo = AppBaseDeviceInfo();

//   void getDeviceId() async {
//     final DeviceInformation deviceInformation =
//         await AppDeviceInformation.initialize();
//     deviceInfo.installGlobalDeviceInfo(deviceInformation);
//     // _setState(AuthState.loading);

//     final String? deviceId = await PlatformDeviceId.getDeviceId;
//     if (deviceId != null) {
//       _deviceId = deviceId;
//       'THE NEW NEW DEVICE ID IS: $deviceId'.log();
//       notifyListeners();
//     } else {
//       _setError("Failed to get device ID");
//     }
//   }

//   Future<void> checkForMonaUser({
//     required String phoneNumber,
//   }) async {
//     _setState(AuthState.loading);
//     final (Map<String, dynamic>? success, failure) =
//         await _authService.checkForMonaUser(phoneNumber: phoneNumber);
//     if (failure != null) {
//       _setError("Mona user check failed. Try again.");
//     } else if (success != null) {
//       '$success'.log();

//       _setState(AuthState.success);
//     }
//   }

//   Future<void> fetchLoginScope({
//     required String merchantId,
//     required String keyId,
//   }) async {
//     _setState(AuthState.loading);
//     final (Map<String, dynamic>? success, failure) = await _authService
//         .fetchLoginScope(merchantId: merchantId, keyId: keyId);
//     if (failure != null) {
//       _setError("Fetching login scope failed. Try again.");
//     } else if (success != null) {
//       '$success'.log();

//       _setState(AuthState.success);
//     }
//   }

//   void _setState(AuthState newState) {
//     _state = newState;
//     notifyListeners();
//   }

//   void _setError(String message) {
//     _errorMessage = message;
//     _setState(AuthState.error);
//   }

//   Future<void> checkCookie({
//     required BuildContext context,
//     required MonaCheckOut monaCheckOut,
//   }) async {
//     _setState(AuthState.loading);

//     // String transactionId = monaCheckOut.transactionId;
//     final String token = 'key-id_${math.Random.secure().nextInt(999999999)}';

//     bool hasError = false;

//     _firebaseSSE.initialize(
//         databaseUrl:
//             'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app');

//     _firebaseSSE.startListeningg(
//       onDataChange: (Map<String, dynamic> event) async {
//         // Extract the event and timestamp from the data map
//         final keyId = event['keyId'];
//         final phone = event['phone'];
//         final userId = event['userId'];
//         final timestamp = event['timestamp'];

//         // Log the event and timestamp
//         '🔥 [SSEListener] Event Received: $keyId at $timestamp'.log();

//         if (keyId != null &&
//             keyId.isNotEmpty &&
//             userId != null &&
//             userId.isNotEmpty) {
//           _firebaseSSE.dispose();
//           // closeCustomTabs();
//           await Future.delayed(Duration(seconds: 5)).then((_) {
//             closeCustomTabs();
//           });
//           fetchLoginScope(merchantId: '', keyId: keyId);
//         }
//       },
//       onError: (error) {
//         '❌ [SSEListener] Error: $error'.log();
//         _setError('');
//         hasError = true;
//       },
//     );

//     if (hasError) {
//       'had errror'.log();
//       return;
//     }

//     String loginScope = base64Encode(utf8.encode(monaCheckOut.merchantId));

//     // String url = 'https://pay.mona.ng/keys?token=$token';
//     String url =
//         'https://pay.development.mona.ng/login?xMonaLoginScope=$loginScope';
//     'url: $url'.log();

//     url.log();

//     await launchUrl(
//       Uri.parse(url),
//       customTabsOptions: CustomTabsOptions.partial(
//         shareState: CustomTabsShareState.off,
//         configuration: PartialCustomTabsConfiguration(
//           initialHeight: context.screenHeight * 0.95,
//           activityHeightResizeBehavior:
//               CustomTabsActivityHeightResizeBehavior.fixed,
//         ),
//         colorSchemes: CustomTabsColorSchemes.defaults(
//           toolbarColor: monaCheckOut.primaryColor,
//           navigationBarColor: monaCheckOut.primaryColor,
//         ),
//         showTitle: false,
//       ),
//       safariVCOptions: SafariViewControllerOptions.pageSheet(
//         configuration: const SheetPresentationControllerConfiguration(
//           detents: {
//             SheetPresentationControllerDetent.large,
//             // SheetPresentationControllerDetent.medium,
//           },
//           prefersScrollingExpandsWhenScrolledToEdge: true,
//           prefersGrabberVisible: false,
//           prefersEdgeAttachedInCompactHeight: true,
//         ),
//         preferredBarTintColor: monaCheckOut.primaryColor,
//         preferredControlTintColor: monaCheckOut.primaryColor,
//         dismissButtonStyle: SafariViewControllerDismissButtonStyle.done,
//       ),
//     );

//     _setState(AuthState.success);
//   }
// }
