---
name: build-fix
description: Diagnose and fix Flutter build failures including dependency conflicts, Gradle errors, compilation issues, and platform-specific build problems
---

# Build Failure Diagnosis and Fix

Expert guidance for diagnosing and fixing Flutter build failures in Android projects.

## When to Use

- `flutter build apk` or `flutter build appbundle` fails
- Gradle sync/build errors
- Dependency resolution failures
- Dart or Kotlin/Java compilation errors
- Plugin integration issues
- Version conflicts

## Build Stages

Flutter Android builds go through these stages:
1. **Dependency Resolution** (`flutter pub get`)
2. **Dart Compilation** (`flutter build`)
3. **Gradle Configuration** (Android build system)
4. **Resource Processing** (R8, ProGuard)
5. **Native Compilation** (Kotlin/Java)
6. **Packaging** (APK/AAB creation)

Identify which stage is failing first.

## Systematic Debug Approach

### Level 1: Quick Fix
```bash
flutter clean
flutter pub get
flutter build apk --verbose
```

### Level 2: Gradle Reset
```bash
cd android && ./gradlew clean && ./gradlew --stop && cd ..
flutter clean && flutter pub get
flutter build apk --verbose
```

### Level 3: Cache Clear
```bash
flutter clean
rm -rf ~/.gradle/caches/
flutter pub cache repair
flutter pub get
flutter build apk --verbose
```

### Level 4: Deep Dive
```bash
flutter doctor -v
java -version
cd android && ./gradlew app:dependencies
./gradlew assembleRelease --stacktrace --info
```

## Common Failures

### Dependency Conflicts
- Check `pubspec.yaml` version constraints
- Run `flutter pub outdated` and `flutter pub upgrade`
- Check `android/app/build.gradle.kts` for Android dependency versions

### Gradle Issues
- Verify Java version: `java -version`
- Update wrapper: `cd android && ./gradlew wrapper --gradle-version=8.0`
- Check memory in `android/gradle.properties`

### R8/ProGuard Issues
- Add keep rules in `android/app/proguard-rules.pro`
- Temporarily disable shrinking to test: `shrinkResources false`

### Manifest Merge Failures
- Check `android/app/src/main/AndroidManifest.xml`
- Use `tools:replace` or `tools:merge` attributes for conflicts

## Quick Reference

```bash
flutter clean && flutter pub get && flutter build apk  # Clean build
flutter build apk --verbose                             # Verbose build
flutter pub outdated                                    # Check deps
dart fix --apply && flutter analyze                     # Fix and analyze
flutter doctor -v                                       # System check
```
