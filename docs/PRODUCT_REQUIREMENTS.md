# Product Requirements: Private Chat Hub

**Status:** Active  
**Prioritization:** MoSCoW (Must / Should / Could / Won't Have)

---

## Document Overview

This document defines the complete functional and non-functional requirements for Private Chat Hub — a privacy-first mobile and desktop app for chatting with AI models across local, self-hosted, and cloud providers. Requirements are technology-agnostic, grouped by functional area, and prioritized using MoSCoW.

Saved chat history is stored as portable plain-text files. SQLite is used only as a local cache/index for speed, search, sync detection, and recoverable temporary state.

**Requirement ID Format:** `AREA-NNN` (e.g., `CHAT-001`, `PROV-002`)

---

## 1. Functional Requirements

### 1.1 Chat & Messaging

#### CHAT-001: Text Chat with Streaming (Must Have)
**Description:** Users send text messages and receive streamed AI responses in real time.

**Acceptance Criteria:**
- User can compose and send multi-line text messages
- AI responses stream token-by-token with visible progress
- Clear visual distinction between user and AI messages
- Chat auto-scrolls to the latest message
- A loading/typing indicator is visible while the model is generating
- Chat remains responsive (no UI freeze) during streaming
- Saved conversations reopen from their plain-text history files across app restarts

#### CHAT-002: Markdown & Code Rendering (Must Have)
**Description:** AI responses render rich Markdown including code blocks, lists, tables, and links.

**Acceptance Criteria:**
- Fenced code blocks render with syntax highlighting
- Inline code, bold, italic, links, and lists render correctly
- Links are tappable and open in browser
- Tables render in a readable format
- Raw Markdown is never shown to the user

#### CHAT-003: Message Actions (Should Have)
**Description:** Users can interact with individual messages after they are sent.

**Acceptance Criteria:**
- Long-press (or menu) on any message reveals: Copy, Delete, Retry (AI), Edit & Resend (user)
- Copy preserves formatting for code blocks
- Retry resends the same prompt and replaces the failed response
- Edit opens the message text for modification, then resends
- Delete removes the message from the conversation with confirmation

#### CHAT-004: Image Input for Vision Models (Must Have)
**Description:** Users can attach images to messages for analysis by vision-capable models.

**Acceptance Criteria:**
- User can attach images from gallery or camera
- Multiple images can be attached to a single message
- Image thumbnails are previewed before sending; user can remove them
- If the active model lacks vision capability, the app warns before sending
- Images are compressed to a reasonable size before transmission

#### CHAT-005: File Attachment as Context (Must Have)
**Description:** Users can attach text-based files to provide context to the model.

**Acceptance Criteria:**
- Supported types include at minimum: TXT, MD, PDF, and common code files
- Attached file name and size are displayed in the message
- Text content is extracted and included in the prompt context
- Files exceeding a size threshold (e.g., 5 MB) trigger a warning
- User can remove an attached file before sending

#### CHAT-006: System Prompt Customization (Should Have)
**Description:** Users can set a custom system prompt per conversation or as a global default.

**Acceptance Criteria:**
- A system prompt field is accessible from conversation settings
- The system prompt is sent as the first message in every request
- Changes to the system prompt apply to subsequent messages only
- A global default can be set in app settings and overridden per conversation

#### CHAT-007: Thinking/Reasoning Display (Should Have)
**Description:** For models that expose reasoning steps, the app displays the thinking process.

**Acceptance Criteria:**
- Thinking tokens are displayed in a collapsible/expandable section
- Thinking content is visually distinct from the final response
- Token count for thinking is tracked separately where applicable
- Models without thinking support show no thinking UI

---

### 1.2 Model Management

#### MODEL-001: Model Discovery & Listing (Must Have)
**Description:** The app discovers and lists all available models across all configured providers.

**Acceptance Criteria:**
- All models from enabled providers appear in a unified list
- Models are grouped by provider type (Local, Self-Hosted, Cloud)
- Each model shows: name, provider, capability badges (vision, tools), and status
- Cloud models show cost-per-token indicator
- The list loads in under 500 ms from cache; background refresh updates it

#### MODEL-002: Model Selection (Must Have)
**Description:** Users can select which model to use for the current conversation.

**Acceptance Criteria:**
- User can switch models with 1–2 taps from the chat screen
- The currently active model is clearly indicated
- Switching models mid-conversation continues the conversation with the new model
- The app remembers the last-used model and selects it by default

#### MODEL-003: Model Information Display (Must Have)
**Description:** Users can view detailed metadata about any model.

**Acceptance Criteria:**
- Detail view shows: parameter count, family/series, capabilities, context window size
- For local/self-hosted models: size on disk, last downloaded date
- For cloud models: pricing (input/output per token), max context length
- Missing metadata is handled gracefully (shows "Unknown" rather than crashing)

#### MODEL-004: Model Download Management (Must Have)
**Description:** Users can browse, download, and delete models for self-hosted and local providers.

**Acceptance Criteria:**
- User can browse an available model catalog (e.g., Ollama library)
- Download progress is displayed (percentage and speed)
- Downloads can be cancelled
- Completed downloads appear in the model list immediately
- User can delete downloaded models to free storage

#### MODEL-005: Favorite Models (Should Have)
**Description:** Users can mark models as favorites for quick access.

**Acceptance Criteria:**
- A star/favorite toggle exists on each model
- Favorites appear in a dedicated section at the top of the model picker
- Favorites persist across app restarts

#### MODEL-006: Resource-Based Recommendations (Could Have)
**Description:** The app recommends models based on detected hardware capabilities.

**Acceptance Criteria:**
- The app detects available RAM/GPU on the host (for self-hosted/local)
- Models exceeding available resources show a warning
- A "Recommended" badge appears on models that fit the hardware
- Recommendations update if the provider's hardware changes

---

### 1.3 Provider System

#### PROV-001: Provider Abstraction (Must Have)
**Description:** All LLM interactions go through a provider-agnostic interface, enabling uniform behavior regardless of backend.

**Acceptance Criteria:**
- A single abstract interface is used for all providers
- Streaming responses work consistently across all provider types
- Error handling is standardized across providers
- Each provider reports its capabilities (vision, tool calling, max context)
- New providers can be added without modifying core chat logic

#### PROV-002: Local Model Provider (Must Have)
**Description:** Support for on-device model inference (e.g., via LiteRT or equivalent runtime).

**Acceptance Criteria:**
- On-device models run without any network connection
- Model download and management is available within the app
- Inference performance is acceptable for small models (< 4B parameters)
- Provider reports accurate capability information

#### PROV-003: Self-Hosted Provider — Ollama (Must Have)
**Description:** Support for connecting to user-hosted Ollama instances on the local network or internet.

**Acceptance Criteria:**
- User can configure host URL/IP and port
- Connection is validated before saving
- Both HTTP and HTTPS are supported
- Connection status indicator shows connected/disconnected in real time
- Multiple connection profiles can be saved
- Connection persists across app restarts

#### PROV-004: Self-Hosted Provider — LM Studio (Should Have)
**Description:** Support for connecting to LM Studio instances via its OpenAI-compatible API.

**Acceptance Criteria:**
- User can configure the LM Studio endpoint URL
- Models are discovered via the LM Studio API
- Chat and streaming work through the OpenAI-compatible interface
- Connection health is monitored

#### PROV-005: Cloud Provider — OpenAI (Must Have)
**Description:** Integration with the OpenAI API for GPT models.

**Acceptance Criteria:**
- Streaming responses work in real time
- Vision-capable models accept image inputs
- API key is stored securely and never logged
- Rate limit and quota errors are handled with clear user messages
- Token usage and estimated cost are tracked per message

#### PROV-006: Cloud Provider — Anthropic (Must Have)
**Description:** Integration with the Anthropic API for Claude models.

**Acceptance Criteria:**
- Streaming responses work in real time
- Vision-capable models accept image inputs
- System prompts are supported
- API key is stored securely and never logged
- Token usage and estimated cost are tracked per message

#### PROV-007: Cloud Provider — Google AI (Must Have)
**Description:** Integration with the Google AI (Gemini) API.

**Acceptance Criteria:**
- Streaming responses work in real time
- Vision-capable models accept image inputs
- API key is stored securely and never logged
- Token usage and estimated cost are tracked per message
- Google's unique message format is handled transparently

#### PROV-008: Provider Registry & Status (Must Have)
**Description:** A central registry tracks all providers, their configuration state, and health.

**Acceptance Criteria:**
- User can enable/disable individual providers
- Each provider shows a status badge: Ready, Unconfigured, Offline, Error, Disabled
- Provider status updates without requiring manual refresh
- Providers are sorted: enabled and healthy first

#### PROV-009: Connection Auto-Discovery (Could Have)
**Description:** The app scans the local network for self-hosted instances.

**Acceptance Criteria:**
- Common ports (e.g., 11434 for Ollama) are scanned on the local network
- Discovered instances are presented to the user for selection
- Scan times out after a reasonable period (e.g., 5 seconds)
- Manual entry remains always available

#### PROV-010: Automatic Provider Fallback (Must Have)
**Description:** When the active provider fails, the app offers or automatically tries fallback providers.

**Acceptance Criteria:**
- User can configure a fallback priority order
- User can choose between "Always ask" and "Auto-fallback" modes
- Fallback executes within 2 seconds of failure detection
- The fallback provider and reason are communicated to the user
- User can disable automatic fallbacks entirely

#### PROV-011: Provider Health Monitoring (Should Have)
**Description:** The app continuously monitors provider availability and performance.

**Acceptance Criteria:**
- Periodic health checks run in the background (configurable interval)
- Success rate, average latency, and rate-limit status are tracked
- Health status is reflected in the UI with color-coded indicators
- Health monitoring has minimal battery impact

---

### 1.4 Conversation Management

#### CONV-001: Create & List Conversations (Must Have)
**Description:** Users can create new conversations and browse existing ones.

**Acceptance Criteria:**
- A "New Conversation" action is always accessible
- Conversation list shows title, last message preview, timestamp, and model used
- Conversations are sorted by most recent activity
- Conversations persist across app restarts

#### CONV-002: Conversation Titles (Must Have)
**Description:** Conversations have descriptive titles, auto-generated or manually set.

**Acceptance Criteria:**
- Titles are auto-generated from the first message or AI summary
- User can manually edit any conversation title
- Auto-generated titles are concise and descriptive

#### CONV-003: Delete & Clear Conversations (Must Have)
**Description:** Users can delete entire conversations or clear messages within one.

**Acceptance Criteria:**
- Delete removes the conversation and all its messages with confirmation
- Clear removes messages but keeps the conversation entry
- Batch delete (select multiple) is supported

#### CONV-004: Conversation Search (Should Have)
**Description:** Users can search across all conversations by message content.

**Acceptance Criteria:**
- Full-text search across all message content returns results in under 500 ms
- Search results show the matching message with context and conversation title
- User can navigate directly to a search result within its conversation
- Filters available: date range, model used, provider

#### CONV-005: Conversation Export (Must Have)
**Description:** Users can export or move conversations in standard, portable formats.

**Acceptance Criteria:**
- Export formats include at minimum: native history file, JSON, Markdown, and plain text
- Exported files include metadata (timestamps, model, provider)
- Export of a single conversation and bulk export of all conversations are both supported
- Export integrates with the platform share sheet or save dialog
- Native history exports can be re-imported and restored by the app on another device

#### CONV-006: Conversation Archive (Should Have)
**Description:** Users can archive conversations to declutter the active list without deleting.

**Acceptance Criteria:**
- Archived conversations are hidden from the main list
- An "Archived" section or filter is available to view them
- Archived conversations can be restored to the active list

#### CONV-007: Platform Share & Import Integration (Must Have)
**Description:** Conversations, messages, and history files integrate with platform-native share and open/import flows on mobile and desktop.

**Acceptance Criteria:**
- User can share or save a full conversation or a single message
- Shared content includes text and images (if present)
- The mobile share sheet or desktop save/open surface is invoked as appropriate
- The app can receive shared/opened text, images, and native history files from other apps

#### CONV-008: File-Backed Chat History (Must Have)
**Description:** Every saved conversation, project chat, and agent chat persists as a plain-text, Markdown-compatible history file.

**Acceptance Criteria:**
- Saved chat history is stored as files, not as the authoritative database record
- The history format includes a session header, `Started:` line, per-message headings in the form `## [timestamp] sender`, and `---` separators between messages
- Markdown, code fences, and relative image references are preserved exactly when saving and reopening
- No sidecar metadata file is required beyond project `AGENT.md` and any referenced attachments/images

#### CONV-009: History Import, Parse & Restore (Must Have)
**Description:** The app can read, parse, and restore saved history files or synced project folders on another device.

**Acceptance Criteria:**
- User can open/import a native history file or a synced project folder created on another device
- The parser reconstructs message order, roles, timestamps, and attachment references without manual editing
- Restored histories render equivalently on mobile and desktop builds
- Invalid or partial history files surface actionable errors without crashing the app
- Restored histories are reindexed locally for search and browsing

---

### 1.5 Tool Calling & Extensions

#### TOOL-001: Tool Calling Architecture (Must Have)
**Description:** The app supports a framework for invoking tools (functions) during a conversation when the model requests them.

**Acceptance Criteria:**
- Models that support tool/function calling can declare and invoke tools
- Tool definitions (name, description, parameters) are passed to the model
- Tool invocation results are fed back into the conversation
- User can enable/disable tool calling globally and per conversation
- Tool execution is sandboxed and cannot perform destructive actions without confirmation

#### TOOL-002: Web Search Tool (Must Have)
**Description:** A built-in web search tool allows models to retrieve up-to-date information.

**Acceptance Criteria:**
- Web search results are displayed as structured cards (title, snippet, URL)
- Search results are cached to avoid redundant queries
- Search latency is under 3 seconds (p95)
- User can see which searches the model performed
- Web search can be disabled by the user

#### TOOL-003: MCP Integration (Should Have)
**Description:** The app connects to remote Model Context Protocol (MCP) servers to extend tool capabilities.

**Acceptance Criteria:**
- User can add MCP server endpoints in settings
- The app discovers and lists available tools from each MCP server
- Tool invocations are routed to the appropriate MCP server
- Connection status is monitored and failures are handled gracefully

#### TOOL-004: Tool Result Rendering (Must Have)
**Description:** Tool invocation results are rendered clearly within the chat.

**Acceptance Criteria:**
- Each tool result is displayed in a distinct card/block within the conversation
- Error results show the error message and a retry option
- User can collapse/expand tool result details
- Tool results do not break the conversation flow

---

### 1.6 Model Comparison

#### COMP-001: Side-by-Side Comparison (Should Have)
**Description:** Users can send the same prompt to multiple models and compare responses side by side.

**Acceptance Criteria:**
- User can select 2+ models for comparison
- The same prompt is sent to all selected models in parallel
- Responses are displayed side by side (or in tabs on small screens)
- Response time and token count are shown per model

#### COMP-002: Comparison Metrics (Should Have)
**Description:** The app shows performance metrics for each model in a comparison.

**Acceptance Criteria:**
- Metrics include: time to first token, total response time, token count, and cost (if cloud)
- Metrics are displayed alongside or below each response
- User can save comparison results for future reference

---

### 1.7 Cost & Usage Tracking

#### COST-001: Token Usage Tracking (Must Have)
**Description:** The app tracks token usage (input and output) for all cloud API requests.

**Acceptance Criteria:**
- Per-message token counts (input, output, total) are recorded
- Estimated cost in USD is calculated using embedded pricing data
- Usage is stored locally and queryable by conversation, model, provider, and date
- A usage summary is accessible from settings or a dedicated screen

#### COST-002: Per-Message Cost Display (Should Have)
**Description:** Each cloud API message shows its token count and estimated cost.

**Acceptance Criteria:**
- A compact cost indicator (e.g., "125 tokens · $0.0006") appears on each cloud message
- Tapping the indicator expands to show input/output breakdown
- Local and self-hosted messages show no cost indicator (or "$0.00")
- The display does not clutter the chat UI

#### COST-003: Cost Limits & Warnings (Should Have)
**Description:** Users can set spending limits and receive warnings when approaching them.

**Acceptance Criteria:**
- User can set daily and/or monthly cost limits per provider
- A warning is displayed when usage reaches a configurable threshold (e.g., 80%)
- A hard limit option stops cloud requests when the limit is reached
- The warning suggests switching to a free alternative (local/self-hosted)

#### COST-004: Usage Data Export (Should Have)
**Description:** Users can export their token usage and cost data.

**Acceptance Criteria:**
- Export formats include CSV and JSON at minimum
- Export includes date, provider, model, token counts, and cost per message
- Date range and provider filters are supported

---

### 1.8 Text-to-Speech

#### TTS-001: Read Responses Aloud (Should Have)
**Description:** Users can have AI responses read aloud using platform TTS.

**Acceptance Criteria:**
- A play button appears on AI messages to trigger TTS
- Playback can be paused and resumed
- Speed and voice can be configured in settings
- TTS works offline using system voices
- Only AI response text is read (not tool results or metadata)

---

### 1.9 Projects & Organization

#### PROJ-001: Projects / Spaces (Should Have)
**Description:** Users can organize conversations into named, folder-backed projects or spaces.

**Acceptance Criteria:**
- User can create, rename, and delete project folders
- Conversations can be moved into or out of a project folder
- The conversation list can be filtered by project
- A default "General" project exists for unorganized conversations

#### PROJ-002: Project Configuration via `AGENT.md` (Should Have)
**Description:** Each project folder can use `AGENT.md` to define local chat defaults and agent-like behavior.

**Acceptance Criteria:**
- User can create or import a project folder containing `AGENT.md`
- `AGENT.md` can define project name, default system prompt, preferred model, and other local chat defaults
- Agent chats and project chats use the same history file format and parser
- Moving or syncing a project folder preserves its configuration and chat history together

---

### 1.10 Settings & Configuration

#### SETT-001: General App Settings (Must Have)
**Description:** Users can configure global app behavior.

**Acceptance Criteria:**
- Available settings include: theme (light/dark/system), default model, message font size, storage/export controls
- An "About" screen shows app version, licenses, and links
- A "Clear All Data" option exists with confirmation dialog
- Settings persist across restarts and take effect immediately

#### SETT-002: Provider Settings (Must Have)
**Description:** A dedicated screen for managing provider configurations.

**Acceptance Criteria:**
- Each provider has its own settings page (API key, endpoint, enable/disable)
- Cloud provider pages show: usage summary, cost limit configuration, connection test
- Self-hosted provider pages show: host/port, connection test, saved profiles
- API key input is obscured and stored securely

#### SETT-003: Model Parameter Configuration (Should Have)
**Description:** Users can adjust inference parameters for any model.

**Acceptance Criteria:**
- Configurable parameters include at minimum: temperature, top-K, top-P, max tokens
- Parameter presets are available (e.g., Creative, Balanced, Precise)
- Parameters can be set globally or per conversation
- A "Reset to Defaults" option exists

#### SETT-004: Onboarding / First-Run Setup (Should Have)
**Description:** New users are guided through initial setup.

**Acceptance Criteria:**
- A setup wizard explains provider types (local, self-hosted, cloud)
- The wizard guides API key entry for cloud providers
- The user can skip cloud setup entirely
- Starter models are suggested based on configured providers

#### SETT-005: Chat History Save Mode (Must Have)
**Description:** Users can choose when chats become saved plain-text history files.

**Acceptance Criteria:**
- Save modes include at minimum: Automatically, Ask before saving, and Only when I tap Save
- Automatic mode saves as the user chats; Ask/Manual modes keep temporary chats in cache until the user saves or discards them
- Unsaved chats are clearly marked and excluded from export or sync until saved
- Changing the save mode affects new chats only unless the user explicitly saves the current chat

---

## 2. Non-Functional Requirements

### 2.1 Performance

#### PERF-001: App Responsiveness (Must Have)
**Targets:**
- App cold start: < 2 seconds
- Screen transitions: < 300 ms
- Message send (before AI response begins): < 200 ms
- Scroll performance: 60 FPS consistently
- Search results: < 500 ms
- Model picker load (from cache): < 500 ms

**Acceptance Criteria:**
- All targets met on a mid-range Android device (e.g., Pixel 6a equivalent)
- No user-perceptible jank during normal operation

#### PERF-002: Streaming Performance (Must Have)
**Targets:**
- Cloud API time to first token: < 2 seconds (p95)
- Streaming render: no visible stutter or lag
- UI remains fully interactive during streaming

**Acceptance Criteria:**
- Measured on a stable Wi-Fi connection for cloud; local network for self-hosted

#### PERF-003: Resource Efficiency (Must Have)
**Targets:**
- Memory usage: < 200 MB average, < 300 MB during model comparison
- Battery drain: < 5% per hour of active use
- App install size: < 100 MB
- Local cache: < 500 MB

**Acceptance Criteria:**
- Measured using platform profiling tools under typical usage

---

### 2.2 Privacy & Security

#### SEC-001: Data Privacy (Must Have)
**Requirements:**
- No telemetry or analytics without explicit opt-in consent
- No user data is sent to the app developer's servers — ever
- Cloud API providers receive only the data necessary for inference
- Conversation content is never included in crash reports or logs
- Saved chat histories are stored locally as human-readable plain-text files and are never uploaded by the app

**Acceptance Criteria:**
- A network traffic audit shows no unexpected outbound requests
- Crash reports contain no message content or API keys
- Saved history files can be opened outside the app and still match in-app rendering

#### SEC-002: Credential Security (Must Have)
**Requirements:**
- API keys are stored using platform secure storage
- API keys are never logged, displayed in full, or included in exports
- HTTPS is enforced for all cloud API communication
- HTTP connections to self-hosted instances trigger a visible warning

**Acceptance Criteria:**
- Security review confirms no plaintext credentials in storage, logs, or memory dumps
- API key fields in the UI are obscured by default

#### SEC-003: Secure Communication (Should Have)
**Requirements:**
- Optional certificate pinning for cloud API connections
- Optional authentication support for self-hosted instances (e.g., Ollama behind a reverse proxy)

**Acceptance Criteria:**
- Certificate pinning can be enabled/disabled in settings
- Authentication credentials are stored securely alongside API keys

---

### 2.3 Reliability

#### REL-001: Stability (Must Have)
**Targets:**
- Crash-free session rate: > 99.5%
- ANR (App Not Responding) rate: < 0.1%

**Acceptance Criteria:**
- No single feature causes a reproducible crash
- App recovers gracefully from provider connection failures

#### REL-002: Data Integrity (Must Have)
**Requirements:**
- No saved conversation data is lost on app crash or force-stop
- History file writes use atomic or append-safe operations
- SQLite cache/index can be rebuilt from saved history files and `AGENT.md` project configuration
- Corrupted data is detected and handled without crashing

**Acceptance Criteria:**
- Killing the app mid-save does not corrupt an already saved history file
- A recovery and reindex mechanism exists for file-backed history and cache corruption

#### REL-003: Offline Resilience (Must Have)
**Requirements:**
- Local models function fully without any network connection
- Cloud and self-hosted messages are queued when offline
- Queued messages auto-send when connectivity is restored
- Offline state is clearly communicated to the user

**Acceptance Criteria:**
- Airplane mode does not crash the app or lose data
- Queued messages send in order upon reconnection

#### REL-004: Error Handling (Must Have)
**Requirements:**
- All provider errors (timeout, rate limit, auth failure, network) are caught
- Error messages are user-friendly and actionable (not raw stack traces)
- Retry with exponential backoff is used for transient failures
- The app never crashes due to a provider error

**Acceptance Criteria:**
- Each documented error scenario has a corresponding user-facing message
- Retry logic is verified for each provider type

---

### 2.4 Accessibility

#### ACC-001: Screen Reader Support (Should Have)
**Acceptance Criteria:**
- All interactive elements have semantic labels for TalkBack
- Navigation order is logical and consistent

#### ACC-002: Visual Accessibility (Should Have)
**Acceptance Criteria:**
- Minimum touch target size: 48 dp
- Color contrast meets WCAG AA (4.5:1 for text)
- Text scales with system font size settings

---

### 2.5 Offline Capability

#### OFF-001: Offline-First Local Models (Must Have)
**Acceptance Criteria:**
- Downloaded local models work with zero network connectivity
- Model download requires network but inference does not
- All saved conversation history is available offline from local history files

#### OFF-002: Graceful Degradation for Cloud/Self-Hosted (Must Have)
**Acceptance Criteria:**
- Loss of connectivity is detected within 500 ms
- The app suggests switching to a local model when cloud/self-hosted is unavailable
- Pending messages are queued and visible to the user

---

### 2.6 Compatibility

#### COMPAT-001: Mobile & Desktop Platform Support (Must Have)
**Target:** Shared Flutter codebase for supported mobile and desktop builds

**Acceptance Criteria:**
- App installs and runs on supported Android mobile builds and supported desktop builds
- The same saved history file opens correctly on both mobile and desktop builds
- Platform-native share, file open/save, and secure-storage integrations are used where available

#### COMPAT-002: Device & Screen Support (Must Have)
**Target:** Phones, tablets, laptops, and desktop windows in portrait, landscape, and resizable layouts

**Acceptance Criteria:**
- Responsive layouts adapt to screen size and orientation
- No content is cut off or inaccessible on supported screen sizes or desktop window sizes

---

## 3. Won't Have (For Now)

| Item | Rationale |
|---|---|
| **iOS support** | Mobile scope currently prioritizes Android while desktop support ships first |
| **Image generation** | Niche use case; dependent on model support that is still evolving |
| **Voice / speech input (STT)** | Adds significant complexity; TTS (output) is prioritized first |
| **Multi-user / team features** | This is a personal/individual tool; collaboration is out of scope |
| **Private Chat Hub-hosted cloud sync** | Portable file-based sync with the user's own tools is preferred over a vendor service |
| **API gateway integration (LiteLLM, OpenRouter)** | Can be supported later via custom endpoint URL on existing providers |
| **Internationalization (i18n)** | English-first; localization adds maintenance burden before product-market fit |
| **Additional cloud providers (Mistral, Cohere, Groq)** | Extensible architecture supports future addition; focus on top 3 first |
| **Advanced cost optimization AI** | Requires usage data history; revisit after cost tracking is mature |
| **Scheduled / recurring prompts** | Power-user feature; revisit after core workflows are stable |

---

## Appendix: Requirement Index

**Must Have (43):** CHAT-001, CHAT-002, CHAT-004, CHAT-005, MODEL-001–004, PROV-001–003, PROV-005–008, PROV-010, CONV-001–003, CONV-005, CONV-007–009, TOOL-001, TOOL-002, TOOL-004, COST-001, SETT-001, SETT-002, SETT-005, PERF-001–003, SEC-001, SEC-002, REL-001–004, OFF-001, OFF-002, COMPAT-001, COMPAT-002

**Should Have (22):** CHAT-003, CHAT-006, CHAT-007, MODEL-005, PROV-004, PROV-011, CONV-004, CONV-006, TOOL-003, COMP-001, COMP-002, COST-002–004, TTS-001, PROJ-001, PROJ-002, SETT-003, SETT-004, SEC-003, ACC-001, ACC-002

**Could Have (2):** MODEL-006, PROV-009
