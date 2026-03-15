import 'package:flutter/foundation.dart';

const double desktopNavigationBreakpoint = 960;
const double desktopPageMaxWidth = 760;
const double desktopMessageMaxWidth = 760;

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };
}

bool isWideLayout(double width) => width >= desktopNavigationBreakpoint;
