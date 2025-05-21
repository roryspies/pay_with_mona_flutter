// import 'package:flutter/material.dart';
// import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
// import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
// import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
// import 'package:pay_with_mona/src/models/mona_checkout.dart';
// import 'package:pay_with_mona/src/utils/extensions.dart';
// import 'package:pay_with_mona/ui/utils/size_config.dart';
// import 'dart:math' as math;

// class CollectionsNotifier extends ChangeNotifier {
//   static final _instance = CollectionsNotifier._internal();
//   factory CollectionsNotifier() => _instance;
//   CollectionsNotifier._internal({
//     // CollectionsService? paymentsService,
//     AuthService? authService,
//     SecureStorage? secureStorage,
//   })  :
//         //  _paymentsService = paymentsService ?? CollectionsService(),
//         _authService = authService ?? AuthService(),
//         _secureStorage = secureStorage ?? SecureStorage();

//   // final CollectionsService _paymentsService;
//   final AuthService _authService;
//   String? _errorMessage;
//   String? _currentTransactionId;
//   String? _strongAuthToken;
//   MonaCheckOut? _monaCheckOut;
//   BuildContext? _callingBuildContext;
//   SecureStorage _secureStorage;
//   CollectionsState _state = CollectionsState.idle;
//   CollectionsMethod _selectedCollectionsMethod = CollectionsMethod.none;
//   final _firebaseSSE = FirebaseSSEListener();

//   /// ***
//   CollectionsState get state => _state;
//   CollectionsMethod get selectedCollectionsMethod => _selectedCollectionsMethod;
//   String? get errorMessage => _errorMessage;
//   String? get currentTransactionId => _currentTransactionId;

//   /// ***
//   void disposeSSEListener() {
//     _firebaseSSE.dispose();
//   }

//   void _setState(CollectionsState newState) {
//     _state = newState;
//     notifyListeners();
//   }

//   void _setError(String message) {
//     _errorMessage = message;
//     _setState(CollectionsState.error);
//   }

//   void _setTransactionId(String transactionId) {
//     _currentTransactionId = transactionId;
//     notifyListeners();
//   }

//   void setMonaCheckOut({
//     required MonaCheckOut checkoutDetails,
//   }) {
//     _monaCheckOut = checkoutDetails;
//     notifyListeners();
//   }

//   void setCallingBuildContext({
//     required BuildContext context,
//   }) {
//     _callingBuildContext = context;
//     notifyListeners();
//   }

//   void setSelectedCollectionsType({
//     required CollectionsMethod selectedCollectionsMethod,
//   }) {
//     _selectedCollectionsMethod = selectedCollectionsMethod;
//     notifyListeners();
//   }
// }
