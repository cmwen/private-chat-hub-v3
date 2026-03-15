# Architecture Decision Record (ADR) Log

**Purpose:** Canonical record of all architectural decisions for Private Chat Hub
**Scope:** All architectural decisions from initial design through multi-provider expansion

---

## Summary Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| 001 | Mobile-first Android platform | Superseded | 2025-12-31 |
| 002 | Provider abstraction pattern | Accepted | 2025-12-31 |
| 003 | Local-first data storage | Superseded | 2025-12-31 |
| 004 | Streaming-first chat experience | Accepted | 2025-12-31 |
| 005 | Material Design 3 | Accepted | 2025-12-31 |
| 006 | Provider registry pattern | Accepted | 2026-01-26 |
| 007 | API key storage strategy | Accepted | 2026-01-26 |
| 008 | Cost tracking approach | Accepted | 2026-01-26 |
| 009 | Smart fallback chains | Accepted | 2026-01-26 |
| 010 | Tool calling architecture | Accepted | 2026-01-26 |
| 011 | MCP integration strategy | Accepted | 2026-01-26 |
| 012 | Model capability detection | Accepted | 2026-01-26 |
| 013 | Offline behavior for cloud providers | Accepted | 2026-01-26 |
| 014 | Multi-provider model comparison design | Accepted | 2026-01-26 |
| 015 | TTS integration approach | Accepted | 2026-01-26 |
| 016 | Conversation data model | Accepted | 2026-01-26 |
| 017 | Project organization pattern | Accepted | 2026-01-26 |
| 018 | File-backed portable history | Accepted | 2026-03-15 |
| 019 | Mobile + desktop platform scope | Accepted | 2026-03-15 |

---

## Foundational Decisions

### ADR-001: Mobile-First Android Platform

**Status:** Superseded by ADR-019
**Date:** 2025-12-31

**Context:** Private Chat Hub targets privacy-conscious users who chat with self-hosted AI models via Ollama. We needed to decide on initial platform scope. Building for all platforms simultaneously would increase the testing matrix, slow iteration, and dilute focus. However, locking into Android-only code would make future expansion costly.

**Decision:** Build for Android only in MVP using Flutter, but maintain cross-platform-compatible code. Avoid Android-specific APIs where possible; abstract any platform-specific code behind interfaces.

**Alternatives Considered:**
- **Cross-platform from day one (Android + iOS + Web):** Broader reach but triples QA surface, delays MVP by weeks, and the target persona skews heavily Android.
- **Native Android (Kotlin):** Maximum platform integration but eliminates future iOS path and reduces the developer pool.
- **React Native:** Viable cross-platform option but Flutter's rendering pipeline offers better control over streaming chat UX and animation performance.

**Consequences:**
- ✅ Reduced testing matrix; faster path to usable product.
- ✅ Flutter's widget layer keeps code inherently portable to iOS later.
- ✅ Android-specific optimizations (R8 shrinking, Gradle caching) can be fully exploited.
- ⚠️ iOS users are excluded until a future phase.
- ⚠️ Must resist leaking Android-only assumptions into shared code.

---

### ADR-002: Provider Abstraction Pattern

**Status:** Accepted (superseded in scope by ADR-006)
**Date:** 2025-12-31

**Context:** The initial design only supported Ollama, but the product roadmap included on-device models and cloud APIs. We needed a service layer design that could support a single provider today without requiring a rewrite when additional backends arrive.

**Decision:** Define a clean `LLMProvider` abstract interface with methods for `listModels()`, `sendMessage()` (streaming), `checkHealth()`, and `getCapabilities()`. The initial `OllamaService` implements this interface directly. A `ChatService` acts as the central router that talks only to the interface, never to a concrete provider.

**Alternatives Considered:**
- **Direct Ollama coupling:** Simpler initially, but every new provider would require rewiring the chat screen and duplicating routing logic.
- **Plugin/package-per-provider:** Good isolation, but premature for a single-developer project with only one provider at launch.

**Consequences:**
- ✅ Adding on-device models and cloud APIs required zero changes to ChatService's public API.
- ✅ Each provider can be unit-tested in isolation with mock HTTP.
- ⚠️ Adds an abstraction layer that is functionally unnecessary with a single provider.
- ⚠️ Interface must be broad enough for wildly different backends (local inference vs REST API vs SSE streams).

---

### ADR-003: Local-First Data Storage

**Status:** Superseded by ADR-018
**Date:** 2025-12-31

**Context:** The core value proposition is privacy. Conversations, settings, and model metadata must never leave the device unless the user explicitly sends a message to a remote model. We also needed an offline story: if the Ollama server is unreachable the app should still browse history, search, and queue messages.

**Decision:** Use SQLite (via `sqflite`) as the primary data store. All conversations and messages are persisted locally before any network call. Messages are marked `pending` until the backend confirms. The model list is cached locally and refreshed opportunistically. SharedPreferences handles lightweight key-value settings.

**Alternatives Considered:**
- **Hive (NoSQL):** Fast key-value store, but lacks full-text search (FTS5) which is critical for message search.
- **Isar:** Modern Flutter DB, but smaller community and less battle-tested at the time of evaluation.
- **Drift (formerly Moor):** Type-safe SQLite wrapper; excellent but adds code-generation overhead for a schema this simple.

**Consequences:**
- ✅ FTS5 virtual table enables sub-50ms message search across thousands of messages.
- ✅ All data is app-private, encrypted by Android 10+ file-based encryption by default.
- ✅ ACID transactions prevent partial writes during crashes.
- ⚠️ Schema migrations must be managed manually (versioned `onCreate`/`onUpgrade`).
- ⚠️ Binary blobs (images) stored as file paths, not in DB—requires orphan cleanup on delete.

---

### ADR-004: Streaming-First Chat Experience

**Status:** Accepted
**Date:** 2025-12-31

**Context:** LLM responses can take seconds to minutes. Showing a spinner until the full response arrives is a poor experience; users expect to see tokens appear in real-time, similar to ChatGPT. Ollama (and later OpenAI/Anthropic) all support streaming via newline-delimited JSON or SSE.

**Decision:** Treat streaming as the primary response mode across all providers. Parse responses line-by-line using a buffered approach that handles partial JSON chunks. Debounce UI updates to 16ms (60 FPS cap) to prevent jank from rapid token emission. Support cancellation via `CancelToken` (Dio) or HTTP client abort.

**Alternatives Considered:**
- **Request-response only:** Simpler parsing, but terrible UX for multi-paragraph responses; users would stare at a spinner for 10-30 seconds.
- **WebSocket transport:** Lower overhead for bidirectional streaming, but none of the target providers use WebSocket for chat completions.

**Consequences:**
- ✅ Token-by-token display creates a responsive, engaging experience.
- ✅ Users can cancel mid-generation, saving compute on the Ollama server.
- ✅ Same streaming architecture works for Ollama (NDJSON), OpenAI/Anthropic (SSE), and Google AI (NDJSON).
- ⚠️ Buffer management adds complexity; partial JSON lines must be accumulated across chunks.
- ⚠️ Debounce logic is critical—without it, rapid setState calls cause frame drops.

---

### ADR-005: Material Design 3

**Status:** Accepted
**Date:** 2025-12-31

**Context:** The app needs a modern, accessible visual language that feels native on Android 12+ devices. We needed a theming system that supports dark mode, dynamic color (wallpaper-based palette), and scales cleanly across the chat, settings, and model management screens.

**Decision:** Use Material Design 3 with `ColorScheme.fromSeed()` for all theming. Use semantic color roles (primary, secondary, surface, error) rather than hardcoded hex values. Support system dark/light mode and optional dynamic color on supported devices.

**Alternatives Considered:**
- **Material Design 2:** Well-supported but visually dated on modern Android; lacks dynamic color and the tonal palette system.
- **Custom design system:** Maximum creative freedom but enormous investment for a single-developer project with no dedicated designer.
- **Cupertino (iOS-style):** Wrong platform language for an Android-first app.

**Consequences:**
- ✅ `ColorScheme.fromSeed()` generates a complete, accessible palette from a single brand color.
- ✅ Dark mode is effectively free—just flip `Brightness.dark` on the same seed.
- ✅ Widgets like `FilledButton`, `NavigationBar`, `SearchAnchor` follow M3 specs out of the box.
- ⚠️ Some M3 widgets (e.g., `NavigationDrawer`) have subtle behavioral differences from M2 that require testing.
- ⚠️ Dynamic color requires Android 12+ and `dynamic_color` package; older devices get the seed-based palette.

---

## Multi-Provider Decisions

### ADR-006: Provider Registry Pattern

**Status:** Accepted
**Date:** 2026-01-26

**Context:** With the addition of OpenAI, Anthropic, and Google AI alongside Ollama and on-device models, the initial `ChatService` central-router approach faced a three-way architecture conflict. Three patterns were proposed: (1) prefix routing—embed the provider ID in the model name string (e.g., `openai:gpt-4o`) and use string parsing to route; (2) central router—a monolithic `ChatService` with explicit if/else chains per provider; (3) provider registry—a `ProviderRegistry` service that manages provider instances by ID, with `ChatService` delegating to registered providers.

**Decision:** Adopt the provider registry pattern. A `ProviderRegistry` holds a `Map<String, LLMProvider>` of all registered providers. Providers self-register at app startup. `ChatService` resolves the target provider via registry lookup, never via string parsing or branching logic. The registry also owns health tracking and provider preference ordering.

**Alternatives Considered:**
- **Prefix routing (`openai:gpt-4o`):** Simple string convention, but tightly couples model IDs to provider identity. Breaks if a model is available from multiple providers or if a user points Ollama at an OpenAI-compatible endpoint.
- **Central router (if/else per provider):** Works for 2-3 providers but becomes an unmaintainable switch statement at 5+. Every new provider requires touching the router.

**Consequences:**
- ✅ Adding a new provider requires only implementing `LLMProvider` and calling `registry.register()`. Zero changes to ChatService.
- ✅ Registry enables provider-level operations (health checks, enable/disable, preference ordering) in one place.
- ✅ Clean separation: ChatService owns conversation logic; registry owns provider lifecycle.
- ⚠️ Adds an indirection layer; debugging requires tracing through registry → provider → HTTP client.
- ⚠️ Registry initialization order matters—providers must register before first message send.

---

### ADR-007: API Key Storage Strategy

**Status:** Accepted
**Date:** 2026-01-26

**Context:** Cloud providers (OpenAI, Anthropic, Google AI) require API keys. These are sensitive credentials—if leaked, an attacker can run up charges on the user's account. We needed a storage mechanism that is resistant to device compromise, backup extraction, and accidental logging.

**Decision:** Store all API keys in `flutter_secure_storage`, which delegates to Android Keystore (hardware-backed on supported devices). The SQLite `provider_configs` table holds only a `api_key_ref` identifier, never the key itself. Keys are never logged, even partially. The UI masks keys by default and optionally requires biometric authentication to reveal them.

**Alternatives Considered:**
- **SharedPreferences:** Simple, but stored as plaintext XML on disk. Trivially extractable on rooted devices.
- **Encrypted SQLite (SQLCipher):** Encrypts the entire database, but adds ~3MB to APK size, requires a master password UX, and is overkill when only API keys need protection.
- **System Keychain only (no local ref):** Secure, but Keychain has no query/list API—we need the ref in SQLite to know which providers are configured.

**Consequences:**
- ✅ Hardware-backed encryption on devices with Keystore TEE; software-backed on older devices.
- ✅ Keys survive app updates but are wiped on app uninstall (Android behavior).
- ✅ Biometric gate prevents shoulder-surfing when viewing keys in settings.
- ⚠️ `flutter_secure_storage` has platform-specific quirks (e.g., Android auto-backup can include encrypted prefs unless excluded in manifest).
- ⚠️ If the user loses their device, there is no key recovery mechanism—this is by design (privacy-first).

---

### ADR-008: Cost Tracking Approach

**Status:** Accepted
**Date:** 2026-01-26

**Context:** Cloud API usage costs real money. Users need transparency about what each conversation costs, the ability to set spending limits, and historical usage breakdowns. Token counts are the billing unit, but pricing varies per model and per provider. We needed to decide between client-side estimation and provider-reported actuals.

**Decision:** Use provider-reported token counts as the source of truth. Each streaming response's final chunk includes a `usage` object with `inputTokens` and `outputTokens`. Record these per-message in a `token_usage` table along with the estimated USD cost (computed from a bundled pricing table). Support user-configurable cost limits (warning threshold + hard limit) per provider and per period (daily/monthly).

**Alternatives Considered:**
- **Client-side token estimation (tiktoken-equivalent):** Available immediately before the response, but inaccurate across providers (each uses different tokenizers) and doesn't account for prompt caching.
- **No cost tracking:** Simpler, but users have reported anxiety about cloud API spending as a top concern in user research.
- **Provider billing API integration:** Most accurate, but OpenAI/Anthropic billing APIs are separate from chat APIs, require additional permissions, and have significant latency.

**Consequences:**
- ✅ Token counts are exact for the actual request (including any prompt caching or system overhead).
- ✅ Per-message granularity lets users see cost per conversation and identify expensive patterns.
- ✅ Hard limits can auto-disable a provider before overspending.
- ⚠️ Pricing table must be updated when providers change rates—shipped as bundled JSON, updatable via app release.
- ⚠️ Cost is estimated (our pricing table × their tokens), not actual invoice amount. Rounding and special pricing tiers may cause small discrepancies.

---

### ADR-009: Smart Fallback Chains

**Status:** Accepted
**Date:** 2026-01-26

**Context:** With 5 provider backends, any single provider can fail (network error, rate limit, API outage, Ollama server offline). The user shouldn't have to manually switch providers when a failure occurs—the app should offer intelligent fallback options. However, automatic fallback raises trust issues: users may not want their private conversation silently redirected to a different cloud provider.

**Decision:** Implement user-configurable fallback chains. When a provider fails, the `FallbackStrategy` service walks a priority-ordered chain based on the failed provider's type: cloud → other cloud → self-hosted → local. The user configures fallback behavior in settings: "Always ask", "Auto-fallback", or "Never fallback". When "Always ask" is selected, a dialog shows the suggested alternative and the user confirms. The fallback respects capability requirements (e.g., won't fall back to a text-only model for a vision request).

**Alternatives Considered:**
- **No fallback (manual only):** Simplest, but frustrating when Ollama is temporarily unreachable and the user has a perfectly good cloud API configured.
- **Fully automatic fallback (silent):** Best UX flow, but violates the privacy-first principle. A user chatting with local Ollama may not want their message silently routed to OpenAI's servers.
- **Static fallback mapping (provider A → always provider B):** Too rigid; doesn't account for runtime availability or capability matching.

**Consequences:**
- ✅ "Always ask" mode preserves user agency and trust—the core brand value.
- ✅ "Auto-fallback" mode provides seamless experience for users who prioritize convenience.
- ✅ Capability matching prevents nonsensical fallbacks (vision → text-only).
- ⚠️ Fallback dialog interrupts the chat flow; must be designed to feel quick, not modal-heavy.
- ⚠️ Chain evaluation requires synchronous health checks, adding latency before the fallback attempt.

---

### ADR-010: Tool Calling Architecture

**Status:** Accepted
**Date:** 2026-01-26

**Context:** Modern LLMs support tool/function calling—the model can request the client to execute a function (e.g., web search, calculator, file read) and incorporate the result. OpenAI, Anthropic, and Google AI each have different tool-calling wire formats. Ollama supports tool calling for compatible models. We needed a provider-agnostic interface so tools are defined once and work across all backends.

**Decision:** Define a provider-agnostic `Tool` interface with a JSON Schema-based parameter definition. A `ToolRegistry` holds available tools. When a provider's streaming response includes a `TOOL_CALL` event, the ChatService pauses streaming, executes the tool via the registry, and feeds the result back as a follow-up message. Each provider adapter is responsible for translating between the canonical tool format and its wire format (OpenAI's `functions`, Anthropic's `tool_use`, Google's `functionDeclarations`).

**Alternatives Considered:**
- **Provider-specific tool definitions:** Each provider gets its own tool format. Simpler per-provider but means every tool must be defined N times and behavior can diverge.
- **No tool support (text-only):** Reduces complexity enormously, but increasingly expected by users who want agents-style workflows with web search, code execution, etc.
- **LangChain-style orchestration:** Full agent framework with chain-of-thought. Powerful but massive dependency, opinionated, and overkill for the current scope.

**Consequences:**
- ✅ Tools are defined once in a canonical format; provider adapters handle translation.
- ✅ Adding a new tool doesn't require touching any provider code.
- ✅ `TOOL_CALL` response type in `ChatResponse` enum fits cleanly into the existing streaming architecture.
- ⚠️ Tool execution is synchronous from the LLM's perspective—long-running tools block the response stream.
- ⚠️ Not all models support tool calling; must gracefully degrade (see ADR-012).

---

### ADR-011: MCP Integration Strategy

**Status:** Accepted
**Date:** 2026-01-26

**Context:** The Model Context Protocol (MCP) is an emerging open standard for connecting LLM applications to external tools and data sources via a standardized JSON-RPC interface. MCP servers provide tools, resources, and prompts that any MCP-compatible client can consume. Supporting MCP would let users connect Private Chat Hub to the growing ecosystem of MCP servers (file systems, databases, APIs) without us building each integration.

**Decision:** Integrate MCP as a tool provider that plugs into the existing `ToolRegistry` (ADR-010). An `MCPBridge` service discovers and connects to user-configured MCP servers (via stdio or HTTP transport). Each MCP server's tools are translated into our canonical `Tool` format and registered dynamically. The bridge handles the MCP JSON-RPC protocol, including capability negotiation and lifecycle management.

**Alternatives Considered:**
- **Native integrations only (no MCP):** Each external tool built in-app. Higher quality per integration but doesn't scale—the MCP ecosystem already has hundreds of servers.
- **Full MCP host implementation:** Implement the complete MCP host spec including resources, prompts, sampling, and roots. Comprehensive but the spec is still evolving; overcommitting to immature features risks rework.
- **MCP as a plugin system (sideload):** Users install MCP server binaries on-device. Technically possible but Android's sandboxing makes this impractical for most users.

**Consequences:**
- ✅ Users get access to the entire MCP ecosystem (file access, web search, database queries, etc.) without custom integrations.
- ✅ MCP tools appear identically to built-in tools in the chat UI.
- ✅ Bridges to the tool calling architecture (ADR-010) cleanly—MCP tools register like any other tool.
- ⚠️ MCP spec is still evolving; must isolate the bridge layer to absorb spec changes without cascading.
- ⚠️ Stdio transport requires a local MCP server process, which is uncommon on mobile—HTTP/SSE transport is the realistic mobile path.

---

### ADR-012: Model Capability Detection

**Status:** Accepted
**Date:** 2026-01-26

**Context:** Different models support different capabilities: text, vision, tool calling, code execution, streaming. The UI needs to know capabilities to show/hide features (e.g., image attach button, tool toggle). Cloud providers publish capability metadata in their model listing APIs. Ollama models have capabilities that depend on the underlying model architecture, not always reported by the API.

**Decision:** Use a hybrid approach: prefer provider-reported capabilities, fall back to a bundled capability database, and probe as a last resort. Cloud providers (OpenAI, Anthropic, Google) report capabilities in their model info endpoints—use these as source of truth. For Ollama, maintain a bundled lookup table mapping common model families (llama, mistral, gemma) to known capabilities. For unknown models, probe by sending a minimal test request with a tool definition and checking if the response includes tool call support.

**Alternatives Considered:**
- **Provider-reported only:** Clean and simple, but Ollama's `/api/show` doesn't reliably report tool-calling or vision support for all model variants.
- **Probe-only (send test requests):** Most accurate at runtime, but adds latency on first use, wastes tokens, and some providers charge for probe requests.
- **User-declared capabilities:** Let users tag models manually. Flexible but terrible UX—users don't know or care whether `llama3.2` supports tool calling.

**Consequences:**
- ✅ Cloud models get instant, accurate capability data from the API response.
- ✅ Bundled lookup table covers 90%+ of common Ollama models without any probe latency.
- ✅ Probing provides a safety net for exotic or newly released models.
- ⚠️ Bundled table needs periodic updates as new models are released.
- ⚠️ Probing can produce false negatives if the model technically supports a feature but the test request doesn't trigger it.

---

### ADR-013: Offline Behavior for Cloud Providers

**Status:** Accepted
**Date:** 2026-01-26

**Context:** The initial offline story was simple: if Ollama is unreachable, queue the message. With cloud providers, "offline" has more nuance. The device might have internet but Ollama is down; or the device has no internet at all (airplane mode); or a specific cloud provider is rate-limited while others work fine. Users need clear feedback about what works, what's degraded, and what's queued.

**Decision:** Implement graceful degradation with provider-level status tracking. Each provider independently reports its status (`READY`, `OFFLINE`, `RATE_LIMITED`, `ERROR`). The UI shows a connectivity banner that reflects the aggregate state: green (all providers healthy), yellow (some degraded), red (no providers available). When the active provider fails, trigger the fallback chain (ADR-009). If no fallback is available, queue the message with a visible "queued" indicator and a timestamp. Process the queue automatically when any provider recovers (FIFO order, max 50 queued messages, exponential retry backoff).

**Alternatives Considered:**
- **Binary online/offline (initial approach):** Simple but misleading when cloud APIs work fine but Ollama is down. Users would see "offline" despite having internet.
- **No queueing for cloud (fail immediately):** Simpler queue logic, but users lose their message text and must retype when service recovers.
- **Background sync (like email):** Queue indefinitely and sync later. Over-engineered for a chat app—conversations lose context if messages are delivered hours later.

**Consequences:**
- ✅ Users always see accurate per-provider status, not a misleading global toggle.
- ✅ Queued messages are never lost; they persist across app restarts via SQLite-backed queue.
- ✅ Automatic queue processing means the user doesn't have to remember to retry.
- ⚠️ Queue processing order may not match conversational intent if the user started new conversations while offline.
- ⚠️ Aggregate status banner logic is complex (5 providers × 4+ states = many combinations to display clearly).

---

### ADR-014: Multi-Provider Model Comparison Design

**Status:** Accepted
**Date:** 2026-01-26

**Context:** Users with multiple configured providers may want to compare model responses—send the same prompt to GPT-4o and Claude and compare quality, speed, and cost side-by-side. This is a common workflow for power users evaluating which model to use for a task. We needed to decide how deeply to integrate this without over-complicating the core chat experience.

**Decision:** Implement comparison as a dedicated mode, not as a modification of normal chat. A "Compare" action on any sent message opens a comparison sheet where the user selects 1-3 additional models. The same prompt (with conversation context) is sent to each selected model in parallel. Results display in side-by-side cards showing response text, latency, token count, and estimated cost. Comparison results are ephemeral (not saved to conversation history) unless the user explicitly chooses to keep one.

**Alternatives Considered:**
- **Split-screen chat (two conversations side by side):** Rich experience, but requires a complete rethinking of the chat screen layout for mobile; too complex for the initial implementation.
- **Inline comparison (responses stacked in same conversation):** Simpler UI, but pollutes the conversation history with duplicate context and makes the thread hard to follow.
- **No comparison feature:** Simplest, but user research showed model comparison as a top-3 requested feature for multi-provider users.

**Consequences:**
- ✅ Core chat experience remains clean and single-model focused.
- ✅ Parallel requests minimize wait time; user sees all responses as they stream.
- ✅ Cost/speed/quality comparison in one view enables informed model selection.
- ⚠️ Parallel requests to cloud APIs multiply token costs for the comparison prompt.
- ⚠️ Ephemeral-by-default means users must remember to save; could add friction.

---

### ADR-015: TTS Integration Approach

**Status:** Accepted
**Date:** 2026-01-26

**Context:** Some users want AI responses read aloud—accessibility use case, hands-free listening, or language learning. Two broad approaches exist: use the device's built-in text-to-speech engine (free, offline, limited quality) or use a cloud TTS API (OpenAI TTS, Google Cloud TTS—high quality, costs money, requires internet).

**Decision:** Use platform-native TTS via Flutter's `flutter_tts` package as the default, with cloud TTS as an optional premium path. Platform-native TTS uses Android's built-in `TextToSpeech` engine, which works offline, supports multiple languages, and costs nothing. For users who want higher quality voices, offer an opt-in cloud TTS option that routes through the configured OpenAI or Google provider (if available). The TTS button appears on each assistant message bubble.

**Alternatives Considered:**
- **Cloud TTS only (OpenAI TTS / Google TTS):** Best voice quality, but requires internet, costs per character, and contradicts the offline-first principle.
- **No TTS:** Simpler, but accessibility is a core value and read-aloud is a frequently requested feature.
- **On-device neural TTS model (custom):** Best of both worlds (offline + quality), but adds significant APK size (100MB+ models) and inference complexity.

**Consequences:**
- ✅ Platform-native TTS is zero-cost, zero-latency, works offline, and supports 50+ languages out of the box.
- ✅ Cloud TTS upgrade path satisfies users who want natural-sounding voices.
- ✅ Per-message TTS button is non-intrusive; doesn't change the default experience.
- ⚠️ Platform TTS quality varies significantly by device and Android version.
- ⚠️ Long responses require chunking to avoid TTS engine buffer limits.

---

### ADR-016: Conversation Data Model

**Status:** Accepted
**Date:** 2026-01-26

**Context:** With multiple providers, each using different message formats (OpenAI's `role`/`content`, Anthropic's `content` blocks with separate system handling, Google's `parts`-based structure), we needed a single canonical message format that the app stores, displays, and can translate to any provider's wire format.

**Decision:** Define a provider-agnostic `Message` entity with a `role` enum (`user`, `assistant`, `system`, `tool`), a `content` field (text), optional structured fields for `images` (list of file paths), `toolCalls` (list of tool invocation records), and `toolResults` (list of tool execution results). Each provider adapter translates to/from this canonical format. The canonical model is serialized into the durable history-file format and projected into SQLite for search, list views, and other derived behaviors. Token counts, provider ID, model ID, and cost are stored as metadata on each message but are not part of the canonical content.

**Alternatives Considered:**
- **Store raw provider-specific JSON:** Preserves maximum fidelity, but makes cross-provider queries, search, and display logic provider-aware throughout the codebase.
- **OpenAI format as canonical (it's the most common):** Pragmatic, but Anthropic's system prompt handling and Google's parts-based format don't map cleanly; would require lossy conversion.
- **Store both canonical + raw:** Maximum flexibility, but doubles storage and creates a sync problem when messages are edited.

**Consequences:**
- ✅ UI code never deals with provider-specific message formats—always reads the canonical model.
- ✅ FTS5 search indexes the canonical `content` field and works identically regardless of which provider generated the response.
- ✅ Conversations can span providers (start with Ollama, continue with OpenAI) without format conflicts.
- ⚠️ Translation layer must handle edge cases: Anthropic's multi-block content, Google's inline images, tool call/result pairing.
- ⚠️ Some provider-specific metadata (e.g., Anthropic's `stop_reason` variants) is lost in translation unless stored in a metadata JSON blob.

---

### ADR-017: Project Organization Pattern

**Status:** Accepted
**Date:** 2026-01-26

**Context:** As the project grew from a simple Ollama chat client to a multi-provider platform with tool calling, cost tracking, and fallback logic, the original flat `lib/` structure became hard to navigate. We needed a consistent organizational pattern that scales with features without creating deep nesting or circular dependencies.

**Decision:** Adopt a layer-first organization with feature grouping within each layer. Top-level directories map to Clean Architecture layers: `core/` (shared utilities, constants, errors), `domain/` (entities, use cases, repository interfaces), `data/` (repository implementations, data sources, provider adapters), `presentation/` (screens, widgets, providers/state), and `services/` (cross-cutting services like TTS, share, storage). Within `presentation/screens/`, organize by feature (chat, models, settings, comparison). Provider implementations live in `data/providers/` with one file per provider.

**Alternatives Considered:**
- **Feature-first (vertical slices):** Group all layers for a feature together (e.g., `features/chat/data/`, `features/chat/domain/`, `features/chat/presentation/`). Good for large teams with feature ownership, but creates duplication for shared entities and makes cross-feature dependencies awkward for a single developer.
- **Flat structure (all files in lib/):** The simplest approach; works for <20 files but collapses at 50+.
- **Package-per-feature (Dart packages in monorepo):** Maximum isolation and enforced dependency rules, but heavy ceremony (pubspec per package, explicit exports) for a single-app project.

**Consequences:**
- ✅ Layer boundaries are immediately visible in the directory tree.
- ✅ Dependency rule (presentation → domain → data) is enforced by import conventions.
- ✅ New features follow a predictable pattern: add entity, add use case, add repository, add screen.
- ⚠️ Some files (e.g., `ModelInfo`) are referenced across many layers and can create import tangles if not placed carefully in `domain/entities/`.
- ⚠️ The `services/` directory is a catch-all that requires discipline to keep focused.

---

### ADR-018: File-Backed Portable History

**Status:** Accepted
**Date:** 2026-03-15

**Context:** Private Chat Hub now treats saved conversation history as a portable asset that users should be able to read, sync, and restore on another device without relying on the app's database. The product direction explicitly calls for plain-text history files, SQLite only for speed/cache, folder-local `AGENT.md` project configuration, and no extra sidecar files beyond what the history actually needs. Analysis of the sibling `opencode-chat` project showed a Markdown-compatible history proposal worth adopting, even though that repository does not yet use it as its canonical runtime format.

**Decision:** Store every saved project chat and agent chat as a Markdown-compatible plain-text history file inside a folder-backed project workspace. Each project folder may contain `AGENT.md` as its local configuration. SQLite remains a derived local index/cache for search, conversation lists, sync markers, and temporary unsaved chats, and it must be fully rebuildable from the file store. The history parser is fence-aware, preserves relative asset paths, and uses the same logic for project chats and agent chats.

**Alternatives Considered:**
- **SQLite as the source of truth:** Fast and structured, but not portable, not human-readable, and a poor fit for user-managed sync/restore.
- **JSON sidecar manifests per chat:** Easier to parse, but creates unnecessary extra files and makes manual inspection less pleasant.
- **First-party cloud sync service:** Could simplify multi-device flows, but conflicts with the product's privacy-first stance and would introduce hosted-state complexity.

**Consequences:**
- ✅ Users own a readable, diffable, portable conversation history format.
- ✅ Restoring a project on another device requires only the folder, not a database export.
- ✅ The same parser and renderer serve project chats and agent chats.
- ✅ SQLite can be dropped and rebuilt without losing saved history.
- ⚠️ Parsing must be Markdown-aware enough to ignore separator-like lines inside code fences.
- ⚠️ Conflict detection is required when the same folder is edited on multiple devices.
- ⚠️ Temporary unsaved chats live only in cache until the chosen save mode persists them.

---

### ADR-019: Mobile + Desktop Platform Scope

**Status:** Accepted
**Date:** 2026-03-15

**Context:** The product now targets both mobile and desktop usage. The existing Android-first framing is too narrow for the current direction, especially once portable history files and folder-backed projects allow the same workspace to move between phone and desktop environments.

**Decision:** Support an adaptive Flutter experience across mobile and desktop, with Android plus supported desktop platforms as the primary delivery targets. Core product behavior, file formats, and workspace semantics must remain platform-neutral, while share/import, secure storage, and file open/save surfaces use each platform's native integration points.

**Alternatives Considered:**
- **Remain Android-only:** Smaller QA matrix, but no longer matches the product's cross-device use case.
- **Desktop-only focus:** Strong file-system ergonomics, but loses the privacy and utility advantages of a mobile companion.
- **Web-first implementation:** Easier sharing, but weaker offline guarantees and a poorer fit for local models and platform-native storage.

**Consequences:**
- ✅ A single workspace can move between mobile and desktop without conversion.
- ✅ UX decisions now prioritize adaptive layouts rather than Android-only assumptions.
- ✅ Platform-native import/export flows become part of the core experience.
- ⚠️ The QA matrix expands significantly across screen sizes and desktop window states.
- ⚠️ Platform-specific integrations must stay behind abstractions to avoid UI drift.

---

## Decision Log Summary

| ADR | Decision | Date | Status | Owner |
|-----|----------|------|--------|-------|
| 001 | Mobile-first Android platform | 2025-12-31 | ♻️ Superseded | @product-owner |
| 002 | Provider abstraction pattern | 2025-12-31 | ✅ Accepted | @architect |
| 003 | Local-first data storage (SQLite + FTS5) | 2025-12-31 | ♻️ Superseded | @architect |
| 004 | Streaming-first chat experience | 2025-12-31 | ✅ Accepted | @architect |
| 005 | Material Design 3 theming | 2025-12-31 | ✅ Accepted | @experience-designer |
| 006 | Provider registry pattern | 2026-01-26 | ✅ Accepted | @architect |
| 007 | API key storage (flutter_secure_storage) | 2026-01-26 | ✅ Accepted | @architect |
| 008 | Cost tracking (provider-reported tokens) | 2026-01-26 | ✅ Accepted | @architect |
| 009 | Smart fallback chains (user-configurable) | 2026-01-26 | ✅ Accepted | @architect |
| 010 | Tool calling (provider-agnostic interface) | 2026-01-26 | ✅ Accepted | @architect |
| 011 | MCP integration (tool provider bridge) | 2026-01-26 | ✅ Accepted | @architect |
| 012 | Model capability detection (hybrid) | 2026-01-26 | ✅ Accepted | @architect |
| 013 | Offline behavior (graceful degradation) | 2026-01-26 | ✅ Accepted | @architect |
| 014 | Multi-provider comparison (dedicated mode) | 2026-01-26 | ✅ Accepted | @experience-designer |
| 015 | TTS integration (platform-native default) | 2026-01-26 | ✅ Accepted | @architect |
| 016 | Conversation data model (provider-agnostic) | 2026-01-26 | ✅ Accepted | @architect |
| 017 | Project organization (layer-first) | 2026-01-26 | ✅ Accepted | @architect |
| 018 | File-backed portable history | 2026-03-15 | ✅ Accepted | @architect |
| 019 | Mobile + desktop platform scope | 2026-03-15 | ✅ Accepted | @product-owner |

---

## Related Documents

- [USER_PERSONAS.md](USER_PERSONAS.md) — Target user personas informing ADR-001, ADR-009
- PRODUCT_REQUIREMENTS.md — Functional requirements driving all ADRs
- [ARCHITECTURE.md](ARCHITECTURE.md) — Full system architecture covering provider registry, services, and data model

---

*This is a living document. Update when architectural decisions are revisited, superseded, or new decisions are made.*
