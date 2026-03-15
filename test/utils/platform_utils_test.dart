import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/utils/platform_utils.dart';

void main() {
  group('platform layout helpers', () {
    test('isWideLayout returns false below desktop breakpoint', () {
      expect(isWideLayout(desktopNavigationBreakpoint - 1), isFalse);
    });

    test('isWideLayout returns true at desktop breakpoint', () {
      expect(isWideLayout(desktopNavigationBreakpoint), isTrue);
      expect(isWideLayout(1280), isTrue);
    });
  });
}
