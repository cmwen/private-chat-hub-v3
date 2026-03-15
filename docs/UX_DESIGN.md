# UX Design: Private Chat Hub

**Version:** 3.1 (Consolidated)  
**Design Language:** Material Design 3 · **Platform:** Adaptive mobile + desktop · **Theme:** Dark mode primary, light supported

---

## 1. Design Principles

**Familiar Yet Powerful.** Mirror ChatGPT/Claude chat patterns. Multi-provider support and tool capabilities are progressive enhancements, not obstacles to sending a first message.

**Privacy-First Visual Language.** Lock icons in branding, "Local" badges on connection status, "Your data never leaves this device" messaging. Cloud providers accessed via OpenCode are clearly labeled as external with cost indicators.

**Dark Mode First.** All layouts designed for dark theme. Light mode is a token inversion, not a separate design. OLED-friendly surfaces save battery during long sessions.

**Progressive Disclosure.** Default UI is a chat screen and model picker. Advanced features — tool calling, comparison mode, server management, TTS — surface through settings, long-press menus, and contextual controls. Power users find depth; newcomers see simplicity.

**Accessibility as Baseline.** 48 dp minimum touch targets, WCAG AA contrast (≥ 4.5:1 text, ≥ 3:1 controls), full TalkBack support with semantic labels, respect for system font scaling up to 200%.

---

## 2. Information Architecture

```
App
├── Chat Screen (home)
│   ├── Message list (streaming, markdown, code blocks)
│   ├── Message input bar (text, attachments, tool indicators)
│   ├── Model chip in app bar (tap to open picker)
│   └── Tool toggle FAB (bottom-right)
├── Navigation Drawer / Sidebar
│   ├── Conversations (grouped by date)
│   ├── New Chat action
│   ├── Running Tasks (badge count, only when active)
│   └── Settings link
├── Model Picker (bottom sheet from app bar chip)
│   ├── Unified model list across all providers
│   ├── Source filter chips
│   └── Compare mode entry
├── Settings
│   ├── Providers (Remote Servers, OpenCode, On-Device)
│   ├── Tools & Capabilities (Web Search, MCP Servers)
│   ├── Text-to-Speech
│   ├── Appearance · Chat · Data & Privacy · About
│   └── Chat History (save mode, export/move, rebuild index)
├── Projects (folder-backed conversation grouping)
└── Search (full-text across conversations)
```

Maximum navigation depth: 3 levels. Most actions reachable in 2 taps from chat.

---

## 3. Key Screens

### 3.1 Chat Screen (Home)

The chat screen IS the home screen. Conversations live in the navigation drawer, not a separate list view.

**App Bar:**
```
┌───────────────────────────────────────────┐
│  ☰   🤖 Qwen 2.5 7B ▾  [🛠][👁]   ⚙️  │
│       Ollama · Home Server · 🟢          │
└───────────────────────────────────────────┘
```
- Hamburger icon opens the navigation drawer
- Model chip: tappable, opens the Model Picker. Shows model name, provider badge, server name, connection status dot
- Capability badges (tools, vision, code) — tappable for detail sheet
- Connection indicators: 🟢 Connected, 🟡 Connecting, 🔴 Disconnected
- Settings gear on right

**Message Display:**
- User messages: right-aligned, filled with primary color
- AI messages: left-aligned, surface color with outline
- Markdown rendering with syntax-highlighted code blocks
- Code blocks: language label + copy button, horizontal scroll for long lines
- Streaming: blinking cursor during generation, "Stop" replaces Send

**Thinking Models:** For reasoning models, a collapsible "Thinking process" section appears above the final answer. Collapsed by default, shows token summary ("320 response · 2,450 thinking tokens"). Tap to expand and read the chain-of-thought.

**Input Bar:**
```
┌───────────────────────────────────────────┐
│  [📎]  Type a message...         [➤ Send] │
│  (attachment preview chips appear here)    │
└───────────────────────────────────────────┘
```
- Attachment button opens file/image picker
- Previews show thumbnails with ✕ to remove
- Send disabled when empty; becomes Stop (■) during generation

**Vision Auto-Detection:** If user attaches an image to a non-vision model, inline dialog: "This model doesn't support images. Switch to [vision model]?" with Cancel and Switch buttons.

**Tool Toggle FAB:** Floating action button, bottom-right, 70 dp above input. Single tap toggles tool calling. States: enabled (filled icon), disabled (outlined), unsupported (slashed icon). Tooltip: "Tools ON (tap to disable)" or "Tools OFF (tap to enable)."

### 3.2 Navigation Drawer

- Header: app name with lock icon
- "New Chat" prominent action at top
- Conversation list grouped by date: Today, Yesterday, Previous 7 Days, Older
- Each row: auto-generated title (from first message, ~40 chars), model badge, timestamp
- Long-press a conversation for: rename, pin, move to project, archive, delete
- Running Tasks section (visible only when active tasks exist, shows count badge)
- Settings entry at bottom
- Empty state: "No conversations yet. Start chatting!"

### 3.3 Model Picker (Unified)

Opens as a bottom sheet when the user taps the model chip. This is the ONE unified model picker — no separate screens per provider.

**Layout:**
```
┌───────────────────────────────────────────┐
│  Choose a Model                      ✕    │
├───────────────────────────────────────────┤
│  [All] [Remote] [On-Device] [Cloud]       │
├───────────────────────────────────────────┤
│  ★ RECOMMENDED                            │
│                                           │
│  🌐 Qwen 2.5 7B                  Ollama  │
│     Home Server · 8B · 💬 🛠 👁          │
│                                           │
│  📱 Gemma 2B                    On-Device │
│     557 MB · Works offline · 💬          │
│                                           │
│  REMOTE MODELS                            │
│                                           │
│  🌐 Llama 3.2 8B                 Ollama  │
│     Home Server · 4.1 GB · 💬 💻        │
│                                           │
│  🌐 DeepSeek Coder            LM Studio  │
│     Lab Server · 6.7B · 💻 🛠           │
│                                           │
│  CLOUD MODELS (via OpenCode)              │
│                                           │
│  ☁️ Claude 3.5 Sonnet     ~$0.003/msg    │
│     Anthropic · 💬 🛠 👁 💻             │
│                                           │
│  ☁️ GPT-4o                 ~$0.005/msg    │
│     OpenAI · 💬 🛠 👁 💻               │
│                                           │
│  ON-DEVICE MODELS                         │
│                                           │
│  📱 Gemma 2B              Downloaded 557M │
│     💬                                    │
│  📱 Phi-3 Mini               ⬇ 2.9 GB    │
│     Available to download                 │
├───────────────────────────────────────────┤
│  [⚖️ Compare Models]                      │
└───────────────────────────────────────────┘
```

**Model Card Anatomy:**
- Source icon: 🌐 (remote self-hosted), ☁️ (cloud via OpenCode), 📱 (on-device)
- Model name (primary text, bold)
- Provider badge: "Ollama", "LM Studio", or cloud provider name
- Server name or host as secondary context
- Size (GB) or parameter count
- Capability icons: 💬 Chat, 🛠 Tools, 👁 Vision, 💻 Code
- Cost estimate for cloud models (e.g., "~$0.003/msg")
- Download button for available but not-yet-downloaded on-device models

**Source Filter Chips:** All | Remote | On-Device | Cloud. "All" is default. When "Cloud" is active, a secondary row appears: All Providers | Claude | GPT | Gemini | etc.

**Recommended Section:** Curated picks based on device capabilities and connected servers. Prioritizes models that are ready to use. Hidden when no recommendations apply.

**Compare Mode:** Tapping "Compare Models" enables multi-select (2–4 models). After selection, chat splits: side-by-side for 2 models, tabs for 3–4. Both/all models receive the same prompt. Metrics panel (pull-down) shows response time, token count, tokens/sec. "Diff" toggle highlights unique vs. common content. "End Comparison" returns to single mode.

**Empty States:**
- No remote servers: "Add a server in Settings to see remote models."
- Server unreachable: "{Name} is not responding. [Retry] [Settings]"
- No OpenCode: "Connect OpenCode in Settings to access cloud models."
- No models at all: "Set up a provider in Settings to get started."

### 3.4 Settings

Scrollable screen with grouped sections.

#### Providers — Remote Servers (Ollama & LM Studio)

Shared saved-server list pattern with subsections per provider type.

```
REMOTE SERVERS
Connect to Ollama or LM Studio to run models on your own server.

  Ollama
  ┌───────────────────────────────────────┐
  │  🟢 Home Server            [Default]  │
  │     192.168.1.20:11434                │
  │     Last connected: 2m ago       [⋮]  │
  ├───────────────────────────────────────┤
  │  🔴 Lab Server                        │
  │     10.0.0.5:11434 · Unreachable [⋮]  │
  └───────────────────────────────────────┘

  LM Studio
  ┌───────────────────────────────────────┐
  │  🟢 Workstation            [Default]  │
  │     192.168.1.30:1234                 │
  │     Last connected: 5m ago       [⋮]  │
  └───────────────────────────────────────┘
  [+ Add Server]
```

Overflow menu (⋮): Test Connection, Edit, Set as Default, Delete.

**Status chips:** Default (blue), Reachable (green), Unreachable (red), Needs Attention (amber). Default and health are independent — a default server can be offline.

**Default rules:** First server auto-defaults. Changing default demotes previous (snackbar). Deleting default promotes next.

**Add/Edit Dialog:** Server Type (Ollama | LM Studio segmented button), Name, Host, Port, HTTPS toggle, [Test Connection], [Save] / [Save & Set as Default]. Auto-discovery (Ollama only): optional "Scan Network" via mDNS.

#### Providers — OpenCode (Cloud Gateway)

Separate section with distinct styling (gateway, not self-hosted runtime). Same list pattern but with API Key field. Helper: "Access cloud models through a single gateway." Same add/edit flow minus Server Type selector.

#### Providers — On-Device Models

Download status, storage usage, link to download/remove screen.

#### Tools & Capabilities

- **Web Search:** Enable toggle, API key, usage quota display (e.g., "85/100 this month")
- **MCP Servers:** List with status, add/remove. Tap server to see tool library. Tool library is searchable; per-tool permissions: auto-allow, require confirmation, deny.

#### Text-to-Speech

Enable toggle, voice selector, speed slider (0.5x–2.0x), auto-play new responses toggle, background playback toggle.

#### Appearance

Theme (System/Dark/Light), dynamic color (Material You) toggle, font size override.

#### Chat

Parameter presets (Creative/Balanced/Precise). Advanced toggle reveals raw sliders: temperature, top-p, top-k. Context length, default system prompt.

#### Data & Privacy

**Chat History**
- **When to save chat history:** Automatically (default), Ask before saving, Only when I tap Save
- **Storage note:** "Saved chats are stored as plain-text files on this device."
- **Back up or move chats:** Export or open the project/history folder with platform-native save/share flows
- **Rebuild search index:** Recreate the local SQLite cache/index from saved history files

**Data tools**
- Export conversations (native history / JSON / Markdown / plain text)
- Storage usage split by Saved chat history and Temporary cache
- Clear conversations (confirmation)
- Clear cache
- Monthly cloud cost summary when applicable

### 3.5 Projects

Group related conversations in folder-backed projects. Project list: name, color, count. "All Conversations" always at top. Assign via drawer long-press → "Move to Project." Each project folder may contain `AGENT.md` to define local defaults for new chats.

---

## 4. Core Interactions

### 4.1 Sending Messages

Type → Send → user message appears instantly → AI response streams with cursor → cursor disappears on completion → message actions available.

**With Attachments:** Tap 📎 → pick files → preview chips appear → optionally add text → Send. Vision auto-detect fires before send if model doesn't support images.

**Offline:** Messages queue automatically. Banner: "Offline · 2 messages queued." On reconnect, queue sends FIFO. Per-message status: ✓ sent, ⏳ queued, ⌛ sending, ⚠️ failed (with [Retry]).

### 4.2 Model Selection & Switching

Tap app bar chip → picker opens → tap model → sheet closes, app bar updates. Switching mid-conversation is allowed; a divider appears: "Switched to [Model]." Prior messages keep original attribution.

**On server change:** App revalidates model availability. If selected model missing, auto-selects first available + snackbar.

### 4.3 Tool Calling Indicators

Inline during chat:
- **In-progress:** `🔍 Web Search · "query" ⏳ Searching...`
- **Complete:** `🔍 Web Search · "query" ✓ 5 results (1.2s)` with expandable result cards
- **Error:** `🔍 Web Search ❌ Timeout [↻ Retry] [Continue without] [Settings]`
- **MCP tools:** Same pattern prefixed with server name: `🔌 Code Tools: Search Codebase`

### 4.4 Cost Display

Cloud models show cost at three levels. Users on local/self-hosted models never see cost UI.

- **Per-message:** Below AI response: "☁️ Claude 3.5 Sonnet · 1,240 tokens · ~$0.004". Tap to expand breakdown. Muted secondary text style.
- **Conversation:** Info area: "This conversation: ~$0.12 (42 messages)". Only visible when cloud messages exist.
- **Monthly (Settings → Data & Privacy):** "Cloud usage this month: ~$3.45" with per-provider breakdown (informational only, app doesn't handle billing).

### 4.5 TTS Controls

Appear below AI messages when TTS is enabled in settings.

- **Ready:** `[▶ Listen] [1.0x ▾]`
- **Playing:** `[⏸ Pause] ████░░ 65% [1.0x ▾] [■ Stop]`
- Speed: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x
- Progress bar is tappable/seekable
- Background playback via media notification when enabled in settings

### 4.6 Message Actions (Long-Press)

**User messages:** Copy, Edit (re-send modified), Delete.
**AI messages:** Copy, Share/Save (platform-native share or save; native history/plain/markdown/HTML), Regenerate, Listen (if TTS enabled), Delete.
**Code blocks:** Copy icon on the block copies just that block; long-pressing the whole message opens full context menu.

---

## 5. Provider Management

### 5.1 Adding a Remote Server

Settings → Providers → Remote Servers → "+ Add Server." Select type (Ollama/LM Studio), fill in name/host/port, test connection, save. On success, server appears in list with Reachable chip.

### 5.2 Adding an OpenCode Server

Same flow with API Key field instead of Server Type. Emphasizes gateway concept.

### 5.3 API Key Security

Keys stored via platform secure storage. Masked fields with reveal toggle. Never exported or synced.

### 5.4 Provider Health

Background health checks (default 60s interval). Status reflected on server cards in real time. Health checks are independent of default status — a default server that goes offline shows 🔴 while retaining the Default badge.

---

## 6. Navigation & Flows

### 6.1 Primary Navigation

**Adaptive navigation** uses a drawer on mobile and a persistent sidebar or split-pane layout on larger desktop/tablet windows. This keeps conversation access fast without sacrificing chat space.

**Quick actions without opening drawer:** Model chip → picker (1 tap). Tool FAB → toggle (1 tap). Settings gear → settings (1 tap).

### 6.2 Conversation Lifecycle

New Chat → save behavior follows the Chat History setting → saved conversations appear in drawer/sidebar → auto-titled from first message → assignable to project. In Ask before saving or manual mode, leaving the chat prompts Save / Discard / Cancel or shows an explicit Save action. Long-press for rename, archive, delete (confirmation dialog for destructive action).

### 6.3 First-Time Setup

Three screens: **Welcome** ("Your AI, Your Data, Your Control") → **Connect** (three cards: Remote Server, On-Device, Cloud via OpenCode — each starts relevant setup) → **Success** ("Connected! Found N models. [Start Chatting]"). Skip lands on chat with banner: "No provider configured. [Set up now]"

### 6.4 Error States

All errors are inline — never modal dialogs.

| Situation | Display |
|-----------|---------|
| Connection lost | Top banner: "⚠️ Connection lost. Retrying... [Retry Now]" — chat scrollable, input disabled |
| Server not configured | "Ollama is not set up. Add a server in Settings. [Open Settings]" |
| Server unreachable | "Server '{name}' unavailable. [Retry] [Switch Model] [Settings]" |
| Model missing on server | "'{model}' not available on '{server}'. [Choose Model] [Switch Server]" |
| Generation error | Partial response + "⚠️ Generation stopped. [Retry] [Delete]" |
| Server deleted (stale ref) | "The server previously used is no longer saved. [Choose Server] [Add Server]" |

---

## 7. Responsive Design & Themes

**Layout:** Single-column portrait on phones, expanded panes on tablets and desktop windows, and responsive resizing for landscape and desktop use. Comparison mode: horizontal split (2 models) or tabs (3–4).

**Color System:** Material 3 tokens with dynamic color where supported. Primary (buttons, user bubbles), Surface (backgrounds, AI bubbles), Error (failures), custom green/amber for connection status. Color reserved for semantic meaning — no decorative colors.

**Typography:** System default (Roboto) + monospace for code. Base spacing: 4 dp. Respects system font scaling.

**Motion:** Message fade-in + slide, streaming cursor, tool results slide up. Respects "Remove animations" accessibility setting. **Haptics:** Light tap on send/tool invoke, medium on results/completion, warning pattern on errors.

---

## 8. Accessibility

**Touch Targets:** All interactive elements ≥ 48 × 48 dp (buttons, model cards, tool links, conversation rows, context menu items).

**Screen Reader (TalkBack):** Every element labeled. Examples: "Selected model: Qwen 2.5 7B on Home Server. Connected. Tap to change." / "Tool calling enabled. Tap to disable." / "Estimated cost: 0.4 cents. 1,240 tokens."

**Color Independence:** No information conveyed by color alone. Connection: dot + text label. Tool status: color + icon. Message status: color + icon. Cost: text with ☁️ prefix.

**Font Scaling:** Layouts tested at 0.85x through 2.0x. Content reflows; no clipping. Long names truncate with ellipsis. Code blocks scroll horizontally.

**Contrast:** ≥ 4.5:1 body text, ≥ 3:1 controls. Verified in both dark and light themes.

---

## Appendix: Design Decision Reference

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation | Drawer, not bottom tabs | More chat space, matches ChatGPT/Claude pattern |
| Model access | App bar chip | 2-tap workflow for frequent switching |
| Message actions | Long-press, not swipe | Works across touch and pointer input without conflicting with navigation gestures |
| Error display | Inline, not modal | Non-blocking, contextual, actionable |
| Onboarding | 3 screens max | Users want to chat, not read tutorials |
| Provider grouping | Remote (Ollama + LM Studio) vs Cloud (OpenCode) | Self-hosted vs gateway mental model |
| Theme | Dark mode primary | Privacy users prefer dark, OLED savings |
| Tool toggle | FAB + settings | Quick access without leaving chat |
| Cost display | Per-msg + conversation + monthly | Informational, never blocks usage |
| TTS placement | Controls on message + global settings | Contextual play, app-wide preferences |
| Server management | Multi-server list per provider | Uniform add/edit/delete/default pattern |
| Model picker | One unified bottom sheet | No separate screens per provider, filter chips instead |
| Chat history save mode | Automatic by default, overridable in Settings | Keeps the default simple while allowing privacy-conscious manual control |
