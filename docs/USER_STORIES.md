# User Stories: Private Chat Hub

**Status:** Active · **Personas:** See [USER_PERSONAS.md](USER_PERSONAS.md)

Stories are provider-agnostic — features work across local (on-device), self-hosted (Ollama), and cloud API (OpenAI, Anthropic, Google AI) providers unless noted otherwise.

### Conventions

**Story Points (Fibonacci):**

| Points | Complexity | Effort |
|--------|-----------|--------|
| 1 | Trivial | < 4 hours |
| 2 | Simple | 4–8 hours |
| 3 | Medium | 1–2 days |
| 5 | Complex | 3–5 days |
| 8 | Very Complex | 1–2 weeks |
| 13 | Epic-sized | Needs decomposition |

**Priority:** Must = required for launch · Should = important, not blocking · Could = nice to have

**Personas referenced:** Alex (Privacy Advocate) · Maya (AI Experimenter) · Jordan (Cost-Conscious Developer) · Priya (Mobile Professional) · Sam (Student / Learner) · Chris (Enterprise User)

---

## Epic 1: Chat & Messaging

Core conversation experience — sending messages, receiving streaming responses, and interacting with content.

### US-CHAT-01: Send and Receive Messages
**As** any user, **I want to** send text and receive streaming AI responses, **so that** I can have real-time conversations with any AI model.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I type a message and tap Send, **When** it's delivered, **Then** it appears instantly (visually distinct from AI messages) with a timestamp.
- **Given** the provider begins responding, **When** tokens stream in, **Then** I see a typing indicator and incremental text; Markdown (bold, lists, code blocks) renders with syntax highlighting and links are tappable.
- **Given** I want to stop generation, **When** I tap Cancel, **Then** the request stops and the partial response is preserved.
- **Given** a long conversation, **When** new messages arrive, **Then** the chat auto-scrolls smoothly at 60 FPS; I can scroll up to see history without disruption.
- **Given** the multi-line input field, **When** I type long messages, **Then** the input area expands up to 5 lines before becoming scrollable.

### US-CHAT-02: Interact with Messages
**As** Maya (AI Developer), **I want to** copy, retry, edit, and delete messages, **so that** I can reuse AI outputs and fix mistakes.  
**Priority:** Should · **Points:** 3

**Acceptance Criteria:**
- **Given** I long-press a message, **When** the context menu appears, **Then** I see Copy, Share, Regenerate, Edit, and Delete actions.
- **Given** I tap Copy, **When** the clipboard updates, **Then** I see a confirmation toast; code blocks copy as plain text.
- **Given** I tap Edit on a user message, **When** I modify and resend, **Then** a new exchange is created preserving original history.
- **Given** I tap Regenerate on an AI response, **When** the model re-runs, **Then** a new response replaces the old one.

### US-CHAT-03: Attach Images for Vision Models
**As** Maya (AI Developer), **I want to** attach images from camera or gallery, **so that** I can use vision models to analyze photos.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I tap the attachment button, **When** I choose Camera or Gallery, **Then** selected images appear as thumbnails (up to 5); I can remove any before sending and tap to preview full-size.
- **Given** the current model lacks vision support, **When** I try to send with images, **Then** I see a warning naming vision-capable models and can switch with one tap.
- **Given** an image exceeds 5 MB, **When** preparing to send, **Then** the app compresses it automatically while maintaining reasonable quality.
- **Given** a message with images is sent, **When** viewing the conversation, **Then** images display inline as thumbnails and I can tap to view full-screen.

### US-CHAT-04: Attach Files as Context
**As** Maya (AI Developer), **I want to** attach text files for AI context, **so that** it can help with code review and document analysis.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I tap Attach File, **When** I select a supported file (.txt, .md, .py, .js, .json, .pdf, etc.), **Then** it shows file name, size, type icon, and a remove button.
- **Given** a file exceeds 5 MB, **When** the check runs, **Then** I see a warning; files over 10 MB are blocked.
- **Given** I send with an attached file, **When** delivered, **Then** content is extracted into the prompt and shown as a collapsible card in chat.

### US-CHAT-05: Share via Android Intents
**As** Jordan (Power User), **I want to** share content into and out of the app via Android share sheet, **so that** I can quickly discuss content from other apps and distribute AI responses.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I share text/images from another app, **When** I pick Private Chat Hub, **Then** the app opens with content pre-populated in the input field.
- **Given** I tap Share on a conversation or message, **When** the share sheet opens, **Then** I can share as plain text, Markdown, or HTML.

---

## Epic 2: Provider Management

Adding, configuring, and monitoring AI providers — local (on-device), self-hosted (Ollama), and cloud APIs (OpenAI, Anthropic, Google AI).

### US-PROV-01: Configure Provider Connections
**As** Alex (Privacy Advocate), **I want to** add and configure Ollama servers and cloud API providers, **so that** I can use my preferred AI backends.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I open provider settings, **When** I select Ollama, **Then** I see Host/Port fields (default 11434), can test the connection, and save multiple named profiles (e.g., "Home Server", "Office").
- **Given** I select a cloud provider (OpenAI, Anthropic, Google AI), **When** I configure it, **Then** I can enter an API key (securely stored), optional organization ID, optional custom base URL (for proxies), and test the connection.
- **Given** I have multiple providers, **When** I view the list, **Then** I can enable/disable each, set priority order, and see connection status indicators (🟢/🟡/🔴/⚪).
- **Given** I configured a provider, **When** I close and reopen the app, **Then** the configuration persists and enabled providers auto-connect.

### US-PROV-02: Add Cloud API Keys
**As** Sam (Budget-Conscious User), **I want to** securely add and manage API keys for cloud providers, **so that** I can access the latest models while keeping credentials safe.  
**Priority:** Must · **Points:** 3

**Acceptance Criteria:**
- **Given** I enter an API key for OpenAI, Anthropic, or Google AI, **When** I save, **Then** the key is validated against the provider's API, stored encrypted via flutter_secure_storage, and shown masked on return (e.g., `sk-...abc`).
- **Given** validation fails (invalid key, expired, quota exceeded), **When** the error is returned, **Then** I see a clear message explaining the issue with a link to the provider's API key page.
- **Given** keys are stored, **When** the app writes logs, crash reports, or exports data, **Then** no API keys appear in any output; keys are cleared on app uninstall.

### US-PROV-03: View Provider Health and Status
**As** Jordan (Power User), **I want to** see real-time health for each provider, **so that** I know which ones are available before chatting.  
**Priority:** Should · **Points:** 3

**Acceptance Criteria:**
- **Given** providers are configured, **When** I view the provider list or model picker, **Then** each shows a status badge: 🟢 Healthy (>95% success), 🟡 Degraded (80–95%), 🔴 Unavailable (<80%), ⚪ Disabled/Unconfigured.
- **Given** a provider goes offline or gets rate-limited, **When** the periodic health check detects it (every 60s), **Then** the status updates with a brief explanation (e.g., "Rate limited — retry in 30s").
- **Given** I tap a provider's status badge, **When** the detail view opens, **Then** I see last check time, success rate, average latency, error message (if any), and a "Test Now" button.

### US-PROV-04: Automatic Provider Fallback
**As** any user, **I want** the app to try fallback providers when my primary fails, **so that** conversations aren't interrupted by outages.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** a provider fails (network error, rate limit, model unavailable), **When** fallback is enabled, **Then** the app presents fallback options: equivalent model on another provider, Ollama, local on-device, or queue the message.
- **Given** "Auto-fallback" mode is on, **When** a failure occurs, **Then** the next provider in the fallback chain is tried within 2 seconds with a brief notification showing the switch.
- **Given** "Always ask" mode is on, **When** a failure occurs, **Then** I see a dialog listing alternatives with model names, provider types, and cost implications.
- **Given** all providers fail, **When** no fallback is available, **Then** the message is queued and auto-retried when a provider recovers; I see a clear notification.

---

## Epic 3: Model Discovery & Selection

Finding, downloading, and choosing models across all provider types.

### US-MODEL-01: Browse and Select Models
**As** Maya (AI Developer), **I want to** see all models from all providers in a unified picker, **so that** I can switch models quickly regardless of provider.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I tap the model selector, **When** the picker opens, **Then** models are grouped by provider type: ☁️ Cloud APIs (with sub-groups per provider), 🖥️ Self-Hosted (Ollama), 📱 Local (On-Device); the current model is highlighted.
- **Given** I view a cloud model entry, **When** I read its details, **Then** I see name, provider, context length, capability badges (👁️ vision, 🔧 tools, 💻 code), and cost per 1K tokens.
- **Given** I view an Ollama model entry, **When** I read its details, **Then** I see name, parameter count, size on disk, and capability badges; cost shows as "Free."
- **Given** I select a different model, **When** I tap it, **Then** it becomes active and a divider in chat shows "Now using [Model Name] via [Provider]."
- **Given** a provider is unconfigured, **When** I see it in the picker, **Then** it shows "Add API Key" inline; tapping opens the provider setup flow.
- **Given** I have favorite models, **When** I open the picker, **Then** favorites appear in a pinned section at the top.

### US-MODEL-02: View Model Details
**As** Alex (Privacy Advocate), **I want to** see detailed model information, **so that** I can make informed decisions about capability, cost, and privacy.  
**Priority:** Must · **Points:** 3

**Acceptance Criteria:**
- **Given** I tap a model's info icon, **When** the detail view loads, **Then** I see: name, family (Llama, GPT, Claude, Gemini, etc.), parameter count, quantization level (Ollama), size on disk, context length, and capability badges.
- **Given** the model is cloud-based, **When** I view details, **Then** I also see input/output token pricing, max context window, and a privacy note that data is sent to the provider's servers.
- **Given** the model is local or self-hosted, **When** I view details, **Then** cost shows "Free" and a privacy note confirms data stays on-device or on my server.
- **Given** the model has limited metadata, **When** information is missing, **Then** the UI shows "Unknown" labels rather than errors.

### US-MODEL-03: Download and Manage Ollama Models
**As** Jordan (Power User), **I want to** browse, download, and delete Ollama models, **so that** I can try different self-hosted models.  
**Priority:** Must · **Points:** 8

**Acceptance Criteria:**
- **Given** I open Download Models, **When** the library loads, **Then** I see available models with name, description, parameter count, estimated download size, and capabilities; I can search and filter.
- **Given** I tap Download, **When** it starts, **Then** I see progress (%, speed, ETA), can navigate away without canceling, and can pause or cancel at any time.
- **Given** a download completes, **When** I return to the model picker, **Then** the new model appears and I can immediately select it.
- **Given** I want to remove a model, **When** I tap Delete with confirmation, **Then** it's removed from the Ollama server and disappears from the model list.
- **Given** I lose network during a download, **When** connectivity returns, **Then** the download resumes from where it stopped.

### US-MODEL-04: Hardware-Based Recommendations
**As** Sam (Budget-Conscious User), **I want to** see which Ollama models suit my hardware, **so that** I don't download models that crash.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** I connect to Ollama, **When** the app queries system info, **Then** models are tagged 🟢 Recommended / 🟡 May be slow / 🔴 Not recommended.
- **Given** I try to download a heavy model, **When** I tap Download, **Then** I see a warning about expected issues and can proceed anyway.

---

## Epic 4: Conversation Management

Organizing, searching, exporting, and managing conversation history across all providers.

### US-CONV-01: Create and Manage Conversations
**As** Jordan (Power User), **I want to** create, rename, switch, and delete conversations, **so that** I stay organized.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I tap New Conversation, **When** it's created, **Then** I'm taken to an empty chat screen with the default model pre-selected and ready to type.
- **Given** I send the first message, **When** the title is empty, **Then** a title is auto-generated from the message content; I can edit it anytime by tapping the title.
- **Given** I open the conversation list, **When** it renders, **Then** each entry shows title, last message preview, timestamp, model used, and provider icon — sorted by recency.
- **Given** I swipe left or long-press and tap Delete, **When** I confirm in the dialog, **Then** the conversation and all messages are permanently removed.
- **Given** I switch between conversations, **When** I navigate back, **Then** scroll position and draft input text are preserved.
- **Given** I want to clear messages without deleting the conversation, **When** I tap "Clear Messages" with confirmation, **Then** all messages are removed but the conversation title remains.

### US-CONV-02: Search Conversation History
**As** Jordan (Power User), **I want to** search across all conversations, **so that** I can find past discussions quickly.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** I type a search query, **When** results load, **Then** they appear in <500 ms grouped by conversation with matches highlighted.
- **Given** I tap a result, **When** I navigate to it, **Then** the matching message is highlighted in context.
- **Given** I want to filter, **When** I apply date range or model filters, **Then** results update instantly.

### US-CONV-03: Export Conversations
**As** Alex (Privacy Advocate), **I want to** export conversations in standard formats, **so that** I own my data independently.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I access the export menu, **When** I choose scope, **Then** I can export a single conversation, selected conversations, or all conversations.
- **Given** I select a format, **When** I export as JSON, Markdown, or Plain Text, **Then** the file includes all messages, timestamps, model names, provider info, and conversation metadata.
- **Given** a conversation includes images, **When** exporting, **Then** images are either embedded (base64 in JSON) or saved separately with references.
- **Given** export completes, **When** the file is saved, **Then** it goes to the Downloads folder with a success notification; I can open or share it immediately via Android share sheet.
- **Given** I export many conversations, **When** processing, **Then** I see a progress indicator and can cancel without losing partial work.

---

## Epic 5: Tool Calling & Extensions

Web search, function calling, and MCP integration. Tool calling works with any provider that supports it (Ollama with compatible models, OpenAI, Anthropic, Google AI).

### US-TOOL-01: Web Search via Tool Calling
**As** any user, **I want** the model to search the web for current information, **so that** I get up-to-date answers without manually searching.  
**Priority:** Must · **Points:** 8

**Acceptance Criteria:**
- **Given** I ask about current events using any tool-capable model (Ollama, OpenAI, Anthropic, Google AI), **When** the model invokes web search, **Then** I see "Searching…" and results within 3 seconds as cards (title, snippet, clickable URL).
- **Given** the model incorporates search results, **When** the response renders, **Then** it cites sources and I can verify claims by tapping links.
- **Given** search fails (network error, rate limit, API key issue), **When** the tool errors, **Then** the model continues without results, I see a brief error notice, and a Retry button is available.
- **Given** I want to control web search, **When** I open tool settings, **Then** I can enable/disable globally or per conversation, enter a search API key, and clear the search cache.

### US-TOOL-02: Tool Result Rendering
**As** any user, **I want** tool results displayed clearly in chat, **so that** I understand what tools were used and what they returned.  
**Priority:** Must · **Points:** 3

**Acceptance Criteria:**
- **Given** a tool is invoked, **When** results display, **Then** I see tool name, a collapsible/expandable result card, execution time, and a Retry button on errors.
- **Given** results contain Markdown or links, **When** they render, **Then** formatting is correct and links are tappable.
- **Given** the model used multiple tools in one response, **When** I view the message, **Then** each tool invocation is shown in sequence with clear labels.

### US-TOOL-03: Connect to MCP Servers
**As** Jordan (Power User), **I want to** connect to MCP servers and use their tools, **so that** I can extend model capabilities.  
**Priority:** Should · **Points:** 8

**Acceptance Criteria:**
- **Given** I add an MCP server in settings, **When** I configure host/port and test, **Then** connection saves and shows available tools with schemas.
- **Given** a model invokes an MCP tool, **When** it executes, **Then** results render like any tool result with the MCP source indicated.
- **Given** I want to restrict access, **When** I open tool permissions, **Then** I can enable/disable tools and require confirmation for sensitive ones.

---

## Epic 6: Model Comparison

Side-by-side evaluation of multiple models across any provider combination (e.g., compare GPT-4o vs Claude vs a local Ollama model).

### US-COMP-01: Compare Models Side by Side
**As** Maya (AI Experimenter), **I want to** send a prompt to multiple models and see responses side by side, **so that** I can evaluate which handles my task best.  
**Priority:** Should · **Points:** 8

**Acceptance Criteria:**
- **Given** I tap Compare Models, **When** I select 2-4 models from any provider (mixing cloud, Ollama, local), **Then** a comparison session begins.
- **Given** I send a message, **When** all models respond, **Then** responses display side by side (or tabbed), labeled with model name, provider, and response time.
- **Given** I send follow-ups, **When** all models see full history, **Then** they respond in parallel.
- **Given** a cloud model is included, **When** responses arrive, **Then** each cloud response shows its token cost alongside the response time.

### US-COMP-02: View Performance Metrics
**As** Maya (AI Developer), **I want to** see response time, token count, and cost per model, **so that** I can choose the best model for my needs.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** comparison responses arrive, **When** I view them, **Then** each shows: total response time, time-to-first-token, output tokens per second, and estimated cost (cloud models show USD, local/Ollama show "Free").
- **Given** I rate a response, **When** I tap a thumbs-up/thumbs-down, **Then** the rating is stored per model and contributes to aggregated quality scores.
- **Given** historical data exists, **When** I view model metrics, **Then** I see aggregated stats (p50/p95 latency, total tokens, total cost) filterable by date range and model.

### US-COMP-03: Highlight Response Differences
**As** Maya (AI Developer), **I want** differences highlighted between responses, **so that** I quickly see where models diverge.  
**Priority:** Could · **Points:** 5

**Acceptance Criteria:**
- **Given** two responses for the same prompt, **When** I tap Compare, **Then** differences are color-coded and similar text is muted.
- **Given** the diff view, **When** I toggle it off, **Then** I return to the standard side-by-side view.

---

## Epic 7: Cost & Usage

Tracking spending and token usage across cloud API providers. Local and self-hosted models are always free.

### US-COST-01: Track Token Usage and Costs
**As** Jordan (Cost-Conscious Developer), **I want to** see token count and estimated cost for each cloud API message, **so that** I understand my spending in real time.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I receive a response from a cloud API model, **When** I view it, **Then** a subtle footer shows token count (input + output) and estimated USD cost (e.g., "📊 125 tokens · $0.0006 · 1.2s").
- **Given** I tap the cost footer, **When** the detail view expands, **Then** I see input tokens, output tokens, per-token rates for the model, and total cost breakdown.
- **Given** I use local or Ollama models, **When** I view messages, **Then** cost display shows "$0.00" or is hidden, clearly indicating no cost.
- **Given** a conversation header, **When** I've used cloud models, **Then** I see the running total cost for this conversation.

### US-COST-02: Set Cost Limits and Warnings
**As** Sam (Budget-Conscious User), **I want to** set daily and monthly spending limits per provider, **so that** I don't overspend on cloud APIs.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** I open cost settings for a cloud provider, **When** I configure limits, **Then** I can set a monthly spending cap and a warning threshold (e.g., 80%).
- **Given** usage reaches the warning threshold, **When** I send a message, **Then** I see a banner: remaining budget, estimated messages left at current model, reset date, and a "Switch to Free Model" button.
- **Given** I hit the hard limit, **When** I try to send, **Then** the request is blocked with a clear explanation; I'm offered to switch to a free local/Ollama model or adjust my limit.
- **Given** the billing period resets, **When** the date arrives, **Then** usage counters reset automatically.

### US-COST-03: View Usage Dashboard
**As** Sam (Budget-Conscious User), **I want to** see a summary of usage across all cloud providers, **so that** I can manage spending over time.  
**Priority:** Should · **Points:** 3

**Acceptance Criteria:**
- **Given** I open the usage dashboard, **When** it loads, **Then** I see per-provider and per-model breakdowns of tokens used and estimated costs for the current billing period.
- **Given** I select a date range, **When** the dashboard filters, **Then** results update and I can export the data as CSV or JSON.
- **Given** I want cost optimization, **When** a model is significantly more expensive than alternatives with similar capability, **Then** the dashboard suggests cheaper alternatives.

---

## Epic 8: Text-to-Speech

Audio output for AI responses — listen hands-free while driving, exercising, or multitasking.

### US-TTS-01: Listen to AI Responses
**As** Priya (Mobile Professional), **I want to** listen to AI responses via TTS, **so that** I can consume content hands-free.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** I see an AI response, **When** I tap the play button on the message, **Then** the response is read aloud using the device's TTS engine with pause/resume/stop controls.
- **Given** TTS is playing, **When** I adjust speed (0.8x–2.0x), **Then** the change takes effect immediately.
- **Given** I background the app while TTS is playing, **When** the app goes to the background, **Then** audio continues and respects system volume controls.
- **Given** TTS finishes a response, **When** playback completes, **Then** controls reset and I can replay or move to the next response.

### US-TTS-02: Configure TTS Preferences
**As** Chris (Casual User), **I want to** customize voice, speed, and language, **so that** TTS sounds natural.  
**Priority:** Should · **Points:** 3

**Acceptance Criteria:**
- **Given** I open TTS settings, **When** I configure voice/speed/pitch/language, **Then** I can preview the result and settings persist across sessions.

### US-TTS-03: Stream TTS While Generating
**As** Chris (Casual User), **I want** TTS to start before the full response is ready, **so that** I don't wait.  
**Priority:** Could · **Points:** 8

**Acceptance Criteria:**
- **Given** auto-play is enabled, **When** the model streams a response, **Then** TTS reads completed sentences incrementally.
- **Given** I stop playback, **When** I tap Stop, **Then** TTS halts without disrupting ongoing generation.

---

## Epic 9: Projects

Organizing conversations into logical workspaces for focused work.

### US-PROJ-01: Create and Manage Projects
**As** Maya (AI Developer), **I want to** group conversations into projects, **so that** I can organize by topic or goal.  
**Priority:** Could · **Points:** 5

**Acceptance Criteria:**
- **Given** I create a project, **When** I set a name and optional description, **Then** I can assign existing conversations to it or create new ones within it.
- **Given** I open a project, **When** I view it, **Then** I see all its conversations sorted by recency; conversations also remain accessible from the global list.
- **Given** I delete a project, **When** I confirm, **Then** the project is removed but its conversations are preserved in the global list (not deleted).

### US-PROJ-02: Project-Level Settings
**As** Maya (AI Developer), **I want to** set default model, system prompt, and parameters per project, **so that** new conversations inherit the right context.  
**Priority:** Could · **Points:** 3

**Acceptance Criteria:**
- **Given** I configure project defaults (model, system prompt, temperature, etc.), **When** I start a new conversation in the project, **Then** it inherits those defaults automatically.
- **Given** I override a project default in a conversation, **When** I view project settings, **Then** the project defaults remain unchanged; overrides are per-conversation only.

---

## Epic 10: Settings & Preferences

App-level configuration, model parameters, and tool settings.

### US-SET-01: Configure App Settings
**As** any user, **I want to** customize appearance and behavior, **so that** the app works the way I prefer.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I open Settings, **When** I view the screen, **Then** I see organized sections: Providers, Appearance, Chat, Data, About.
- **Given** I change theme (Light/Dark/System) or font size (S/M/L), **When** I save, **Then** changes apply instantly and persist across restarts.
- **Given** I view the Data section, **When** I interact, **Then** I can see storage used, clear cache, clear all conversations (with confirmation), and export all data.
- **Given** I view the About section, **When** it loads, **Then** I see app version, build number, open-source licenses, privacy policy link, and a link to report bugs/feedback.

### US-SET-02: Adjust Model Parameters
**As** Maya (AI Developer), **I want to** fine-tune model parameters per conversation, **so that** I can control creativity and length.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** I open model parameters, **When** I adjust sliders, **Then** I can set Temperature (0–2), Top-K, Top-P, Max Tokens — each with explanatory tooltips.
- **Given** I want a quick config, **When** I select a preset (Creative/Balanced/Precise/Code), **Then** parameters auto-fill; I can customize a system prompt and reset to defaults.
- **Given** parameters are set, **When** I switch conversations, **Then** each conversation remembers its own parameters.

### US-SET-03: Configure Tool Settings
**As** Jordan (Power User), **I want to** configure web search and tool preferences, **so that** I control tool behavior.  
**Priority:** Should · **Points:** 2

**Acceptance Criteria:**
- **Given** I open tool settings, **When** I view options, **Then** I can enable/disable web search, enter search API keys, and clear tool caches.

---

## Epic 11: Onboarding

First-time user experience guiding through provider setup and first conversation.

### US-ONBOARD-01: First-Time Setup Wizard
**As** a new user, **I want** a guided setup, **so that** I can start chatting quickly without reading documentation.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I launch for the first time, **When** the wizard starts, **Then** I see the app logo, tagline, and privacy highlights ("Your data stays on your device").
- **Given** I proceed, **When** I reach provider selection, **Then** the wizard explains the three tiers with clear icons: 📱 Local (free, 100% private, on-device), 🖥️ Self-Hosted (free, your server), ☁️ Cloud APIs (pay-per-use, latest models).
- **Given** I choose to configure a cloud provider, **When** I enter an API key, **Then** it's validated inline and I see available models before continuing.
- **Given** I choose to skip cloud setup, **When** I proceed, **Then** the wizard lets me continue with local or Ollama only — cloud is not required.
- **Given** setup completes, **When** I see the success screen, **Then** it shows available models, recommended starter model, and a "Start Chatting" button.

### US-ONBOARD-02: Provider Setup Guides
**As** a new user, **I want** step-by-step instructions per provider, **so that** I can configure even without prior experience.  
**Priority:** Should · **Points:** 3

**Acceptance Criteria:**
- **Given** I select Ollama during setup, **When** the guide loads, **Then** I see instructions for finding my server IP, verifying Ollama is running, and auto-discover is offered as a shortcut.
- **Given** I select OpenAI/Anthropic/Google AI, **When** the guide loads, **Then** I see step-by-step instructions with a deep link to the provider's API key page and expected cost ranges.
- **Given** I skip a provider during setup, **When** I want to add it later, **Then** the same guided setup is available from Settings > Providers.

---

## Epic 12: Offline & Privacy

Working without internet, local data control, and network discovery.

### US-PRIV-01: Persist All Data Locally
**As** Alex (Privacy Advocate), **I want** all data stored only on my device, **so that** I maintain complete control.  
**Priority:** Must · **Points:** 5

**Acceptance Criteria:**
- **Given** I use the app, **When** I monitor network traffic, **Then** no data is sent to any server except configured AI providers — zero telemetry or analytics without explicit consent.
- **Given** the app stores data, **When** I check file locations, **Then** the SQLite database is in the app's private directory, not accessible to other apps, and encrypted at rest via Android encryption.
- **Given** the app crashes mid-message, **When** I restart, **Then** no data is corrupted; the database remains consistent via transaction safety.
- **Given** thousands of messages, **When** I query conversations, **Then** responses return in <100 ms and the UI remains responsive.
- **Given** I want to verify privacy, **When** I check the About section, **Then** I see a privacy policy link confirming no data collection.

### US-PRIV-02: Work Offline with Local Models
**As** Alex (Privacy Advocate), **I want to** use on-device models with zero connectivity, **so that** I have complete privacy anywhere.  
**Priority:** Must · **Points:** 3

**Acceptance Criteria:**
- **Given** my device is in airplane mode, **When** I open the app, **Then** it launches normally and local on-device models are available for chat.
- **Given** I try to use a cloud or Ollama model while offline, **When** the connection check fails, **Then** I see a clear offline message and am offered to switch to an available local model.
- **Given** I compose messages while offline for cloud/Ollama providers, **When** connectivity is restored, **Then** queued messages are sent automatically and I'm notified of the results.
- **Given** I was chatting with a local model offline, **When** I go back online, **Then** the conversation continues seamlessly with no data loss.

### US-PRIV-03: Auto-Discover Ollama Instances
**As** Jordan (Power User), **I want** automatic Ollama discovery on my network, **so that** I don't type IP addresses manually.  
**Priority:** Should · **Points:** 5

**Acceptance Criteria:**
- **Given** I tap Auto-Discover, **When** the scan runs, **Then** Ollama instances appear within 10 seconds; tapping one fills the connection form.
- **Given** nothing is found, **When** the scan completes, **Then** I see troubleshooting tips and can enter details manually.

### US-PRIV-04: Clear All Data
**As** Alex (Privacy Advocate), **I want to** wipe all app data, **so that** nothing remains if I stop using the app.  
**Priority:** Must · **Points:** 2

**Acceptance Criteria:**
- **Given** I tap "Clear All Data" in Settings, **When** I confirm, **Then** all conversations, API keys, cached data, and settings are permanently deleted; the app returns to first-time setup.

---

## Summary

| Epic | Stories | Must | Should | Could | Points |
|------|---------|------|--------|-------|--------|
| 1. Chat & Messaging | 5 | 4 | 1 | 0 | 23 |
| 2. Provider Management | 4 | 3 | 1 | 0 | 16 |
| 3. Model Discovery & Selection | 4 | 3 | 1 | 0 | 21 |
| 4. Conversation Management | 3 | 2 | 1 | 0 | 15 |
| 5. Tool Calling & Extensions | 3 | 2 | 1 | 0 | 19 |
| 6. Model Comparison | 3 | 0 | 2 | 1 | 18 |
| 7. Cost & Usage | 3 | 1 | 2 | 0 | 13 |
| 8. Text-to-Speech | 3 | 0 | 2 | 1 | 16 |
| 9. Projects | 2 | 0 | 0 | 2 | 8 |
| 10. Settings & Preferences | 3 | 1 | 2 | 0 | 12 |
| 11. Onboarding | 2 | 1 | 1 | 0 | 8 |
| 12. Offline & Privacy | 4 | 3 | 1 | 0 | 15 |
| **Totals** | **39** | **20** | **15** | **4** | **184** |
