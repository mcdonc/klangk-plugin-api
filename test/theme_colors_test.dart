import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klangk_plugin_api/klangk_plugin_api.dart';

void main() {
  group('KColors', () {
    test('exposes the documented dark-theme tokens', () {
      expect(KColors.bgCanvas, const Color(0xFF0D1117));
      expect(KColors.accentBlue, const Color(0xFF58A6FF));
      expect(KColors.accentGreen, const Color(0xFF238636));
    });

    test('colorForString is stable for the same input', () {
      expect(
        KColors.colorForString('alice'),
        equals(KColors.colorForString('alice')),
      );
    });

    test('colorForString differs across distinct inputs', () {
      // Different inputs need not always differ, but two common names map to
      // different hues — assert the hash→hue mapping is not constant.
      expect(
        KColors.colorForString('alice'),
        isNot(equals(KColors.colorForString('bob'))),
      );
    });
  });
}
