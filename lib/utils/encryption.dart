import 'package:encrypt/encrypt.dart';

class EncryptData {
//for AES Algorithms

  final key = 'Taal ko panni m@cchi le kh@nii..';

  Encrypted encryptAES(String plainText) {
    final cipherKey = Key.fromUtf8(key);
    // final iv = IV.fromLength(16);
    final iv = IV.fromUtf8("d@dB0dy311@??t!L");
    final encrypter = Encrypter(AES(cipherKey));
    Encrypted encryptedData = encrypter.encrypt(plainText, iv: iv);
    // print(encryptedData.base64);
    return encryptedData;
  }

  String decryptAES(Encrypted encryptedData) {
    final cipherKey = Key.fromUtf8(key);
    // final iv = IV.fromLength(16);
    final iv = IV.fromUtf8("d@dB0dy311@??t!L");
    final encrypter = Encrypter(AES(cipherKey));
    var decrypted = encrypter.decrypt(encryptedData, iv: iv);
    // print(decrypted);
    return decrypted;
  }

  // final decrypted = encrypter.decrypt(encrypt.Encrypted.fromBase64(encrypted),iv:iv);
}
