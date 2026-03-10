# UX Component Specification: Private Chat Hub

**Design System:** Material Design 3 · **Platform:** Android (mobile-first) · **Theme:** Dark mode primary, light supported

---

## 1. Design Principles

- **Familiar Yet Powerful.** Mirror ChatGPT/Claude patterns. Multi-provider and tool features surface progressively.
- **Privacy-First Visual Language.** Local badges, lock icons, explicit cloud labels with cost indicators.
- **Dark Mode First.** OLED-friendly surfaces. Light mode is a token inversion.
- **Accessibility Baseline.** ≥48 dp touch targets, WCAG AA contrast, full TalkBack support, font scaling to 200%.

---

## 2. Chat Components

### 2.1 MessageBubble

**Purpose:** Single message — user input, AI response, or streaming output.

```
User (right-aligned, primary fill):       AI (left-aligned, surface + outline):
┌───────────────────────┐                 ┌────────────────────────────────┐
│  How do I sort a list?│                 │  🤖 Qwen 2.5 7B · Ollama      │
│             12:04 PM  │                 │  You can use `list.sort()`:    │
└───────────────────────┘                 │  ┌─ python ──── [📋]─┐        │
                                          │  │  my_list.sort()    │        │
Streaming (with cursor):                  │  └────────────────────┘        │
┌────────────────────────────────┐        │  320 resp · 2,450 think  [▾]  │
│  You can use the built-in▌     │        └────────────────────────────────┘
│  ████████░░░░  generating...   │
└────────────────────────────────┘
```

**States:** Sent (✓), Queued (⏳, offline), Streaming (blinking cursor, no actions), Complete (markdown rendered, actions available), Error (partial + "⚠️ Generation stopped. [Retry] [Delete]"), Thinking (collapsible chain-of-thought, collapsed by default with token summary).

**Interactions:** Long-press → MessageActions. Code blocks have per-block copy + horizontal scroll. Thinking section tap to expand/collapse.

**A11y:** "AI response from Qwen 2.5 7B. [content]. 12:04 PM." Code: "Code block, Python." Thinking: "Collapsed. 2,450 thinking tokens. Tap to expand."

### 2.2 MessageActions

**Purpose:** Long-press context menu on a message.

- **User messages:** Copy, Edit & Resend, Delete.
- **AI messages:** Copy, Share, Regenerate, Listen (if TTS enabled), Delete.

Delete requires confirmation. Each item ≥48 dp. Focus order matches visual order.

### 2.3 ChatInput

**Purpose:** Bottom-anchored text entry with attachment support.

```
┌───────────────────────────────────────────┐
│  [📎]  Type a message...         [➤ Send] │
│  (attachment preview chips with ✕ here)   │
└───────────────────────────────────────────┘
```

**States:** Empty (send disabled), Has text (send active), Has attachments (preview chips above field), Generating (Send → Stop ■), Offline (messages queue, subtle indicator).

**Interactions:** 📎 opens file/image picker. Send dispatches + clears. Stop cancels generation. Vision auto-detect: inline dialog "Switch to [vision model]?" if image attached to non-vision model.

**A11y:** "Message input field." Attachment: "Attach file." Send: "Send message" / "Stop generation."

### 2.4 StreamingIndicator

**Purpose:** Feedback that the AI model is generating. Blinking cursor (500ms) inline within AI bubble; token count increments live. Cursor disappears on completion. TalkBack: "Generating response" on start, "Response complete" on finish — does not read tokens incrementally.

---

## 3. Model & Provider Components

### 3.1 ModelPicker

**Purpose:** Unified bottom sheet for model selection across ALL providers. The single point of model selection.

```
┌───────────────────────────────────────────┐
│  Choose a Model                      ✕    │
├───────────────────────────────────────────┤
│  [All] [Remote] [On-Device] [Cloud]       │
├───────────────────────────────────────────┤
│  ★ RECOMMENDED                            │
│  🌐 Qwen 2.5 7B              Ollama      │
│     Home Server · 8B · 💬 🛠 👁          │
│                                           │
│  REMOTE MODELS                            │
│  🌐 Llama 3.2 8B              Ollama     │
│     Home Server · 4.1 GB · 💬 💻        │
│                                           │
│  CLOUD MODELS (via OpenCode)              │
│  ☁️ Claude 3.5 Sonnet     ~$0.003/msg    │
│     Anthropic · 💬 🛠 👁 💻             │
│                                           │
│  ON-DEVICE MODELS                         │
│  📱 Gemma 2B           Downloaded 557M    │
│  📱 Phi-3 Mini              ⬇ 2.9 GB     │
├───────────────────────────────────────────┤
│  [⚖️ Compare Models]                      │
└───────────────────────────────────────────┘
```

**Model card anatomy:** Source icon (🌐/☁️/📱), model name (bold), provider badge, server name, size/params, capability icons (💬🛠👁💻), cost for cloud.

**States:** Populated (grouped sections), Filtered (chip selection narrows list), Compare mode (multi-select 2–4 models, checkboxes appear), Empty per-section ("Add a server in Settings"), Server unreachable ("{Name} not responding. [Retry] [Settings]").

**Interactions:** Tap model → close sheet + update app bar. Filter chips narrow list. "Compare Models" → multi-select. On-device download button → progress bar.

**A11y:** "Model picker. 12 models available. Filter: All." Cards: "Qwen 2.5 7B, remote, Ollama, supports chat tools vision."

### 3.2 ProviderBadge

Compact label showing model source. `[🌐 Ollama]` / `[☁️ Anthropic]` / `[📱 On-Device]`. Appears in model cards, app bar, message bubbles. Color tint per provider category. Read as part of parent context.

### 3.3 CapabilityChips

Icons: 💬 Chat, 🛠 Tools, 👁 Vision, 💻 Code. Supported capabilities rendered; unsupported omitted. Tap in app bar opens detail sheet. A11y reads as group: "Supports chat, tools, and vision."

### 3.4 CostIndicator

Cloud-only. Three levels: per-message ("☁️ Claude 3.5 · 1,240 tokens · ~$0.004" — tap to expand breakdown), per-conversation ("~$0.12, 42 messages"), monthly in Settings. Muted secondary text. Hidden for local/self-hosted. A11y: "Estimated cost: 0.4 cents."

### 3.5 ProviderHealthIndicator

Real-time connection dot: 🟢 Connected, 🟡 Connecting, 🔴 Disconnected. Shown on server cards and app bar chip. Background health checks at 60s interval. Independent of Default badge. Tap disconnected → reconnect attempt. **Color always paired with text label.**

---

## 4. Tool Components

### 4.1 ToolBadge

**Purpose:** Inline chat indicator for tool invocation and result.

```
Loading:  🔍 Web Search · "query" ⏳ Searching...
Success:  🔍 Web Search · "query" ✓ 5 results (1.2s)
Error:    🔍 Web Search ❌ Timeout  [↻ Retry] [Continue without] [Settings]
MCP:      🔌 Code Tools: Search Codebase · "binary_search" ⏳
```

**States:** Loading (spinner + shimmer), Success (checkmark, tappable to expand), Error (❌ + action buttons).

**Interactions:** Tap success → expand ToolResultCard. Retry re-invokes. "Continue without" proceeds without results.

**A11y:** "Web search in progress." / "Complete, 5 results, 1.2 seconds." / "Failed, timeout. Retry available."

### 4.2 ToolResultCard

**Purpose:** Expandable card below ToolBadge showing detailed output.

```
┌─────────────────────────────────────┐
│  🔍 Web Search · 5 results          │
├─────────────────────────────────────┤
│  Flutter List.sort() documentation  │
│  dart.dev · "The sort method..."    │
│  [Show 3 more results]             │
└─────────────────────────────────────┘
```

Collapsed shows summary count; expanded shows individual results (scrollable if >3). MCP results show code snippets with View/Copy actions. Tap header to collapse.

### 4.3 ToolConfigPanel

**Purpose:** Settings panel for web search and MCP servers.

```
Web Search:  [Enabled 🔘]  API Key: ••••••  Usage: 85/100
MCP Servers:
  🟢 Code Tools (12 tools · 2m ago)
  🔴 Research Assistant (8 tools · Disconnected)  [⋮]
  [+ Add MCP Server]
```

Toggle web search on/off. Tap MCP server → browse tool library (searchable, per-tool permissions: auto-allow / require confirmation / deny). Overflow: Test Connection, Edit, Remove.

---

## 5. Navigation Components

### 5.1 ConversationList

**Purpose:** Scrollable conversation list in the navigation drawer, grouped by date.

```
┌───────────────────────────────────────┐
│  🔒 Private Chat Hub                  │
│  [+ New Chat]                         │
├───────────────────────────────────────┤
│  TODAY                                │
│    How to sort a list in Dart         │
│    🌐 Qwen 2.5 7B · 12:04 PM        │
│                                       │
│  YESTERDAY                            │
│    Write unit tests for auth          │
│    ☁️ Claude 3.5 · 3:15 PM           │
├───────────────────────────────────────┤
│  🎯 Running Tasks             [3]    │
│  ⚙️ Settings                          │
└───────────────────────────────────────┘
```

**Groups:** Today, Yesterday, Previous 7 Days, Older. Running Tasks section visible only when active. Empty: "No conversations yet. Start chatting!"

**Interactions:** Tap to open. "New Chat" starts fresh. Long-press → context menu. Edge swipe or ☰ opens/closes.

### 5.2 ConversationListItem

Single row: auto-generated title (~40 chars), model badge, timestamp. Long-press menu: Rename, Pin, Move to Project, Archive, Delete (confirmation required). States: default, selected (highlighted), pinned (📌 prefix).

### 5.3 ProjectCard

Group conversations by project. Shows: color dot, name, count. "All Conversations" always first. Assign via long-press → "Move to..." Tap to filter conversation list.

---

## 6. Settings Components

### 6.1 ProviderConfigCard

**Purpose:** Server entry in Providers settings showing connection info and health.

```
Ollama
  🟢 Home Server       [Default]  192.168.1.20:11434  2m ago  [⋮]
  🔴 Lab Server                   10.0.0.5:11434  Unreachable  [⋮]
[+ Add Server]
```

**Status chips:** Default (blue), Reachable (green), Unreachable (red), Needs Attention (amber). Independent — a default server can be offline. Overflow: Test Connection, Edit, Set as Default, Delete. First server auto-defaults; deleting default promotes next.

**Add/Edit dialog:** Server Type (Ollama | LM Studio segmented button), Name, Host, Port, HTTPS toggle, Test Connection, Save / Save & Set as Default.

### 6.2 ServerListItem

Individual row within a provider section. Same health indicator pattern as §3.5. Reused for remote servers and MCP servers with context-appropriate overflow actions.

### 6.3 ThemeSelector

Segmented button: System / Dark / Light — applies immediately. Dynamic Color (Material You) toggle (Android 12+). Font size dropdown: Default, Small, Large, Extra Large.

---

## 7. Feedback Components

### 7.1 ErrorBanner

**Purpose:** Non-modal, top-anchored inline error. All errors inline — never modal dialogs.

```
⚠️ Connection lost. Retrying...              [Retry Now]
⚠️ Server '{name}' unavailable.    [Retry] [Switch Model] [Settings]
No provider configured.                      [Set up now]
```

**States:** Warning (amber, auto-retry), Error (red, user action needed), Info (surface, setup nudge). Dismisses automatically when resolved. Chat scrollable; input may be disabled during connection errors.

**A11y:** Announced on appearance: "Warning: Connection lost." Auto-dismiss: "Connection restored."

### 7.2 EmptyState

Contextual placeholder per screen. Simple monochrome icon + message + optional action button.

- **Chat:** "Start a conversation. Your data stays on your device. [Choose a Model]"
- **Drawer:** "No conversations yet. Start chatting!"
- **Model picker:** "Set up a provider in Settings to get started."
- **Search:** "No results for '{query}'. Try different terms."

### 7.3 LoadingOverlay

**Purpose:** Blocking loading state for long operations.

- **Indeterminate:** Circular spinner + text ("Connecting to Home Server..."). Scrim at 40% opacity.
- **Determinate:** Linear progress bar + percentage + size ("████░░ 65% 1.9/2.9 GB [Cancel]").

**A11y:** "Loading. Connecting to Home Server." / "Downloading. 65 percent. Cancel available."

---

## Appendix: Component-to-Screen Mapping

| Component | Primary Screen | Also Appears |
|-----------|---------------|--------------|
| MessageBubble | Chat | — |
| MessageActions | Chat (long-press) | — |
| ChatInput | Chat (bottom) | — |
| StreamingIndicator | Chat (inline) | Compare mode |
| ModelPicker | Bottom sheet | — |
| ProviderBadge | Model picker, app bar | Message bubbles |
| CapabilityChips | Model picker, app bar | — |
| CostIndicator | Chat, model picker | Settings (monthly) |
| ProviderHealthIndicator | Settings, app bar | Model picker |
| ToolBadge | Chat (inline) | — |
| ToolResultCard | Chat (inline) | — |
| ToolConfigPanel | Settings | — |
| ConversationList | Navigation drawer | — |
| ConversationListItem | Navigation drawer | — |
| ProjectCard | Navigation drawer | — |
| ProviderConfigCard | Settings → Providers | — |
| ServerListItem | Settings → Providers | Settings → MCP |
| ThemeSelector | Settings → Appearance | — |
| ErrorBanner | Chat (top) | Model picker |
| EmptyState | Chat, drawer, picker | Search |
| LoadingOverlay | Chat, settings | Model download |
