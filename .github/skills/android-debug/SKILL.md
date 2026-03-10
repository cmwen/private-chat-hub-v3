---
name: android-debug
description: Debug Android Flutter app runtime errors, crashes, device issues, and performance problems
---

# Android App Debugging

Expert guidance for debugging Android Flutter applications — runtime errors, device connectivity, and performance.

## When to Use

- App crashes or runtime errors on Android
- Device/emulator connection issues
- Performance problems (lag, memory, battery)
- Platform channel issues
- Native Android integration bugs

## Diagnostic Workflow

### 1. Gather Information
```bash
flutter doctor -v          # System check
flutter devices            # Connected devices
flutter run --verbose      # Verbose app launch
flutter logs               # App logs (or: adb logcat)
```

### 2. Device Connection
```bash
adb devices                          # List devices
adb kill-server && adb start-server  # Restart ADB
adb connect <ip>:5555               # Network device
```

### 3. Runtime Debugging
```bash
flutter run -d <device-id> --verbose  # Run with logging
flutter run --profile                 # Profile mode
flutter run --profile --trace-skia    # Skia tracing
```

### 4. Log Analysis
```bash
flutter logs | grep -i "flutter"     # Filter Flutter logs
adb logcat -s flutter                # Android-specific
adb logcat -c                        # Clear logs
adb logcat > debug.log               # Save to file
```

## Common Issues

### App Crashes on Startup
1. Check logs: `flutter logs`
2. Look for stack traces in logcat
3. Verify AndroidManifest.xml permissions
4. Check minSdkVersion in `android/app/build.gradle.kts`

### UI Lag / Jank
```bash
flutter run --profile
flutter run --profile --trace-skia
```
- Use Flutter DevTools Timeline tab
- Check for expensive operations in build methods
- Add `const` constructors, use `RepaintBoundary`

### Memory Leaks
- Use DevTools Memory tab
- Check for undisposed controllers
- Review image caching strategy
- Look for retained references in closures

### Large APK Size
```bash
flutter build apk --analyze-size
```
- Enable R8 shrinking in build configuration
- Check for unused dependencies in pubspec.yaml

## DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```
Features: Widget Inspector, Timeline, Memory, Network, Logging, Debugger

## ADB Quick Reference
```bash
adb shell screencap /sdcard/screen.png && adb pull /sdcard/screen.png  # Screenshot
adb shell am force-stop <package-id>                                    # Force stop
adb shell pm clear <package-id>                                         # Clear data
```
