# Phase 1 Flutter Android Foundation App - Requirements & Patterns Summary

## Overview
**Project:** Private Chat Hub v2  
**Platform:** Android (Flutter)  
**Scope:** Phase 1 Foundation (MVP - self-hosted and local models only)  
**Architecture Pattern:** Layer-first (Clean Architecture) with feature grouping  

---

## 1. ARCHITECTURE & DESIGN PATTERNS

### 1.1 Layered Architecture (ADR-017)
```
lib/
├── core/                  # Shared utilities, constants, errors, exceptions
├── domain/                # Entities, interfaces, use cases, constants
├── data/                  # Repositories, data sources, provider implementations
├── presentation/          # Screens, widgets, state management (Riverpod)
└── services/              # Cross-cutting concerns (TTS, share, storage, etc.)
```

**Key Principle:** Dependency rule enforced by convention: `presentation → services → domain → data`

### 1.2 Core Architecture Principles (ADRs 002, 006)

1. **Provider-Agnostic Core**
   - All LLM interaction flows through abstract `LLMProvider` interface
   - No service references specific backends directly
   - Services route through `ProviderRegistry`

2. **Provider Registry Pattern** (ADR-006)
   - Central `ProviderRegistry` holds `Map<String, LLMProvider>`
   - Providers self-register at app startup
   - `ChatService` resolves provider via registry lookup
   - Enables adding new providers without touching core chat logic

3. **Model ID as Routing Key** (Qualified IDs)
   - Each model: `provider:model-id` (e.g., `ollama:llama3.2`, `local:gemma3-1b`)
   - `ModelIdService` centralizes all parsing and validation
   - No other service needs to know about prefix conventions

4. **Offline-First** (ADR-003)
   - All conversations, messages, preferences stored locally
   - App fully functional with on-device models (no network required)
   - Queued sends persist across app restarts

5. **Streaming-First Chat** (ADR-004)
   - Token-by-token response display (not full-buffer)
   - 60 FPS cap with debounce logic
   - Cancellation support via CancelToken
   - Works across all providers (NDJSON, SSE)

6. **Capability-Driven UI**
   - Interface adapts to what selected model can do (vision, streaming, tool calling)
   - UI never shows features model doesn't support
   - Graceful degradation for missing capabilities

7. **Fail Gracefully** (ADR-009, ADR-013)
   - Smart fallback chains (configurable, user can choose)
   - Default: Cloud → Other Cloud → Self-Hosted → Local → Queue
   - Per-provider status tracking (READY, OFFLINE, RATE_LIMITED, ERROR)
   - Graceful degradation with clear user feedback

### 1.3 State Management
- **Framework:** Riverpod (already adopted)
- **Pattern:** Provider-based with lazy initialization
- **Service Locator:** Available for dependency injection

### 1.4 Storage Strategy (ADR-003, ADR-007, ADR-008)

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| Conversations, messages | SQLite (with FTS5) | Queryable, searchable, ACID transactions |
| User preferences | SharedPreferences | Simple key-value, fast access |
| API keys (Phase 2) | flutter_secure_storage | Android Keystore (hardware-backed) |
| Connection profiles | SQLite | Structured, multiple per provider |
| Model metadata | SQLite + cache | FTS5 for search, in-memory for speed |

---

## 2. CORE MODELS & ENTITIES

### 2.1 Data Models (Domain Layer)

**Conversation**
```dart
id: String
title: String
modelId: String (qualified: "ollama:llama3.2")
systemPrompt: String?
createdAt: DateTime
updatedAt: DateTime
archived: bool
```

**Message**
```dart
id: String
conversationId: String
role: MessageRole (user | assistant | system | tool)
content: String
status: MessageStatus (draft | queued | sending | sent | failed)
tokenUsage: {inputTokens, outputTokens}?
costUsd: double?
toolCalls: List<ToolCall>?
toolResults: List<ToolResult>?
timestamp: DateTime
```

**Message Status State Machine**
```
draft ──────┬──────► queued ──────────┐
            │        (offline)        │
            │                         ▼
            └────► sending ──────► sent
                        │
                        └──► failed (after max retries)
```

**Provider** (Registry Entity)
```dart
id: String (unique: "ollama", "openai", "local")
type: ProviderType (LOCAL | SELF_HOSTED | CLOUD | GATEWAY)
displayName: String
status: ProviderStatus (READY | UNCONFIGURED | OFFLINE | ERROR | RATE_LIMITED)
config: dynamic (provider-specific)
enabled: bool
```

**Model**
```dart
qualifiedId: String ("ollama:llama3.2")
providerId: String
displayName: String
contextWindow: int?
capabilities: {vision, tools, streaming, systemPrompt, ...}
costPerToken: {input, output}?  // Cloud only
```

**ConnectionProfile** (for Ollama, LM Studio, etc.)
```dart
id: String
providerKind: String (ollama | lmstudio)
name: String
host: String
port: int
useHttps: bool
isDefault: bool
lastConnectedAt: DateTime?
```

### 2.2 LLMProvider Interface (Core Abstraction)

```dart
abstract class LLMProvider {
  // Identity
  String get providerId;
  String get displayName;
  ProviderType get providerType;

  // Configuration
  bool get requiresApiKey;
  bool get requiresNetwork;
  bool get supportsStreaming;

  // Capabilities
  Future<ModelCapabilities> getCapabilities();

  // Models
  Future<List<Model>> listModels();
  Future<Model?> getModelInfo(String modelId);

  // Chat
  Stream<ChatResponse> sendMessage({
    required String modelId,
    required List<Message> messages,
    required ChatParams params,
  });

  // Health
  Future<ProviderHealth> checkHealth();
  ProviderStatus get currentStatus;

  // Lifecycle
  Future<void> initialize();
  Future<void> dispose();
}
```

**ChatResponse** (Tagged Union)
```dart
ChatResponse = 
  | Content(text: String)
  | ToolCall(name, arguments, id)
  | Usage(inputTokens, outputTokens)
  | Error(code, message, userAction, recoverable, suggestedFallback)
```

---

## 3. CORE SERVICES

### 3.1 Chat Service
**Responsibilities:**
- Accept send request (conversationId + userText)
- Resolve provider via registry
- Check provider health → trigger fallback or queue
- Stream response chunks to UI and persist messages
- Delegate tool calls to ToolService
- Record token usage via CostService

**Key Patterns:**
- No provider-specific logic (delegation via registry)
- Streaming response handling with line-buffered JSON parsing
- Automatic message persistence before network call
- Graceful error handling with user-facing messages

### 3.2 Model Service
**Responsibilities:**
- Poll each provider's `listModels()` on demand or schedule
- Cache results per-provider with independent TTLs (default 5 min)
- Merge into unified list with provider badges and capability tags
- Detect availability changes and notify UI
- Grouping: Remote (Ollama + LM Studio) · On-Device · Cloud (later phase)

### 3.3 Conversation Service
**Responsibilities:**
- CRUD: create, read, list, update, delete conversations
- Full-text search across messages (FTS5)
- Rename, archive, export (JSON/Markdown/Text)
- Per-conversation system prompts
- Aggregate metadata (model used, token totals, timestamps)

### 3.4 Settings Service
**Responsibilities:**
- Provider connection profiles (multi-server per type)
- API key storage delegation (later phase)
- Default model selection per provider type
- User preferences and theme settings
- Tool toggle states

**Connection Management Pattern (Shared by Ollama, LM Studio):**
- Each provider type supports multiple saved profiles
- One profile marked "default"
- First saved server becomes default automatically
- Deleting default promotes next remaining server

### 3.5 Message Queue Service
**Responsibilities:**
- Persist queued messages during offline periods
- FIFO queue processing with retry logic (0s, 5s, 15s backoff)
- Max 50 queued messages; user notified when full
- Emit stream for UI queue count and progress
- Max 3 retries; mark failed if exceeded

### 3.6 Provider Registry Service
**Responsibilities:**
- Manage `Map<String, LLMProvider>` of all providers
- Register providers at startup
- Lookup by providerId
- Filter providers (by type, status, enabled)
- Resolve model qualifiedId → (provider, rawModelId)
- Get merged model list across all healthy providers
- Initialize/dispose all providers

---

## 4. SCREENS & WIDGETS (Presentation Layer)

### 4.1 Primary Screens (Phase 1)

**Chat Screen (Home)**
- Message list with streaming display
- Markdown rendering with syntax-highlighted code
- Model chip in app bar (tappable → picker)
- Text input with send/stop toggle
- Tool toggle FAB (bottom-right)
- Navigation drawer (conversations)

**Model Picker (Bottom Sheet)**
- Unified model list across providers
- Filter chips: All, Remote, On-Device
- Groups: Recommended · Remote Models · On-Device
- Each model shows: name, provider, size, capabilities
- Tap to select; updates app bar

**Conversation Drawer**
- Conversations grouped by date (Today, Yesterday, Previous 7 Days, Older)
- Each row: title (auto-generated), model badge, timestamp
- Long-press: rename, move to project, archive, delete
- "New Chat" action at top
- Running Tasks section (when active)
- Settings link at bottom

**Settings Screen**
- Providers section (Remote Servers, On-Device)
  - Server list per type
  - Add/edit/delete/test server
  - Health status indicators
  - Set as default toggle
- Appearance (Theme, Dark/Light mode)
- Chat preferences
- Data & Privacy
- About

**Onboarding Screens** (First Time Setup)
- Welcome slide
- Choose Provider slide (Remote / On-Device / Skip)
- Provider-specific setup (host/port for Ollama, model pick for on-device)
- Success / confirmation slide

### 4.2 Key Widgets

**MessageBubble**
- User messages: right-aligned, filled primary
- AI messages: left-aligned, surface + outline
- Markdown rendering
- Code blocks: language label, copy button, horizontal scroll
- Streaming indicator (blinking cursor)
- Long-press menu: Copy, Edit & Resend (user) / Copy, Share, Regenerate (AI)

**ChatInput**
- Text field with multi-line support
- Attachment button (📎)
- Send button (➤) / Stop button (■ during generation)
- Attachment preview chips with remove (✕)
- Vision auto-detect: "Switch to vision model?" dialog

**ProviderHealthIndicator**
- Color-coded dots: 🟢 Connected, 🟡 Connecting, 🔴 Disconnected
- Tooltip: status detail

**ModelCapabilityBadges**
- Visual indicators: 💬 (streaming), 👁 (vision), 🛠 (tools), 💻 (code)
- Tappable for detail

**StreamingIndicator**
- Blinking cursor (500ms) inline in bubble
- Live token count display
- "Generating response" indicator
- Disappears on completion

---

## 5. NAMING & GROUPING CONVENTIONS

### 5.1 Directory Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   │   └── llm_provider_exception.dart
│   └── utils/
│       └── model_id_service.dart
│
├── domain/
│   ├── entities/
│   │   ├── conversation.dart
│   │   ├── message.dart
│   │   ├── model.dart
│   │   ├── provider.dart
│   │   ├── connection_profile.dart
│   │   └── chat_response.dart
│   ├── interfaces/
│   │   └── llm_provider.dart
│   └── repositories/
│       ├── conversation_repository.dart
│       └── provider_registry.dart
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── conversation_local_data_source.dart
│   │   │   └── sqlite_database.dart
│   │   └── remote/
│   │       └── http_client_config.dart
│   ├── repositories/
│   │   └── conversation_repository_impl.dart
│   └── providers/
│       ├── ollama_provider.dart
│       ├── local_model_provider.dart
│       └── provider_registry_impl.dart
│
├── presentation/
│   ├── screens/
│   │   ├── chat/
│   │   │   ├── chat_screen.dart
│   │   │   ├── chat_provider.dart  // Riverpod state
│   │   │   └── widgets/
│   │   ├── models/
│   │   │   ├── model_picker_sheet.dart
│   │   │   └── model_info_screen.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── provider_settings_screen.dart
│   │   │   └── appearance_settings_screen.dart
│   │   ├── onboarding/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── provider_setup_screen.dart
│   │   │   └── success_screen.dart
│   │   └── conversation/
│   │       └── conversation_drawer.dart
│   │
│   ├── widgets/
│   │   ├── message_bubble.dart
│   │   ├── chat_input.dart
│   │   ├── message_actions.dart
│   │   ├── model_chip.dart
│   │   ├── provider_health_indicator.dart
│   │   ├── capability_badges.dart
│   │   └── streaming_indicator.dart
│   │
│   └── providers/
│       ├── chat_provider.dart         // Riverpod state
│       ├── conversation_provider.dart
│       ├── model_provider.dart
│       └── settings_provider.dart
│
└── services/
    ├── chat_service.dart
    ├── conversation_service.dart
    ├── model_service.dart
    ├── settings_service.dart
    ├── message_queue_service.dart
    ├── provider_registry_service.dart
    └── fallback_service.dart
```

### 5.2 Naming Conventions

**Files:**
- Use snake_case for filenames (e.g., `chat_service.dart`)
- Suffix by type: `_service.dart`, `_provider.dart`, `_screen.dart`, `_widget.dart`
- Data source files: `*_local_data_source.dart`, `*_remote_data_source.dart`
- Repository implementations: `*_repository_impl.dart`

**Classes:**
- Use PascalCase (e.g., `ChatService`, `ConversationRepository`)
- Service classes: suffix with "Service" (e.g., `ChatService`)
- Provider implementations: suffix with "Provider" (e.g., `OllamaProvider`)
- Repository interfaces: use base name (e.g., `ConversationRepository`)
- Repository implementations: suffix with "Impl" (e.g., `ConversationRepositoryImpl`)
- Riverpod providers: suffix with "Provider" and declare with `.family` or `.watch` as needed
- Enums: PascalCase (e.g., `MessageRole`, `ProviderStatus`)

**Riverpod Providers:**
- Service providers: `final chatServiceProvider = Provider((ref) => ChatService(...));`
- State notifiers: `final chatStateProvider = StateNotifierProvider<ChatStateNotifier, ChatState>(...);`
- Stream providers: `final conversationsStreamProvider = StreamProvider<List<Conversation>>(...);`
- Family providers: `final modelsByProviderProvider = FutureProvider.family<List<Model>, String>(...);`

**Enums:**
- `MessageRole` (user, assistant, system, tool)
- `MessageStatus` (draft, queued, sending, sent, failed)
- `ProviderType` (LOCAL, SELF_HOSTED, CLOUD, GATEWAY)
- `ProviderStatus` (READY, UNCONFIGURED, OFFLINE, ERROR, RATE_LIMITED)

**Constants:**
- File: `lib/core/constants/`
- Prefix enum name: `const kMaxQueuedMessages = 50;`
- Use `k` prefix for constants (Dart convention)

---

## 6. TESTING STRATEGY

### 6.1 Test Organization

```
test/
├── unit/
│   ├── services/
│   │   ├── chat_service_test.dart
│   │   ├── conversation_service_test.dart
│   │   └── model_service_test.dart
│   ├── domain/
│   │   └── model_id_service_test.dart
│   └── data/
│       ├── repositories/
│       │   └── conversation_repository_impl_test.dart
│       └── providers/
│           ├── ollama_provider_test.dart
│           └── local_model_provider_test.dart
│
├── widget/
│   ├── screens/
│   │   ├── chat_screen_test.dart
│   │   └── model_picker_test.dart
│   └── widgets/
│       ├── message_bubble_test.dart
│       └── chat_input_test.dart
│
└── integration/
    └── chat_flow_test.dart
```

### 6.2 Testing Patterns

**Unit Tests:**
- Mock `LLMProvider` interface for service tests
- Test provider implementations with fake HTTP responses
- Test error handling and fallback logic
- Test streaming JSON parsing

**Widget Tests:**
- Test UI rendering with different states
- Test user interactions (tap, long-press)
- Test accessibility (semantic labels, touch targets)

**Integration Tests:**
- Full chat flow (send message → streaming response → persistence)
- Provider fallback when primary fails
- Offline queue and retry

**Coverage Target:** >70% (Phase 1 success criteria)

---

## 7. SECURITY & STORAGE PATTERNS

### 7.1 API Keys (Phase 2, documented here for awareness)
- **Storage:** `flutter_secure_storage` → Android Keystore
- **Never:** log, export, or store in SharedPreferences
- **Implementation:** API key ref in SQLite, actual key in Keystore

### 7.2 Data at Rest
- Conversations/messages: SQLite in app-private directory
- Android 10+ file-based encryption applied automatically
- No additional encryption layer needed for Phase 1

### 7.3 Network Security (Opinionated Defaults)
- **HTTPS required** for all production traffic
- **HTTP allowed** for localhost and emulator only (development)
- Network Security Config: `android/app/src/main/res/xml/network_security_config.xml`
- For Ollama on local network: cleartext allowed for trusted LAN addresses

### 7.4 Permissions (Opinionated Defaults - INTERNET enabled)
- **Required:** INTERNET, ACCESS_NETWORK_STATE
- **Optional (commented out):** CAMERA, RECORD_AUDIO, READ_EXTERNAL_STORAGE (Phase 3 for attachments)

---

## 8. PROVIDER IMPLEMENTATIONS (Phase 1)

### 8.1 Ollama Provider (Self-Hosted)

**Requirements:**
- User configures: host, port, HTTPS toggle
- Connection validation before save
- Health check endpoint: `/api/tags`
- Model listing: `/api/tags`
- Chat endpoint: `/api/generate` (streaming)
- Multiple connection profiles per provider
- Status indicators in real time

**Connection Pattern:**
- Stored in SQLite ConnectionProfile table
- One profile marked "default"
- Auto-discover option (mDNS, port 11434)
- Test connection before saving
- Health checks background (60s interval)

**Model Resolution:**
- Ollama models returned as `ollama:{model-name}`
- Example: `ollama:llama3.2`, `ollama:qwen2:7b`

**Streaming:**
- Newline-delimited JSON responses
- Each line: `{"response":"token","done":false}`
- Final line: `{"done":true,"total_duration":...,"load_duration":...,"sample_count":...,"sample_duration":...}`

**Capabilities Detection:**
- Use bundled lookup table for common models (llama, mistral, gemma)
- Fallback: probe with minimal tool-calling test request
- Models without vision/tools support: degrade gracefully

### 8.2 Local Model Provider (On-Device)

**Requirements:**
- Use LiteRT (TensorFlow Lite) for inference
- Or: Gemini Nano (Android 14+) if available
- Fully offline operation
- Model download/management within app
- Support for small models (<4B parameters)

**Supported Models (Phase 1):**
- Gemma 2B
- Phi-3 Mini
- Other lightweight GGUF quantized models

**Model Management:**
- Model picker shows: size, download status, storage location
- Download progress with cancel option
- Delete to free storage
- Auto-unload after 5 minutes of inactivity

**Model Resolution:**
- Local models returned as `local:{model-name}`
- Example: `local:gemma-2b`, `local:phi-3-mini`

**Streaming:**
- Token-by-token generation from inference engine
- May not support streaming natively; chunk output as tokens appear

**Capabilities:**
- Text generation only (no vision, no tools for Phase 1)
- Offline-first, zero cost

---

## 9. DEFAULT CONFIGURATION (OPINIONATED_DEFAULTS.md)

| Setting | Default | Rationale |
|---------|---------|-----------|
| Default provider | Self-hosted (Ollama) | Privacy-first positioning |
| Fallback behavior | Ask user | Respect user's privacy choice |
| Streaming | Enabled | Better perceived performance |
| Markdown rendering | Enabled | AI responses use markdown |
| Dark mode | System default | Respect OS preference |
| HTTPS | Enforced (HTTP for localhost) | Security by default |

---

## 10. DESIGN LANGUAGE & THEMES

### 10.1 Material Design 3 (ADR-005)

**Framework:**
- `ColorScheme.fromSeed()` for theming
- Semantic color roles: primary, secondary, surface, error
- Support dynamic color (Android 12+)
- Dark mode first, light mode as token inversion

**Theming:**
- `MaterialApp` with `themeData` and `darkTheme`
- Dynamic color via `dynamic_color` package (opt-in on Android 12+)
- Fallback to seed-based palette on older devices

**Layout Grid:** 8dp baseline grid
- Touch targets: ≥48 dp
- Text: ~16 sp body, ~28 sp headline
- Icons: 24 dp standard, 56 dp FAB

**Components:**
- `FilledButton` for primary actions
- `OutlinedButton` for secondary
- `NavigationBar` for main nav
- `FloatingActionButton` for floating actions
- `BottomSheet` for pickers and menus
- `Snackbar` for transient notifications

### 10.2 Accessibility (WCAG AA)

- **Text contrast:** ≥4.5:1 for normal text, ≥3:1 for large
- **Touch targets:** ≥48 × 48 dp minimum
- **Font scaling:** Support up to 200%
- **TalkBack:** All interactive elements have semantic labels
- **Screen reader:** Proper heading structure, alt text for images
- **No color-only indication:** Always pair with icon or text

---

## 11. KEY DECISION LOG (for Phase 1)

| ADR | Decision | Rationale | Phase |
|-----|----------|-----------|-------|
| 001 | Mobile-first Android + Flutter | Reduce testing matrix, faster iteration | 1 |
| 002 | Provider abstraction pattern | Enable multi-provider without refactor | 1 |
| 003 | SQLite + FTS5 (local-first) | Structured, searchable, ACID | 1 |
| 004 | Streaming-first responses | Better UX than spinner | 1 |
| 005 | Material Design 3 | Modern, themeable, accessible | 1 |
| 006 | Provider registry pattern | Extensible, no touching ChatService | 1 |
| 017 | Layer-first organization | Clear boundaries, scalable | 1 |

---

## 12. SUCCESS CRITERIA (Phase 1)

- [x] Provider abstraction interface defined
- [x] Ollama provider implementation (connection, model listing, streaming)
- [x] Local model provider implementation (LiteRT or equivalent)
- [x] Chat Service with streaming response handling
- [x] Conversation persistence (SQLite)
- [x] UI: Chat screen, Model picker, Settings, Onboarding
- [x] Message queue for offline mode
- [x] Fallback chains (configurable)
- [ ] User can hold multi-turn conversation with streaming ✓
- [ ] Markdown renders correctly ✓
- [ ] Conversations persist across restarts ✓
- [ ] Ollama connection < 2s setup ✓
- [ ] Local model inference works offline ✓
- [ ] App starts in < 2s ✓
- [ ] Crash-free > 99% ✓
- [ ] Test coverage > 70% ✓

---

## 13. DEPENDENCIES (Key Libraries - Phase 1)

- **State Management:** `riverpod`
- **HTTP:** `dio`
- **Local Database:** `sqflite`
- **Markdown:** `flutter_markdown`
- **Syntax Highlighting:** `highlight` (bundled with flutter_markdown or custom)
- **Async:** `stream_transform`, `async`
- **Testing:** `mockito`, `mocktail`, `flutter_test`
- **Android:** `path_provider`, `connectivity_plus`
- **Logging:** `logger`
- **Environment:** `flutter_dotenv`

**Phase 2 additions:** `flutter_secure_storage`, `dio_http_cache`, `google_generative_ai`, `http` (OpenAI/Anthropic SDKs)

---

## 14. FILE STRUCTURE EXAMPLE (Single Feature)

Example: Chat feature from domain to presentation

```
lib/
├── domain/
│   ├── entities/
│   │   ├── message.dart          # Message entity
│   │   ├── conversation.dart     # Conversation entity
│   │   └── chat_response.dart    # Streaming response types
│   └── interfaces/
│       └── llm_provider.dart     # LLMProvider abstract interface
│
├── data/
│   ├── datasources/
│   │   └── local/
│   │       ├── conversation_local_data_source.dart
│   │       └── sqlite_database.dart
│   ├── repositories/
│   │   └── conversation_repository_impl.dart
│   └── providers/
│       ├── ollama_provider.dart
│       └── local_model_provider.dart
│
├── presentation/
│   ├── screens/
│   │   └── chat/
│   │       ├── chat_screen.dart          # UI
│   │       ├── chat_notifier.dart        # State logic
│   │       ├── chat_state.dart           # State model
│   │       └── widgets/
│   │           ├── message_bubble.dart
│   │           └── chat_input.dart
│   └── providers/
│       └── chat_provider.dart            # Riverpod: StateNotifierProvider<ChatNotifier, ChatState>
│
└── services/
    ├── chat_service.dart                 # Business logic (non-UI)
    ├── conversation_service.dart
    └── message_queue_service.dart
```

---

## Summary

**Phase 1 is the foundation.** Build the provider abstraction and clean architecture now so cloud providers, tool calling, and MCP integrate seamlessly in later phases. All design patterns, naming conventions, and tests should follow this foundation to enable rapid feature addition without refactoring.

**Key constraint:** NO backend-specific logic in services or screens. Everything routes through LLMProvider interface and ProviderRegistry.
