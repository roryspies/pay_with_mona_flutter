import 'package:basic_utils/basic_utils.dart';
import 'package:convert/convert.dart';
import 'package:encrypt/encrypt.dart';

class CryptoUtil {
  static const otherPublicKey = """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApXwFU8YtCfLGnE/YcgRK
JcL2G8aDM50f5blhgujFeLTrMxhQCLoO9HWOL9zcr+DyjVLxoNWvF2RAfJCWrMkv
6a3u21W19VkuHCKMsT872QHo2F8U+NmXXwzjIAElYqgUal0/2BHuvG9ko+azvMk2
RLGK5sZyJKK7iYZN0kosPtrHfEdUXm2eRy/9MKlTTqRx3UmdD4jTlvVEKjIzkKfM
to26uGrhBC1rGapeSPUHs0EoGXrzFzAn47Ua94Dg7TxlrwfRk2SfsCe7fQLma+mK
JokqEQibKB1XcWFSa6BoSrqQEdDLLHoASXgW0A3btPsK71v6c7F0E2zNlBV6D9Ka
aQIDAQAB
-----END PUBLIC KEY-----
""";

  static _getPublicKey() {
    return CryptoUtils.rsaPublicKeyFromPem(otherPublicKey);
  }

  static Future<String> encryptWithPublicKey({
    required String data,
  }) async {
    final enc = Encrypter(
      RSA(
        publicKey: _getPublicKey(),
        encoding: RSAEncoding.OAEP,
      ),
    );

    final result = enc.encrypt(data);
    return hex.encode(result.bytes);
  }
}
