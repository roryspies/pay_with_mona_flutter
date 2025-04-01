// import 'package:flutter_passkey/flutter_passkey.dart';

// Future<bool> checkForSafariCreatedPasskey() async {
//   final passkeys = FlutterPasskey();

//   try {
//     // The domain here MUST match the domain where the passkey was created in Safari
//     final credentials = await passkeys.getCredential('https://pay.mona.ng');

//     return credentials.isNotEmpty;
//   } catch (e) {
//     print('Error checking for passkeys: $e');
//     return false;
//   }
// }
