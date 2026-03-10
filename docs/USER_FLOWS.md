# User Flows: Private Chat Hub

**Purpose:** Visual maps of every key user journey — from first launch to advanced features.
**Companion doc:** [UX_DESIGN.md](UX_DESIGN.md) for screen specs, component details, and design decisions.

---

## 1. First-Time Setup

New user opens the app for the first time. Three-screen onboarding leads to a configured provider and a ready chat.

```
  ┌───────────┐     ┌──────────────────────┐     ┌──────────────┐
  │  Welcome   │────▶│   Choose Provider     │────▶│   Success    │
  │            │     │                      │     │              │
  │ "Your AI,  │     │ ┌─────────────────┐  │     │ "Connected!" │
  │  Your Data,│     │ │ 🌐 Remote Server│  │     │ Found N      │
  │  Your      │     │ │ 📱 On-Device    │  │     │ models.      │
  │  Control"  │     │ │ ☁️  Cloud (OC)   │  │     │              │
  │            │     │ └────────┬────────┘  │     │ [Start Chat] │
  │ [Get       │     │          │           │     └──────────────┘
  │  Started]  │     │  [Skip ──────────────────▶ Chat + banner:
  └───────────┘     └──────────┼───────────┘   "No provider. [Set up]"]
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
     ┌─────────────┐   ┌─────────────┐    ┌─────────────┐
     │ Remote Setup│   │  On-Device  │    │  OpenCode   │
     │             │   │   Setup     │    │   Setup     │
     │ Type: Ollama│   │             │    │             │
     │ /LM Studio  │   │ Pick model  │    │ Endpoint +  │
     │ Host + Port │   │ to download │    │ API key     │
     │ [Test]      │   │ (size shown)│    │ [Test]      │
     └──────┬──────┘   └──────┬──────┘    └──────┬──────┘
            │                 │                   │
            ▼                 ▼                   ▼
     ┌─────────────┐   ┌─────────────┐    ┌─────────────┐
     │  ✓ Pass     │   │  Downloading│    │  ✓ Pass     │
     │  ✗ Fail ──▶ │   │  ████░░ 65% │    │  ✗ Fail ──▶ │
     │   [Retry]   │   │  [Cancel]   │    │   [Retry]   │
     └─────────────┘   └─────────────┘    └─────────────┘
```

**Key decisions:**
- Any single provider is enough to proceed — users can add more later.
- Skip is always available; lands on chat with a non-blocking banner.
- Auto-discovery (mDNS) offered during Remote Setup as an optional scan.

---

## 2. Core Chat

The primary loop: type a message, receive a streaming AI response.

```
                          ┌──────────────┐
                          │  Chat Screen │
                          │  (home)      │
                          └──────┬───────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
   ┌─────────────┐       ┌─────────────┐        ┌─────────────┐
   │  Type msg   │       │  Attach 📎  │        │  Toggle 🛠  │
   │  [➤ Send]   │       │  file/image │        │  tools FAB  │
   └──────┬──────┘       └──────┬──────┘        └─────────────┘
          │                     │
          │   ┌─────────────────┘
          │   │  preview chips + optional text
          ▼   ▼
   ┌──────────────┐    Vision model?
   │  Send to     │───── No ──▶ "Switch to [vision model]?"
   │  provider    │               [Cancel] [Switch]
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
   │ User message │────▶│  Streaming   │────▶│  Complete    │
   │ appears      │     │  response    │     │  response    │
   │ instantly    │     │  ▌ cursor    │     │  (markdown)  │
   └──────────────┘     │  [■ Stop]    │     └──────┬───────┘
                        └──────────────┘            │
                                                    ▼
                                             Message actions
                                             (long-press):
                                             Copy · Share ·
                                             Regenerate ·
                                             Listen (TTS)
```

**Key decisions:**
- Send button becomes Stop (■) during generation — user can cancel at any time.
- Thinking models show a collapsible "Thinking process" section above the answer.
- Offline: messages queue automatically; banner shows count; FIFO on reconnect.

---

## 3. Model Selection

Unified picker accessed via the app bar chip. One bottom sheet, all providers.

```
   ┌──────────────────────────────────────┐
   │  ☰  🤖 Qwen 2.5 7B ▾   [🛠] ⚙️    │  ◀── Tap model chip
   └──────────────┬───────────────────────┘
                  │
                  ▼
   ┌──────────────────────────────────────┐
   │  Choose a Model                  ✕   │
   ├──────────────────────────────────────┤
   │  [All] [Remote] [On-Device] [Cloud]  │  ◀── Source filter chips
   ├──────────────────────────────────────┤
   │  ★ RECOMMENDED                       │
   │  🌐 Qwen 2.5 7B        Ollama       │
   │     Home Server · 💬 🛠 👁           │
   │                                      │
   │  REMOTE MODELS                       │
   │  🌐 Llama 3.2 8B       Ollama       │
   │  🌐 DeepSeek Coder     LM Studio    │
   │                                      │
   │  CLOUD MODELS (via OpenCode)         │
   │  ☁️ Claude 3.5 Sonnet  ~$0.003/msg  │
   │  ☁️ GPT-4o             ~$0.005/msg  │
   │                                      │
   │  ON-DEVICE                           │
   │  📱 Gemma 2B           Downloaded    │
   │  📱 Phi-3 Mini         ⬇ 2.9 GB     │
   ├──────────────────────────────────────┤
   │  [⚖️ Compare Models]                 │
   └──────────────┬───────────────────────┘
                  │  Tap a model
                  ▼
   ┌──────────────────────────────────────┐
   │  ☰  🤖 Llama 3.2 8B ▾  [🛠] ⚙️     │  ◀── App bar updates
   │                                      │
   │  ┌────────────────────────────────┐  │
   │  │ Switched to Llama 3.2 8B      │  │  ◀── Divider in chat
   │  └────────────────────────────────┘  │
   └──────────────────────────────────────┘
```

**Key decisions:**
- Mid-conversation switching is allowed; a divider marks the switch point.
- Compare mode (2–4 models): side-by-side for 2, tabs for 3–4, with metrics panel.
- Cloud models always show cost estimate; local/self-hosted models never show cost UI.

---

## 4. Provider Configuration

Settings → Providers. Add, edit, test, set default, delete.

```
   Settings ──▶ Providers
                  │
   ┌──────────────┼──────────────────────┐
   │              │                      │
   ▼              ▼                      ▼
┌──────────┐  ┌──────────┐       ┌──────────┐
│ Remote   │  │ OpenCode │       │ On-Device│
│ Servers  │  │ (Cloud)  │       │ Models   │
└────┬─────┘  └────┬─────┘       └────┬─────┘
     │              │                  │
     ▼              ▼                  ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Server list  │ │ Gateway list │ │ Download /   │
│ per type:    │ │ Endpoint +   │ │ manage local │
│ Ollama,      │ │ API key      │ │ models       │
│ LM Studio    │ │              │ │              │
│ [+ Add]      │ │ [+ Add]      │ │ Storage info │
└──────┬───────┘ └──────────────┘ └──────────────┘
       │
       ▼  [+ Add Server]
┌─────────────────────────────────────┐
│ Type: [Ollama | LM Studio]         │
│ Name: ___________                   │
│ Host: ___________  Port: ____       │
│ HTTPS: [ ]                          │
│                                     │
│ [Scan Network]  (Ollama only)       │
│ [Test Connection]                   │
│                                     │
│    ✓ Connected! 5 models found.     │
│                                     │
│ [Save]  [Save & Set as Default]     │
└─────────────────────────────────────┘

   Server overflow menu (⋮):
   Test Connection · Edit · Set as Default · Delete
```

**Key decisions:**
- First server auto-defaults; changing default demotes previous (snackbar undo).
- Health checks run in background (60s interval); status dots update in real time.
- API keys stored via Android Keystore-backed secure storage; never exported.

---

## 5. Tool Calling

User enables tools, sends a message that triggers a tool, sees inline results.

```
   ┌──────────────┐
   │ Tools FAB    │  Tap to toggle: ON (filled) / OFF (outlined)
   │ [🛠]         │
   └──────┬───────┘
          │  Tools ON
          ▼
   ┌──────────────────────────────────────┐
   │ User: "What's the weather in Tokyo?" │
   └──────────────┬───────────────────────┘
                  │  Model decides to call tool
                  ▼
   ┌──────────────────────────────────────┐
   │ 🔍 Web Search · "Tokyo weather"     │
   │    ⏳ Searching...                   │  ◀── In-progress
   └──────────────┬───────────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
   ┌──────────┐       ┌──────────┐
   │ ✓ Success│       │ ❌ Error  │
   └────┬─────┘       └────┬─────┘
        │                   │
        ▼                   ▼
   ┌──────────────┐   ┌──────────────────────────────┐
   │ 🔍 Web Search│   │ 🔍 Web Search ❌ Timeout     │
   │ ✓ 5 results  │   │ [↻ Retry] [Continue] [⚙️]   │
   │ (1.2s)       │   └──────────────────────────────┘
   │ ▶ Expand     │
   └──────┬───────┘
          │
          ▼
   ┌──────────────────────────────────────┐
   │ AI: "The weather in Tokyo is..."     │
   │      (uses tool results in answer)   │
   └──────────────────────────────────────┘

   MCP TOOLS (same pattern, prefixed with server):
   🔌 Code Tools: Search Codebase · ⏳ Running...
   🔌 Code Tools: Search Codebase · ✓ 12 matches (0.8s)
```

**Key decisions:**
- Tool results are inline chat elements, not popups — non-blocking.
- MCP tools can require confirmation before execution (per-tool permission in Settings).
- Tool errors offer three actions: Retry, Continue without tool, open Settings.

---

## 6. Conversation Management

Create, browse, search, archive, and delete conversations from the drawer.

```
   ☰ (hamburger) or edge swipe
          │
          ▼
   ┌──────────────────────────────────┐
   │  🔒 Private Chat Hub            │
   │                                  │
   │  [+ New Chat]                    │
   │                                  │
   │  🔍 Search conversations...      │
   │                                  │
   │  TODAY                           │
   │  "Explain async/await"    Qwen   │
   │  "Recipe for pasta"       Llama  │
   │                                  │
   │  YESTERDAY                       │
   │  "Debug React hook"      Claude  │
   │                                  │
   │  PREVIOUS 7 DAYS                 │
   │  "Tokyo trip planning"    GPT-4o │
   │                                  │
   │  ─────────────────────────────── │
   │  ⚙️ Settings                     │
   └──────────────┬───────────────────┘
                  │
   ┌──────────────┼──────────────────────────────┐
   │              │                              │
   ▼              ▼                              ▼
  Tap           Long-press                    Swipe left
  ───           ──────────                    ──────────
  Open chat     Context menu:                 Delete
                • Rename                      (confirm dialog)
                • Pin
                • Move to Project
                • Archive
                • Delete

   SEARCH:
   ┌──────────────────────────────────┐
   │ 🔍 "pasta"                       │
   ├──────────────────────────────────┤
   │ "Recipe for pasta"               │
   │   "...use San Marzano tomatoes"  │  ◀── Matching snippet
   │   Yesterday · Llama 3.2          │
   └──────────────────────────────────┘
```

**Key decisions:**
- Auto-title from first user message (~40 chars); editable via rename.
- Archive removes from main list but keeps data; delete is permanent with confirmation.
- Full-text search across all message content with highlighted snippets.

---

## 7. Project Organization

Group conversations by topic or purpose.

```
   Drawer (long-press conversation)
          │
          ▼  "Move to Project"
   ┌──────────────────────────────────┐
   │  Move to Project                 │
   │                                  │
   │  🔵 Work                    (3)  │
   │  🟢 Personal                (7)  │
   │  🟠 Research                (2)  │
   │                                  │
   │  [+ Create New Project]          │
   │  [Remove from Project]           │
   └──────────────┬───────────────────┘
                  │
                  ▼  [+ Create New Project]
   ┌──────────────────────────────────┐
   │  New Project                     │
   │  Name: ___________               │
   │  Color: 🔴🟠🟡🟢🔵🟣           │
   │  [Cancel] [Create]              │
   └──────────────────────────────────┘

   DRAWER WITH PROJECT FILTER:
   ┌──────────────────────────────────┐
   │  Projects ▾                      │
   │  [All] [🔵 Work] [🟢 Personal]  │  ◀── Filter chips
   │                                  │
   │  TODAY                           │
   │  (filtered conversation list)    │
   └──────────────────────────────────┘
```

**Key decisions:**
- "All Conversations" is always the default view — projects are optional filters.
- A conversation belongs to at most one project at a time.
- Projects are lightweight: name + color. No nested hierarchy.

---

## 8. Cost Tracking

Informational cost display for cloud models. Local/self-hosted models show no cost UI.

```
   PER-MESSAGE (below AI response):
   ┌──────────────────────────────────────┐
   │  AI: "Here is your analysis..."      │
   │                                      │
   │  ☁️ Claude 3.5 · 1,240 tok · ~$0.004│  ◀── Tap to expand
   └──────────────┬───────────────────────┘
                  │  Tap
                  ▼
   ┌──────────────────────────────────────┐
   │  Token Breakdown                     │
   │  Prompt:     820 tokens   ~$0.001    │
   │  Response:   420 tokens   ~$0.003    │
   │  Total:    1,240 tokens   ~$0.004    │
   └──────────────────────────────────────┘

   PER-CONVERSATION (info area):
   ┌──────────────────────────────────────┐
   │  This conversation: ~$0.12           │
   │  42 messages · Claude 3.5 Sonnet     │
   └──────────────────────────────────────┘

   MONTHLY SUMMARY (Settings → Data & Privacy):
   ┌──────────────────────────────────────┐
   │  Cloud Usage This Month     ~$3.45   │
   ├──────────────────────────────────────┤
   │  Anthropic (Claude)         ~$2.10   │
   │  OpenAI (GPT-4o)            ~$1.35   │
   ├──────────────────────────────────────┤
   │  ℹ️ Costs are estimates. Actual      │
   │  billing is through your OpenCode    │
   │  provider.                           │
   └──────────────────────────────────────┘
```

**Key decisions:**
- Cost is always informational — the app does not handle billing.
- Display uses muted secondary text; never blocks usage or shows warnings.
- Only conversations with cloud messages show cost; pure local chats are cost-free.

---

## 9. Fallback & Error Recovery

All errors are inline — never modal dialogs. Every error offers actionable next steps.

```
CONNECTION LOST:
   ┌──────────┐     ┌───────────────────────────────────────────┐
   │ Connected│────▶│ ⚠️ Connection lost. Retrying... [Retry]   │  ◀── Top banner
   └──────────┘     └──────────────────┬────────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
             ┌───────────┐     ┌───────────┐     ┌───────────┐
             │ Auto-retry│     │  Manual   │     │  Continue │
             │(background│     │  [Retry]  │     │  offline  │
             │ exp. back-│     │           │     │  (read    │
             │ off)      │     │           │     │  history) │
             └─────┬─────┘     └───────────┘     └───────────┘
                   │
          ┌────────┴────────┐
          ▼                 ▼
   ┌─────────────┐   ┌─────────────┐
   │ ✓ Reconnect │   │ ✗ Still off │
   │ Hide banner │   │ Next retry  │
   └─────────────┘   └─────────────┘

GENERATION ERROR:
   ┌──────────────────────────────────────────────┐
   │ AI: "Here is the partial respo..."           │
   │                                              │
   │ ⚠️ Generation stopped.  [Retry] [Delete]     │
   └──────────────────────────────────────────────┘

SERVER UNREACHABLE:
   ┌──────────────────────────────────────────────┐
   │ Server 'Home Server' unavailable.            │
   │ [Retry]  [Switch Model]  [Settings]          │
   └──────────────────────────────────────────────┘

MODEL MISSING:
   ┌──────────────────────────────────────────────┐
   │ 'llama3.2' not available on 'Home Server'.   │
   │ [Choose Model]  [Switch Server]              │
   └──────────────────────────────────────────────┘

PROVIDER FALLBACK:
   Selected model unavailable
          │
          ▼
   Auto-select first available model from same provider
          │
          ├── Found? ──▶ Snackbar: "Switched to [model]"
          │
          └── None? ──▶ Try next provider ──▶ Banner with [Settings]
```

**Key decisions:**
- Auto-retry uses exponential backoff (2s, 4s, 8s, …, 60s max).
- Offline mode: input disabled, history readable, queued messages send on reconnect.
- Fallback prefers same-provider models before cross-provider switch.

---

## 10. Settings

All configuration grouped under a single scrollable screen.

```
   ⚙️ Settings
   │
   ├── PROVIDERS
   │   ├── Remote Servers (Ollama, LM Studio)  ──▶ [Flow 4]
   │   ├── OpenCode (Cloud Gateway)
   │   └── On-Device Models
   │
   ├── TOOLS & CAPABILITIES
   │   ├── Web Search: [toggle] API key, quota display
   │   └── MCP Servers: list, add/remove, per-tool permissions
   │       └── Tool Library: searchable, per-tool: auto / confirm / deny
   │
   ├── TEXT-TO-SPEECH
   │   ├── Enable: [toggle]
   │   ├── Voice: [selector]
   │   ├── Speed: [0.5x ──●── 2.0x]
   │   ├── Auto-play new responses: [toggle]
   │   └── Background playback: [toggle]
   │
   ├── APPEARANCE
   │   ├── Theme: System / Dark / Light
   │   ├── Dynamic Color (Material You): [toggle]
   │   └── Font size override
   │
   ├── CHAT
   │   ├── Preset: Creative / Balanced / Precise
   │   ├── Advanced ▶ temperature, top-p, top-k sliders
   │   ├── Context length
   │   └── Default system prompt
   │
   └── DATA & PRIVACY
       ├── Export conversations (JSON / Markdown / Plain Text)
       ├── Storage usage
       ├── Cloud cost summary (monthly)  ──▶ [Flow 8]
       ├── Clear conversations (confirmation dialog)
       └── Clear cache
```

**Key decisions:**
- Chat presets (Creative/Balanced/Precise) hide raw sliders by default — advanced toggle reveals them.
- MCP tool permissions are per-tool: auto-allow, require confirmation, or deny.
- Export and clear are destructive — both require explicit confirmation.

---

## Screen Map

Quick reference for how all flows connect.

```
┌─────────────────────────────────────────────────────────┐
│                     APP SCREEN MAP                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ENTRY                                                  │
│  • First launch ──▶ Onboarding [1] ──▶ Chat            │
│  • Normal launch ──▶ Chat (last conversation)           │
│                                                         │
│  PRIMARY                                                │
│  • Chat Screen [2] ─── app bar chip ──▶ Model Picker [3]│
│  • Navigation Drawer ──▶ Conversations [6], Projects [7]│
│  • Settings [10] ──▶ Providers [4], Tools [5], Cost [8] │
│                                                         │
│  OVERLAYS                                               │
│  • Model Picker (bottom sheet) [3]                      │
│  • Tool results (inline) [5]                            │
│  • Error banners (inline) [9]                           │
│  • Message actions (long-press context menu)            │
│  • Confirmation dialogs (delete, clear)                 │
│                                                         │
│  Max depth: 3 levels. Most actions: 2 taps from chat.   │
└─────────────────────────────────────────────────────────┘
```

---

**Related Documents:**
- [UX_DESIGN.md](UX_DESIGN.md) — Screen specs, component details, design decisions
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) — Functional requirements
