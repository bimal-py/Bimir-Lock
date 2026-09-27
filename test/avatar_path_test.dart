import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageHelper.avatarFileName', () {
    test('reduces an old iOS absolute path to the file name', () {
      expect(
        StorageHelper.avatarFileName(
            '/var/mobile/Containers/Data/Application/5AF0E816-D0F1-4E6A-B342-01F9811F7B2E/Documents/imageFolder/image.jpg'),
        'image.jpg',
      );
    });

    test('reduces an old Android absolute path to the file name', () {
      expect(
        StorageHelper.avatarFileName(
            '/data/user/0/com.cklamib.bimirLock/databases/imageFolder/image.png'),
        'image.png',
      );
    });

    test('leaves a bare file name alone', () {
      expect(StorageHelper.avatarFileName('avatar_1727400000000.jpg'),
          'avatar_1727400000000.jpg');
    });
  });
}
