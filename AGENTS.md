# Agent Configuration and Instructions

This document provides guidance for AI agents and automated tools working with this Flutter Android repository. It serves as the primary rules file for both OpenCode and GitHub Copilot.

## Repository Overview

**Private Chat Hub** is a universal AI chat platform — one app for local, self-hosted, and cloud AI models. Built with Flutter for Android, it features a provider registry architecture, Material Design 3, and comprehensive AI-powered development workflow.

## AI Agent Tooling

This project supports two AI agent platforms:

| Platform | Config | Agents | Skills |
|----------|--------|--------|--------|
| **OpenCode** | `opencode.json` + `.opencode/` | `.opencode/agents/*.md` | `.opencode/skills/` |
| **GitHub Copilot** | `.github/agents/*.agent.md` | `.github/agents/` | `.github/skills/` |

### Agents

6 specialized agents available on both platforms:

| Agent | Role | Mode |
|-------|------|------|
| **@product-owner** | Define features, requirements, user stories | Subagent |
| **@experience-designer** | Design UX, user flows, interfaces | Subagent |
| **@architect** | Plan architecture, technical decisions | Subagent |
| **@researcher** | Research packages, best practices | Subagent |
| **@flutter-developer** | Implement features, write tests, debug | Primary |
| **@doc-writer** | Create documentation, guides | Subagent |

### Skills

4 reusable skills available on both platforms:

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| **build-fix** | Diagnose build failures | Gradle errors, dependency conflicts, compilation issues |
| **android-debug** | Debug Android app issues | Crashes, device issues, performance problems |
| **ci-debug** | Fix GitHub Actions failures | Workflow failures, CI-specific build errors |
| **icon-generation** | Generate app icons | Creating UI or launcher icons |

### OpenCode Commands

| Command | Description |
|---------|-------------|
| `/test` | Run Flutter tests with coverage |
| `/build` | Build release APK |
| `/analyze` | Run static analysis |
| `/fix` | Auto-fix and format code |
| `/clean` | Clean and reinstall dependencies |
| `/check` | Full project health check |

## Project Structure

```
├── lib/                    # Dart source code
│   ├── main.dart           # App entry point
│   ├── screens/            # Full-screen pages
│   ├── widgets/            # Reusable components
│   ├── models/             # Data models
│   ├── services/           # Business logic, API calls
│   ├── providers/          # State management
│   └── utils/              # Helpers and utilities
├── test/                   # Unit and widget tests
├── android/                # Android platform files
├── docs/                   # Specifications and guides
├── .opencode/              # OpenCode agent configuration
│   ├── agents/             # 6 specialized agents
│   └── skills/             # 4 reusable skills
├── .github/                # CI/CD and Copilot agents
│   ├── workflows/          # GitHub Actions
│   ├── agents/             # 6 Copilot agents
│   └── skills/             # 4 Copilot skills
├── opencode.json           # OpenCode config
└── pubspec.yaml            # Dependencies and project config
```

## Key Documentation

| Document | Purpose |
|----------|---------|
| `docs/PRODUCT_VISION.md` | Core vision and principles |
| `docs/PRODUCT_REQUIREMENTS.md` | Feature requirements (MoSCoW) |
| `docs/PRODUCT_ROADMAP.md` | Phased delivery plan |
| `docs/USER_PERSONAS.md` | Target user profiles |
| `docs/USER_STORIES.md` | Stories with acceptance criteria |
| `docs/ARCHITECTURE.md` | System architecture |
| `docs/ARCHITECTURE_DECISIONS.md` | ADR log |
| `docs/UX_DESIGN.md` | Screen designs and interactions |
| `docs/UX_COMPONENTS.md` | Component specifications |
| `docs/OPINIONATED_DEFAULTS.md` | Default configurations |

## Flutter Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter test                 # Run tests
flutter test --coverage      # Tests with coverage
flutter analyze              # Static analysis
dart format .                # Format code
dart fix --apply             # Auto-fix lint issues
flutter build apk --release  # Build release APK
flutter clean                # Clean build artifacts
```

## Architecture Overview

The app uses a **Provider Registry** pattern:
- All AI providers (local, Ollama, LM Studio, OpenAI, Anthropic, Google) implement a common `LLMProvider` interface
- Providers register with the `ProviderRegistry` for discovery and routing
- Models use qualified IDs (`provider:model`) for unambiguous resolution
- Smart fallback chains route to alternative providers on failure

See `docs/ARCHITECTURE.md` for full details and `docs/ARCHITECTURE_DECISIONS.md` for rationale.

## Best Practices for AI Agents

1. **Verify changes** — Run `flutter analyze` and `flutter test` after implementation
2. **Save documentation to docs/** — Use consistent prefixes (REQUIREMENTS_, ARCHITECTURE_, UX_DESIGN_)
3. **Check existing patterns** — Search the codebase before creating new patterns
4. **CI auto-formats code** — No need to run `dart format` manually
5. **Reference specs** — Link to docs/ files for design context
6. **Run tests** — Verify functionality before considering work complete

## Multi-Agent Workflows

### Implement a New Feature

1. **@product-owner** → Define requirements and user stories
2. **@experience-designer** → Design UX flows and screens
3. **@researcher** → Research packages and best practices
4. **@architect** → Design architecture and data models
5. **@flutter-developer** → Implement, test, and verify
6. **@doc-writer** → Document the feature

### Debug a Build Issue

1. Use **build-fix** skill for systematic diagnosis
2. If Android-specific, use **android-debug** skill
3. If CI-only, use **ci-debug** skill

### Troubleshooting

```bash
# Clean rebuild
flutter clean && flutter pub get && flutter build apk

# Fix common issues
dart fix --apply && flutter analyze

# Full health check
flutter doctor -v && flutter pub outdated
```
