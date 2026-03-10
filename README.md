# Private Chat Hub

**A universal AI chat platform** — one app for all your AI models: local, self-hosted, and cloud.

## Vision

Private Chat Hub gives you **privacy by choice**. Chat with on-device models for maximum privacy, self-hosted servers for full control, or cloud APIs for cutting-edge capabilities. You choose the right balance for each conversation.

## Key Features

- **Three-Tier Provider Support**
  - **Local**: On-device models for 100% offline, private chat
  - **Self-Hosted**: Ollama, LM Studio for user-controlled infrastructure
  - **Cloud**: OpenAI, Anthropic, Google for latest model capabilities

- **Smart Model Management**
  - Unified model picker across all providers
  - Model capability detection (vision, tool calling, context size)
  - Smart fallback when a provider is unavailable

- **Cost-Aware Chat**
  - Per-message token usage for cloud providers
  - Conversation and monthly cost tracking
  - Cost warnings and configurable limits

- **Tool Calling & Extensions**
  - Web search integration
  - Function/tool calling (provider-agnostic)
  - MCP (Model Context Protocol) support

- **Rich Chat Experience**
  - Streaming responses with real-time display
  - Markdown and code block rendering
  - Image attachments and vision model support
  - Text-to-speech for AI responses
  - Conversation export and sharing

- **Organization**
  - Projects for grouping conversations
  - Conversation search and filtering
  - Archive and manage chat history

## Platform

Android (primary) — Material Design 3, dark/light themes, accessibility-first.

## Documentation

| Document | Description |
|----------|-------------|
| [Product Vision](docs/PRODUCT_VISION.md) | Core vision, principles, and differentiators |
| [Product Requirements](docs/PRODUCT_REQUIREMENTS.md) | Complete feature requirements (MoSCoW) |
| [Product Roadmap](docs/PRODUCT_ROADMAP.md) | Phased delivery plan |
| [User Personas](docs/USER_PERSONAS.md) | Target user profiles |
| [User Stories](docs/USER_STORIES.md) | Stories with acceptance criteria |
| [Architecture](docs/ARCHITECTURE.md) | System architecture and design |
| [Architecture Decisions](docs/ARCHITECTURE_DECISIONS.md) | ADR log with rationale |
| [UX Design](docs/UX_DESIGN.md) | Screen designs and interactions |
| [UX Components](docs/UX_COMPONENTS.md) | Component specifications |
| [Opinionated Defaults](docs/OPINIONATED_DEFAULTS.md) | Default configurations |
| [Pre-Release Checklist](docs/PRE_RELEASE_CHECKLIST.md) | Release quality gates |

## AI Agent Workflows

This project includes 6 specialized AI agents and 4 reusable skills for both OpenCode and GitHub Copilot. See [AGENTS.md](AGENTS.md) for details.

| Agent | Role |
|-------|------|
| @product-owner | Define features, requirements, user stories |
| @experience-designer | Design UX, user flows, interfaces |
| @architect | Plan architecture, technical decisions |
| @researcher | Research packages, best practices |
| @flutter-developer | Implement features, write tests, debug |
| @doc-writer | Create documentation, guides |

## Getting Started

```bash
# Clone the repository
git clone <repo-url>
cd private-chat-hub-v2

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See LICENSE file when added.
