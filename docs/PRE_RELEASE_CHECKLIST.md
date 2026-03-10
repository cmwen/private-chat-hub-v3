# Pre-Release Checklist

Use this checklist before each release to ensure quality and completeness.

---

## Code Quality

- [ ] All tests passing
- [ ] Zero compilation errors
- [ ] `flutter analyze` passes with 0 issues
- [ ] Code formatted (`dart format .`)
- [ ] Release APK builds successfully
- [ ] No critical bugs or crashes
- [ ] Null safety maintained throughout

## Features Complete

- [ ] All planned features for this release implemented
- [ ] Feature acceptance criteria met (per user stories)
- [ ] Edge cases handled
- [ ] Error states display clear, actionable messages

## Provider Integration

- [ ] Self-hosted providers (Ollama) connecting correctly
- [ ] Cloud API providers authenticating and responding
- [ ] Local on-device models loading and running
- [ ] Model discovery working for all configured providers
- [ ] Fallback behavior working as designed
- [ ] Cost tracking accurate for paid providers

## UI/UX

- [ ] Material Design 3 implementation consistent
- [ ] Responsive layouts on different screen sizes
- [ ] Loading states and progress indicators present
- [ ] Dark/light theme both working
- [ ] Accessibility: screen reader labels on interactive elements
- [ ] Accessibility: minimum 48dp touch targets
- [ ] Accessibility: 4.5:1 color contrast ratio

## Security & Privacy

- [ ] No hardcoded credentials
- [ ] API keys stored in encrypted storage
- [ ] No data sent to external services without user consent
- [ ] Local-first data storage verified
- [ ] Network security config enforces HTTPS

## Documentation

- [ ] README.md updated with current features
- [ ] CHANGELOG updated with release notes
- [ ] API/architecture docs reflect current state
- [ ] User-facing help text accurate

## Build System

- [ ] CI/CD workflows passing
- [ ] Release signing configured
- [ ] APK size acceptable
- [ ] Build times acceptable

## Testing

- [ ] Unit tests for models and services
- [ ] Widget tests for UI components
- [ ] Integration tests for critical flows
- [ ] Manual testing on physical device

## Release Preparation

- [ ] Version bumped in pubspec.yaml
- [ ] Git tag created (e.g., `v1.0.0`)
- [ ] Release notes written
- [ ] Artifacts uploaded to GitHub Releases

## Verification Commands

```bash
flutter test                          # Run all tests
flutter analyze                       # Static analysis
flutter build apk --release           # Build release APK
flutter build appbundle --release     # Build App Bundle
```
