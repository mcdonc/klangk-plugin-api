import 'package:flutter_test/flutter_test.dart';
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

void main() {
  group('openUrl', () {
    test('routes through testOpenUrlOverride when set', () {
      final opened = <String>[];
      testOpenUrlOverride = opened.add;
      addTearDown(() => testOpenUrlOverride = null);
      openUrl('https://example.com');
      expect(opened, ['https://example.com']);
    });

    test('is a no-op on the VM when no override is set', () {
      // Stub platform (VM test): openUrlInBrowser is a no-op, so this must
      // not throw and opens nothing.
      testOpenUrlOverride = null;
      openUrl('https://example.com');
    });
  });
}
