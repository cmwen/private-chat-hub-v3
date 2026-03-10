# Contributing to Private Chat Hub

Thank you for considering contributing to Private Chat Hub!

## Getting Started

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your changes
4. **Make changes**, test, and submit a PR

## Development Workflow

### Reporting Issues

- Check if the issue already exists
- Provide clear reproduction steps
- Include your environment details (OS, Flutter version, Dart version)
- Share relevant error messages or logs

### Pull Requests

1. **Fork** the repository
2. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**:
   - Follow existing code style
   - Update documentation if needed
   - Keep changes minimal and focused
4. **Test your changes**:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```
5. **Commit your changes**:
   ```bash
   git commit -m "Brief description of changes"
   ```
6. **Push to your fork** and open a Pull Request

### Code Style Guidelines

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use Flutter best practices and widget composition
- Maintain null safety throughout
- Use `const` constructors when possible
- Separate business logic from UI (services/ vs screens/)
- Write testable code with dependency injection

> **Note**: CI auto-formats code on push. You don't need to run `dart format` manually.

### Commit Message Format

```
Brief summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what changed and why, not how.

- Use present tense: "Add feature" not "Added feature"
```

## AI Agent Workflows

This project includes AI agent configurations for both OpenCode and GitHub Copilot. See `AGENTS.md` for details on:
- 6 specialized agents (product-owner, architect, flutter-developer, researcher, doc-writer, experience-designer)
- 4 reusable skills (build-fix, android-debug, ci-debug, icon-generation)

### Before Submitting a PR

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `flutter build apk` succeeds
- [ ] Documentation updated (if applicable)

## Questions?

Open an issue for discussion before starting major work.

## License

By contributing, you agree that your contributions will be licensed under the project's license.
