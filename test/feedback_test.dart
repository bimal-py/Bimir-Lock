import 'package:bimir_lock/utils/constants.dart';
import 'package:bimir_lock/utils/helper/feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Bimir Lock',
      packageName: 'com.cklamib.bimirLock',
      version: '1.1.1',
      buildNumber: '5',
      buildSignature: '',
    );
  });

  test(
    'the report carries the version and warns against sending secrets',
    () async {
      final String subject = await AppFeedback.reportSubject();
      final String body = await AppFeedback.reportBody();
      expect(subject, 'Bimir Lock 1.1.1 (5): problem report');
      expect(body, contains('App: Bimir Lock 1.1.1 (5)'));
      expect(
        body,
        contains('Please never send a password, PIN or backup password'),
      );
      expect(body, contains('System: '));
    },
  );

  test('the store ids point at Bimir Lock', () {
    expect(StoreLink.appStoreId, '6821090857');
    expect(StoreLink.appStore, 'https://apps.apple.com/app/id6821090857');
    expect(StoreLink.googlePlay, endsWith('id=com.cklamib.bimirLock'));
  });
}
