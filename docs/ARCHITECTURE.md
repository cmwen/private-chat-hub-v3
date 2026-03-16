# Architecture: Private Chat Hub v2

**Status:** Design Specification — Clean Rebuild  
**Scope:** Complete system architecture for a multi-provider AI chat application on mobile and desktop

---

## 1. System Overview

Private Chat Hub is a privacy-first Flutter app for chatting with AI models across
mobile and desktop devices. It connects to on-device inference, self-hosted servers,
cloud APIs, and gateway aggregators through a single provider interface routed by a
central registry.

Saved chat history is durable as plain-text files. SQLite is a derived local
index/cache used for fast search, browsing, temporary unsaved state, and rebuildable
performance optimizations.

### System Context Diagram

```
                              ┌───────────────────┐
                              │ Mobile/Desktop    │
                              │      User         │
                              └────────┬──────────┘
                                       │
                          ┌────────────▼────────────┐
                          │   Private Chat Hub      │
                          │ (Flutter Mobile/Desktop)│
                          └──┬────┬────┬────┬────┬──┘
                             │    │    │    │    │
              ┌──────────────┘    │    │    │    └──────────────┐
              ▼         ┌────────┘    │    └────────┐          ▼
        ┌──────────┐    ▼             ▼             ▼    ┌─────────┐
        │ On-Device│ ┌──────────┐ ┌──────────┐ ┌──────┐ │  MCP    │
        │ (LiteRT) │ │Self-Host │ │ Cloud    │ │Gate- │ │ Servers │
        │          │ │ Ollama   │ │ OpenAI   │ │way   │ │         │
        │ Local    │ │ LM Studio│ │ Anthropic│ │Open- │ │ Tool    │
        │ inference│ │          │ │ Google AI│ │Code  │ │ discov. │
        └──────────┘ └──────────┘ └──────────┘ └──────┘ └─────────┘
         (device)    (LAN/VPN)     (internet)  (local)   (network)
```

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  PRESENTATION        Screens, Widgets, State Management             │
├─────────────────────────────────────────────────────────────────────┤
│  SERVICES            ChatService, ModelService, CostService, ...    │
├─────────────────────────────────────────────────────────────────────┤
│  PROVIDER LAYER      ProviderRegistry ─► LLMProvider implementations│
├─────────────────────────────────────────────────────────────────────┤
│  DATA LAYER          Repositories, History Files, SQLite Index,     │
│                      Preferences, Cache                              │
├─────────────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER      HTTP clients, Platform channels, Native bridge │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Architecture Principles

1. **Provider-agnostic core.** Services never reference a specific backend directly.
   All LLM interaction flows through the `LLMProvider` interface and `ProviderRegistry`.

2. **Model ID as routing key.** Every model has a provider-qualified ID
   (`ollama:llama3.2`, `openai:gpt-4o`, `local:gemma3-1b`). Routing is determined
   by parsing the prefix — not by a global mode switch.

3. **File-backed, offline-first.** Saved conversations persist as plain-text
   history files. SQLite accelerates search, browsing, sync detection, and
   recoverable temporary state, but it is never the authoritative history store.

4. **Portable workspace model.** Chats live inside folder-backed projects. Each
   project folder may contain `persona.md` as its local configuration, and the same
   folder can be restored on another device without translation.

5. **Capability-driven UI.** The interface adapts to what the selected model can do
   (streaming, vision, tool calling, etc.) rather than showing a fixed feature set.

6. **Cost transparency.** Cloud API usage is tracked per-message with configurable
   limits and warnings. Self-hosted and local providers report zero cost.

7. **Fail gracefully.** When a provider is unavailable the system can fall back to
   an alternative provider, queue the message for later, or clearly tell the user
   what happened and what to do next.

8. **Extension over modification.** New providers, tools, and features are added by
   registering new implementations — not by editing core routing logic.

---

## 3. Provider System

### 3.1 Provider Interface

Every backend implements this contract. The interface is intentionally minimal;
providers that lack a capability (e.g. cost estimation for local models) return
a no-op or null result.

```
LLMProvider
├── Identity
│   ├── providerId        → unique key ("ollama", "openai", "local", ...)
│   ├── displayName       → human-readable label
│   └── providerType      → LOCAL | SELF_HOSTED | CLOUD | GATEWAY
│
├── Configuration
│   ├── requiresApiKey    → bool
│   ├── requiresNetwork   → bool
│   └── supportsStreaming  → bool
│
├── Capabilities
│   └── getCapabilities() → vision, tools, streaming, system prompt, ...
│
├── Models
│   ├── listModels()      → available models with metadata
│   └── getModelInfo(id)  → single model detail
│
├── Chat
│   └── sendMessage(modelId, messages, params) → Stream<ChatResponse>
│
├── Health
│   ├── checkHealth()     → reachable / latency / error detail
│   └── currentStatus     → READY | UNCONFIGURED | OFFLINE | ERROR | RATE_LIMITED
│
├── Cost (optional)
│   └── estimateCost(modelId, messages) → token counts + USD estimate
│
└── Lifecycle
    ├── initialize()
    └── dispose()
```

`ChatResponse` is a tagged union of:
- **Content** — a text chunk (streamed incrementally)
- **ToolCall** — the model is requesting a tool invocation
- **Usage** — token counts for the completed turn
- **Error** — a provider-level error with recovery hints

### 3.2 Provider Registry

The registry is the single lookup point for all provider instances. Services never
hold direct references to provider implementations.

```
ProviderRegistry
├── register(provider)           → add a provider at startup
├── getProvider(providerId)      → lookup by ID
├── listProviders(filters)       → filter by type, status, enabled
├── resolveModel(qualifiedId)    → parse prefix → (provider, rawModelId)
├── getAllModels()                → merged list across all healthy providers
└── initializeAll() / dispose()  → lifecycle for all registered providers
```

**Resolution flow** for a qualified model ID like `anthropic:claude-sonnet-4`:

```
"anthropic:claude-sonnet-4"
       │
       ├── parse prefix ──► providerId = "anthropic"
       ├── strip prefix ──► rawModelId = "claude-sonnet-4"
       └── registry.getProvider("anthropic") ──► AnthropicProvider instance
```

Legacy unqualified IDs (e.g. `llama3.2`) are treated as `ollama:llama3.2` during
a migration window, then phased out.

### 3.3 Provider Types

| Type | Examples | Network | API Key | Cost |
|------|----------|---------|---------|------|
| **Local** | LiteRT (on-device) | None | No | Free |
| **Self-Hosted** | Ollama, LM Studio | LAN / VPN | No | Free |
| **Cloud** | OpenAI, Anthropic, Google AI | Internet | Yes | Per-token |
| **Gateway** | OpenCode | Localhost | Optional | Varies |

Self-hosted providers share a common connection model (host, port, HTTPS toggle,
health check) and appear together in a single "Remote Servers" settings section.
Gateway providers (OpenCode) are visually separated because they carry different
trust, billing, and credential expectations.

### 3.4 Model Resolution

Every persisted model reference uses the qualified form `provider:model-id`.

| Prefix | Provider | Example |
|--------|----------|---------|
| `local:` | LiteRT on-device | `local:gemma3-1b` |
| `ollama:` | Ollama server | `ollama:llama3.2:3b` |
| `lmstudio:` | LM Studio server | `lmstudio:qwen2-7b` |
| `openai:` | OpenAI API | `openai:gpt-4o` |
| `anthropic:` | Anthropic API | `anthropic:claude-sonnet-4` |
| `google:` | Google AI API | `google:gemini-2.0-flash` |
| `opencode:` | OpenCode gateway | `opencode:anthropic/claude-sonnet-4` |

A `ModelIdService` centralises all parsing, validation, and display-name
derivation so no other service needs to know about prefix conventions.

---

## 4. Core Services

### 4.1 Chat Service

Central router for all message sends. It does **not** contain provider-specific
logic; it delegates to whatever provider the registry resolves for the
conversation's model.

**Responsibilities:**
- Accept a send request (conversation ID + user text)
- Resolve the provider via the registry; if unhealthy → fallback or queue
- Stream response chunks to the UI and hand completed turns to file persistence
- Delegate tool calls to `ToolService` and feed results back to the model
- Record token usage via `CostService`

**Fallback chain** (configurable, default by provider type):

```
Cloud failed     → other Cloud → Self-Hosted → Local → queue
Self-Hosted fail → Cloud (if configured) → Local → queue
Local failed     → Self-Hosted → Cloud → show error
```

### 4.2 Model Service

Aggregates model lists from every registered, healthy provider into one catalog.

**Responsibilities:**
- Poll each provider's `listModels()` on demand or on a schedule
- Cache results per-provider with independent TTLs
- Merge into a unified list with provider badges and capability tags
- Detect availability changes and notify the UI

**Model grouping in UI:** Remote Models (Ollama + LM Studio grouped, with source
badges) · On-Device Models · Cloud Models (OpenAI, Anthropic, Google — shown when
API keys configured) · Gateway Models (OpenCode).

### 4.3 Conversation Service

CRUD for conversations and messages across folder-backed projects. The service owns
history-file save/restore behavior, project discovery, full-text search projections,
and aggregate metadata (model used, token totals, timestamps).

**Responsibilities:**
- Create and update plain-text history files for saved chats
- Parse history files into the canonical conversation/message model
- Discover project folders and read local defaults from `persona.md`
- Maintain SQLite-backed search/index projections derived from files
- Import and reindex synced history folders restored from another device
- Support save modes for automatic, prompted, or manual history creation
- CRUD for conversations and messages: create, rename, delete, archive, full-text
  search, export (native history / JSON / Markdown / plain text), per-conversation
  system prompts, and aggregate metadata (model used, token totals, timestamps)

### 4.4 Tool Service

Handles tool calling and MCP (Model Context Protocol) integration.

**Responsibilities:**
- Registry of available tools (built-in + MCP-discovered)
- Validate, execute, and return tool results when model issues a tool call
- User-configurable tool toggles (enable/disable per tool)
- Track invocations for analytics; manage MCP server connections

**Built-in tools:** web search, URL content fetch, code search.

**MCP tools** are discovered at runtime from configured MCP servers and surfaced
alongside built-in tools with the same toggle and execution interface.

**Tool execution flow:**

```
Model returns tool_call → ToolService validates & executes
→ result recorded in history → fed back to model as tool_response
→ model generates final answer incorporating tool output
```

### 4.5 Cost Service

Tracks token usage and estimated cost for cloud API providers.

**Responsibilities:**
- Record per-message usage (input tokens, output tokens, cost in USD)
- Aggregate by provider, model, and time period
- Enforce spending limits (warning threshold + hard cap; auto-disable on cap)
- Self-hosted and local providers always report zero cost

### 4.6 Settings Service

Central store for user preferences and provider configuration.

**Responsibilities:**
- Provider connection profiles (multi-server per provider type)
- API key storage (delegated to platform secure storage)
- Default model selection per provider type
- Tool toggle states and UI preferences
- Chat history save mode (`Automatically`, `Ask before saving`, `Only when I tap Save`)
- Import/export defaults and local reindex requests

**Connection management pattern** (shared by Ollama, LM Studio, OpenCode):
- Each provider type supports multiple saved server profiles
- One profile per provider is marked "default"
- First saved server becomes default automatically
- Deleting the default promotes the next remaining server

---

## 5. Data Model

The architecture distinguishes between the **durable file model** and the
**derived SQLite model**:

- **Durable:** plain-text history files inside folder-backed projects
- **Derived:** SQLite records used for FTS/search, conversation lists, sync markers,
  temporary unsaved chats, and other performance-sensitive views

### Key Entities

```
┌─────────────┐       ┌─────────────┐
│ Conversation │──1:N──│   Message   │
├─────────────┤       ├─────────────┤
│ id           │       │ id          │
│ title        │       │ role        │  (user | assistant | system | tool)
│ modelId      │       │ content     │
│ systemPrompt │       │ status      │  (draft | queued | sending | sent | failed)
│ createdAt    │       │ tokenUsage  │
│ updatedAt    │       │ costUsd     │
│ archived     │       │ toolCalls   │──0:N──┐
└─────────────┘       │ timestamp   │       │
                      └─────────────┘       │
                                            ▼
┌─────────────┐       ┌──────────────┐  ┌──────────────┐
│   Provider   │       │  ToolCall    │  │  ToolResult  │
├─────────────┤       ├──────────────┤  ├──────────────┤
│ id           │       │ id           │  │ toolCallId   │
│ type         │       │ toolName     │  │ output       │
│ displayName  │       │ arguments    │  │ success      │
│ status       │       │ timestamp    │  │ duration     │
│ config       │       └──────────────┘  └──────────────┘
│ enabled      │
└─────────────┘
                      ┌──────────────┐  ┌───────────────┐
                      │    Model     │  │  CostRecord   │
                      ├──────────────┤  ├───────────────┤
                      │ qualifiedId  │  │ providerId    │
                      │ providerId   │  │ modelId       │
                      │ displayName  │  │ conversationId│
                      │ contextWindow│  │ inputTokens   │
                      │ capabilities │  │ outputTokens  │
                      │ costPerToken │  │ costUsd       │
                      └──────────────┘  │ timestamp     │
                                        └───────────────┘

┌──────────────────┐
│ ConnectionProfile│
├──────────────────┤
│ id               │
│ providerKind     │  (ollama | lmstudio | opencode)
│ name             │
│ host             │
│ port             │
│ useHttps         │
│ isDefault        │
│ lastConnectedAt  │
└──────────────────┘
```

The entities above are the logical application model and are cached/indexed in
SQLite. Durable storage on disk follows a portable workspace layout:

### Durable Workspace Layout

```text
<project-folder>/
├── persona.md
├── history/
│   └── YYYY-MM-DD-<short-title>.md
└── images/                  # optional, only when referenced by history
```

- `persona.md` stores project-local defaults and agent-like configuration.
- `history/` contains the saved chat transcripts.
- No sidecar metadata files are required beyond `persona.md` and any referenced
  assets.

### History File Format

Saved chat history uses a Markdown-compatible plain-text format:

```markdown
# Chat Session: <topic or date>
Started: YYYY-MM-DD HH:MM

---

## [YYYY-MM-DD HH:MM] <sender>

<message body in markdown>
```

The parser must be block-aware:
- `---` is a message separator only when it appears outside fenced code blocks
- Message bodies preserve Markdown, code fences, and relative image paths
- The same parser is used for both project chats and agent chats
- SQLite-derived IDs and sync metadata stay in the cache/index, not in extra files

### Message Status State Machine

```
                          ┌──────────┐
                    ┌────►│  queued  │  (offline, waiting for connectivity)
                    │     └────┬─────┘
                    │          │ connectivity restored
  ┌───────┐        │     ┌────▼─────┐     ┌──────┐
  │ draft │────────┴────►│ sending  │────►│ sent │
  └───────┘              └────┬─────┘     └──────┘
                              │
                         ┌────▼─────┐
                         │ failed   │  (after max retries)
                         └──────────┘
```

---

## 6. Cross-Cutting Concerns

### 6.1 Error Handling & Fallback

Errors are wrapped in a structured `LLMProviderException` that includes:
- **Error code** — machine-readable (`RATE_LIMITED`, `INVALID_API_KEY`, …)
- **User message** — what to show in the chat bubble
- **User action** — what the user can do ("Check your API key in Settings")
- **Recoverable flag** — whether retry or fallback makes sense
- **Suggested fallback** — optional alternative provider or model

Chat Service catches provider exceptions and either attempts the fallback chain
or surfaces the error to the UI with the action hint.

### 6.2 Offline Support

| Scenario | Behavior |
|----------|----------|
| Network unavailable + remote model | Message queued; queue badge shown |
| Network unavailable + local model | Works normally (no network needed) |
| Network restored | Queue processed FIFO with retry (0s, 5s, 15s backoff) |
| Queue full (50 messages) | User notified; new sends blocked until space |
| Max retries exceeded (3) | Message marked failed; user can retry manually |

The `MessageQueueService` persists queued items to local storage and emits a
stream so the UI can show queue count and processing progress.

### 6.3 Security

| Concern | Approach |
|---------|----------|
| API key storage | Platform secure storage |
| Saved chat history | Plain-text files in app-local or user-managed synced folders; never uploaded by the app |
| SQLite index/cache | Rebuildable local cache; safe to delete and regenerate from history files |
| Network (cloud) | HTTPS enforced for all cloud API calls |
| Network (LAN) | HTTPS toggle available; LAN assumed trusted by default |
| Model files | Downloaded from trusted sources; checksum verification |
| Queue data / temporary chats | Stored locally until sent, saved, or discarded according to save mode |

### 6.4 Performance

**Caching:**
- Model lists cached per-provider with configurable TTL (default 5 min)
- Conversation list uses incremental updates from the SQLite projection, not full reload
- Provider health status cached between polling intervals (30s)
- FTS/search index is rebuilt from history files when imported or resynced

**Streaming:**
- All chat responses are streamed token-by-token to the UI
- Responses are never fully buffered before display
- Stream controllers are cleaned up on cancellation or completion

**Resource management:**
- On-device models auto-unload after 5 minutes of inactivity
- Conversation history sent to models is capped (last N messages) to
  stay within context windows and limit latency
- Parallel model comparison streams are independent and cancellable

**Lazy initialization:**
- Providers are registered at startup but not initialised until first use
- MCP tool discovery runs in the background after app launch

---

## 7. Extension Points

### Adding a New Provider

1. Implement the `LLMProvider` interface for the new backend
2. Choose a unique `providerId` and model prefix
3. Register the provider in the app's startup sequence
4. Add a connection profile type (if network-based) to `ConnectionProfile`
5. The provider's models will automatically appear in the unified model list
   and be routable by the Chat Service — no other service changes needed

### Adding a New Tool

1. Define the tool's JSON Schema (name, description, parameters)
2. Implement execution logic (HTTP call, local computation, etc.)
3. Register the tool with `ToolService`
4. The tool is automatically available to models that support tool calling
   and appears in the user's tool toggle settings

### Adding MCP Servers

1. User adds an MCP server URL in Settings
2. `ToolService` connects and discovers available tools at runtime
3. Discovered tools appear alongside built-in tools with the same UX

### Model Comparison

The Chat Service supports a `sendComparisonMessage()` variant that fans out the
same prompt to 2–4 models in parallel, collects responses independently, and
links them to the same user message for side-by-side display. Each response
tracks its own token usage and timing metrics.

---

## Appendix: Decision Log

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Provider abstraction | Common `LLMProvider` interface + registry | Most extensible; avoids mode-switch spaghetti |
| 2 | Model routing | Provider-qualified IDs (`provider:model`) | Eliminates ambiguity when providers share model names |
| 3 | LM Studio integration | Sibling of Ollama under "Self-Hosted", not a new mode | Both are user-managed servers; separate modes would clutter Settings |
| 4 | OpenCode integration | Gateway provider type, visually separated | Different trust/billing model from self-hosted servers |
| 5 | Fallback strategy | Configurable chain per provider type | Balances convenience with user control over data flow |
| 6 | State management | Riverpod providers | Already adopted; supports lazy init and dependency injection |
| 7 | Local persistence | Plain-text history files + SQLite index/cache + SharedPreferences | Files are the source of truth; SQLite accelerates queries/FTS; SharedPrefs handles simple KV |
| 8 | Streaming protocol | SSE / chunked HTTP depending on backend | Provider implementations normalise to a common `Stream<ChatResponse>` |
| 9 | Connection model | Multi-server profiles per provider kind | Supports users with multiple Ollama/LM Studio boxes |
| 10 | Cost tracking | Per-message recording with period-based limits | Gives users fine-grained visibility and automatic safety nets |
| 11 | Project configuration | `persona.md` per project folder | Keeps project defaults portable with the history files |
