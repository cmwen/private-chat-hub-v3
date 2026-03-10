---
name: ci-debug
description: Debug GitHub Actions workflow failures, CI build issues, test failures in CI, and deployment problems
---

# CI / GitHub Actions Debugging

Expert guidance for debugging GitHub Actions workflows and CI-specific issues for this Flutter Android project.

## When to Use

- GitHub Actions workflow failures
- CI build errors that don't occur locally
- Test failures only in CI
- Artifact upload/download issues
- Secret/credential problems
- Cache-related failures

## Debugging Steps

### 1. Access Logs
```bash
gh run list --limit 10        # Recent runs
gh run view <run-id>          # View specific run
gh run download <run-id>      # Download logs
```

### 2. Common Failures

**Flutter/Dart Setup**: Check flutter-action version in workflow matches project needs.

**Java Version**: Verify `setup-java` action uses the correct Java version.

**Gradle OOM**: CI environments need reduced memory settings. Use CI-specific Gradle properties with reduced heap and workers, daemon disabled.

**Dependency Resolution**: Clear cache by changing cache key. Check `pubspec.yaml` validity.

**Test Failures (CI-only)**:
- Timing issues — ensure proper `await` usage
- File paths must be relative, not absolute
- No external service dependencies
- Check timezone/locale differences

**Cache Issues**: Verify cache key uses `hashFiles('**/pubspec.lock')`. 10GB limit per repo.

**Auto-format Commit**: Requires `GITHUB_TOKEN` write permissions. Only runs on same-repo PRs.

### 3. Release Issues

**Missing Secrets** (required for signed release builds):
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

**Tag Not Triggering**: Release tags must follow the configured pattern (e.g., `v*`).

## Local CI Simulation
```bash
flutter clean && flutter pub get
dart format . && dart fix --apply
flutter analyze
flutter test --coverage
flutter build apk --release && flutter build appbundle --release
```

## Quick Checklist

- Flutter version matches workflow config?
- Java version correct?
- Gradle properties configured for CI?
- All required secrets are set?
- Tests pass locally with same commands?
- Cache keys match lock file?
- Artifact paths match build output?
