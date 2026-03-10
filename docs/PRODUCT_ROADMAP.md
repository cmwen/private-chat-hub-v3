# Product Roadmap: Private Chat Hub

**Status:** Active — Clean Rebuild  
**Last Updated:** January 2026  
**Maintained By:** @product-owner

---

## Vision

**"One app. Every AI model. Your choice."**

Private Chat Hub is a universal AI chat app for Android. Users choose their privacy/cost/performance balance: local models for full privacy, self-hosted (Ollama) for control, or cloud APIs for access to frontier models. Each phase builds on the last — foundation first, then extensions, then polish.

---

## How to Read This Document

- **Phases are sequential.** Phase 1 ships before Phase 2 starts. No phase begins until its dependencies are met.
- **No calendar dates.** Timelines depend on team capacity and scope adjustments. Phases are ordered by dependency, not deadline.
- **Success criteria are gates.** A phase is not complete until its success criteria are met.

---

## Phase 1: Foundation

**Goal:** Deliver a fully functional chat app for self-hosted and local models. This is the MVP — everything else builds on it.

### Key Features

| Feature | Description |
|---------|-------------|
| Core chat | Send/receive messages with streaming responses |
| Markdown rendering | Code blocks with syntax highlighting, lists, links, tables |
| Conversation management | Create, list, search, rename, delete conversations |
| Ollama integration | Connect to self-hosted Ollama instances (host/port config, connection testing, status indicator) |
| Local model support | On-device inference via LiteRT/Gemini Nano for fully offline use |
| Model picker | Select from available models on configured providers |
| Settings | Connection profiles, default model selection, basic preferences |
| Theme support | Dark and light themes with Material Design 3 |
| Offline mode | Queue messages when disconnected; send when reconnected |
| Provider abstraction | `LLMProvider` interface — all providers implement the same contract from day one |

### Architecture Note

The `LLMProvider` abstraction must be built now (Ollama + Local), even though cloud providers come later. This avoids a costly refactor in Phase 2.

### Success Criteria

- [ ] User can hold a multi-turn conversation with streaming responses
- [ ] Markdown renders correctly (code blocks, lists, links, bold/italic)
- [ ] Conversations persist across app restarts
- [ ] Ollama connection works on local network with < 2s connection setup
- [ ] Local model inference works fully offline
- [ ] App starts in < 2s
- [ ] Crash-free session rate > 99%
- [ ] Test coverage > 70%

### Dependencies

None — this is the foundation.

### Risks

- Local model quality may disappoint — position as "offline fallback", not primary
- Ollama connections vary across networks — invest in diagnostics and retry logic

---

## Phase 2: Universal Provider Support

**Goal:** Expand from self-hosted/local to cloud APIs. Users can access OpenAI, Anthropic, and Google models alongside their existing providers. This is the strategic differentiator — no other mobile app covers local + self-hosted + cloud.

### Key Features

| Feature | Description |
|---------|-------------|
| OpenAI provider | GPT-4o, GPT-4, GPT-3.5-turbo with streaming |
| Anthropic provider | Claude 3.5 Sonnet, Claude 3 Opus/Haiku with streaming |
| Google AI provider | Gemini Pro, Gemini Ultra with streaming |
| LM Studio provider | Local LM Studio instances (OpenAI-compatible API) |
| Unified model picker | Single list showing all models across all providers with type badges (local/self-hosted/cloud) |
| API key management | Secure storage (flutter_secure_storage), per-provider key entry, key validation |
| Cost tracking | Per-message token count and estimated cost, session totals, monthly summary |
| Cost warnings | Alerts when approaching user-defined spending limits |
| Smart fallback | Configurable fallback chains (e.g., Cloud → Ollama → Local → Queue) |
| Provider health | Real-time status indicators, latency tracking, automatic health checks |

### Architecture

All cloud providers implement the same `LLMProvider` interface from Phase 1. Cost tracking wraps cloud providers transparently.

### Success Criteria

- [ ] All 5 provider types work: Local, Ollama, OpenAI, Anthropic, Google AI
- [ ] Streaming works consistently across all providers
- [ ] Cost tracking accurate within 5% of actual API charges
- [ ] API keys never appear in logs, crash reports, or UI (except masked in settings)
- [ ] Fallback chains execute correctly when primary provider fails
- [ ] Provider setup takes < 5 minutes per provider
- [ ] 60%+ of test users configure at least one cloud provider

### Dependencies

- **Phase 1 complete.** Provider abstraction, chat UI, and conversation management must be stable.

### Risks

- API key security is critical — encrypt at rest, never log, audit all access paths
- Cost tracking must be accurate — validate against provider dashboards
- Too many models can overwhelm the picker — group by provider, add favorites

---

## Phase 3: Intelligence & Extensions

**Goal:** Move beyond basic chat. Add tool calling, web search, file attachments, and MCP support. This transforms the app from a chat client into an AI assistant platform.

### Key Features

| Feature | Description |
|---------|-------------|
| Tool calling framework | Provider-agnostic tool interface — works with Ollama (function calling), OpenAI, Anthropic, Google |
| Web search | Search tool that models can invoke during conversation; results rendered as cards |
| MCP support | Connect to Model Context Protocol servers; discover and invoke external tools |
| Conversation attachments | Send images and files as context (provider support permitting) |
| Advanced model config | Per-conversation overrides for temperature, max tokens, top-p, system prompt |
| Tool result rendering | Rich cards for search results, tool outputs, error states with retry |

### Architecture

Provider-agnostic tool framework: abstract `Tool` interface → `ToolCallingService` routes invocations → handler-per-tool (WebSearch, MCP, custom) → results formatted and returned to model.

### Success Criteria

- [ ] Tool invocation success rate > 95%
- [ ] Web search results return in < 3s (p95)
- [ ] MCP server connection and tool discovery works reliably
- [ ] Image attachments work with providers that support vision (GPT-4o, Claude, Gemini)
- [ ] Tool calling works across at least 3 providers (Ollama, OpenAI, Anthropic)
- [ ] Advanced config changes apply immediately without restarting conversation

### Dependencies

- **Phase 2 complete.** Tool calling needs the provider abstraction to work across cloud and self-hosted providers. Some tools (web search) benefit from cloud provider availability.

### Risks

- Tool calling varies across providers — abstract with provider-specific adapters, degrade gracefully
- MCP ecosystem still maturing — start with manual server config
- Web search latency — cache results, stream indicators, enforce timeouts

---

## Phase 4: Power Features

**Goal:** Features that delight power users and differentiate from competitors. These are high-value but not foundational — they build on everything from Phases 1-3.

### Key Features

| Feature | Description |
|---------|-------------|
| Model comparison | Side-by-side responses from 2+ models on the same prompt |
| Text-to-speech | Read AI responses aloud using Android TTS; play/pause, speed control, voice selection |
| Projects | Group conversations by project/topic; project-level default model and system prompt |
| Export & sharing | Export conversations as Markdown/PDF; share via Android share intent; receive text from other apps |
| Advanced search | Full-text search across all conversations; filter by model, date, provider, project |
| Thinking model support | Display extended reasoning steps from models that support it (chain-of-thought visibility) |

### Success Criteria

- [ ] Model comparison renders side-by-side on phone screens without UX degradation
- [ ] TTS works on 95%+ of Android devices (API 26+)
- [ ] Export produces valid Markdown that renders correctly in external tools
- [ ] Search returns results in < 500ms for 1000+ conversations
- [ ] Share intent receives text from 95%+ of common Android apps
- [ ] Thinking model reasoning steps render with clear visual hierarchy

### Dependencies

- **Phase 3 complete.** Model comparison benefits from tool calling (compare tool usage across models). Projects depend on stable conversation management. Export needs stable message format.

### Risks

- Model comparison may overload Ollama — implement rate limiting and sequential fallback
- Side-by-side UI too cramped on small screens — use tabbed fallback for < 360dp

---

## Phase 5: Polish & Scale

**Goal:** Production hardening. Make the app fast, accessible, international, and ready for diverse Android devices. No new major features — focus on quality.

### Key Features

| Feature | Description |
|---------|-------------|
| Performance optimization | Lazy loading, response caching, memory profiling, startup time reduction |
| Accessibility audit | Screen reader support, contrast ratios, touch targets, semantic labels |
| Internationalization | String extraction, RTL support, locale-aware formatting; start with top 5 languages |
| Tablet & foldable support | Responsive layouts, multi-pane UI on large screens, fold-aware positioning |
| Analytics & insights | Personal usage dashboard — messages per day, model usage breakdown, cost trends, conversation stats |
| Long-running task support | Background execution for extended model operations, progress tracking, task resumption |

### Success Criteria

- [ ] App startup < 1.5s on mid-range devices (cold start)
- [ ] Memory usage < 200MB during normal operation, < 300MB during model comparison
- [ ] WCAG 2.1 AA compliance for all core flows
- [ ] UI renders correctly on screens from 5" phone to 12" tablet
- [ ] Foldable devices handle fold/unfold without state loss
- [ ] All user-facing strings extracted and translatable
- [ ] No ANR (Application Not Responding) events in production

### Dependencies

- **Phase 4 complete.** Polish requires feature-complete state. Accessibility audit covers all features. Performance optimization depends on knowing the full feature set.

### Risks

- i18n at scale is tedious — use `intl` package from early phases; enforce string extraction in CI
- Tablet layouts need responsive design from Phase 1 to avoid a rewrite here

---

## Cross-Cutting Concerns (All Phases)

- **Security:** API keys encrypted at rest. No secrets in logs or crash reports. Conversation data local-only.
- **Testing:** Unit + widget + integration tests. Target 80%+ coverage by Phase 3.
- **CI/CD:** Automated build/test/lint on every PR. Signed release builds via GitHub Actions.
- **Privacy:** "Privacy by choice." Local/Ollama = zero data to third parties. Cloud = only conversation content to selected provider. No telemetry without opt-in.

---

## Out of Scope

iOS, desktop, cloud sync, custom agent builder, voice input (STT), multi-user conversations, plugin marketplace.

---

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Phases, not versions | Avoids confusion from overlapping v1/v1.5/v2 numbering. Phases are clearer. |
| Relative ordering, not dates | Dates become stale. Dependency ordering doesn't. |
| Provider abstraction in Phase 1 | Avoids costly refactor later. The interface is small; the cost is low. |
| Cloud APIs in Phase 2, not Phase 1 | Foundation must be solid first. Cloud adds complexity (auth, cost, rate limits). |
| Tool calling in Phase 3, not Phase 2 | Needs stable multi-provider support. Tool calling varies significantly across providers. |
| No iOS | Android-first focus. Flutter enables iOS later if demand justifies it. |

---

## Related Documents

- [USER_PERSONAS.md](USER_PERSONAS.md) — Target user archetypes
- Product requirements — per-phase detailed specs (to be created per phase)
- Architecture docs — per-phase technical design (to be created per phase)
