# Product Vision: Private Chat Hub

## Vision Statement

**Private Chat Hub** is a universal AI chat platform that gives users full control over how they interact with AI across mobile and desktop. One app connects to on-device models, self-hosted infrastructure, and cloud AI services — letting each user choose their own balance of privacy, performance, and cost. Saved chat history lives as portable plain-text files, while SQLite accelerates search, browsing, and local recovery without becoming the source of truth.

## Mission

Democratize access to AI by removing the false choice between privacy and capability. Users should never be locked into a single provider, forced to sacrifice privacy for power, or pay for features they don't need.

---

## Core Principles

### 1. Privacy by Choice
Users decide where their data goes — on-device, self-hosted, or cloud — per conversation if they want. We never make that decision for them. No telemetry, no hidden data collection. The default is always the most private option available.

### 2. Provider Agnostic
No vendor lock-in. Every feature works across provider types. The app is an interface to *all* AI, not a client for any single one. Adding a new provider should never require rethinking the user experience.

### 3. Cost Transparency
Cloud AI costs money. We make that visible — per message, per conversation, per month. We proactively suggest free local or self-hosted alternatives when they can handle the task. No surprises.

### 4. Offline First
The app must be fully functional without an internet connection when paired with on-device models. Saved histories remain available from local files, while cloud and self-hosted features degrade gracefully: messages queue, sync-compatible files remain readable, and connectivity-dependent actions recover cleanly.

### 5. Portable History Ownership
Conversation history belongs to the user as plain-text files they can read, back up, sync, and restore on another device. The app may cache and index that history locally for speed, but it never hides user data behind a proprietary database format.

### 6. Simplicity Over Complexity
Complex infrastructure, simple interface. A new user should be productive within minutes. Power features exist but don't clutter the default experience.

---

## Value Proposition

### For Privacy-Conscious Users
- **Complete data ownership** — local and self-hosted conversations never leave your control
- **Full offline mode** — chat with on-device models anywhere, no internet required
- **Portable plain-text history** — open your saved chats in any text editor, sync them with your own tools, and restore them on another device
- **Per-conversation privacy** — choose local, self-hosted, or cloud for each conversation independently

### For AI Enthusiasts & Developers
- **Universal model access** — on-device, self-hosted (Ollama), and cloud APIs (OpenAI, Anthropic, Google, and more) in one place
- **Cross-provider model comparison** — test the same prompt across providers, compare quality, speed, and cost
- **Flexible infrastructure** — run models on-device, on a home server, or pay-per-use in the cloud
- **Advanced capabilities** — vision models, file context, tool calling, extended reasoning

### For Cost-Conscious Users
- **No mandatory subscription** — use free on-device and self-hosted models with zero cost
- **Pay only for what you use** — cloud APIs billed per token, not per month
- **Smart routing** — automatically suggest the cheapest model that can handle the task
- **Transparent spending** — real-time cost tracking with configurable limits and warnings

---

## Key Differentiators

| Capability | Private Chat Hub | ChatGPT / Claude Apps | Jan.ai / LM Studio |
|---|---|---|---|
| **Model Sources** | Local + Self-Hosted + Cloud | Single cloud provider | Local / Self-hosted only |
| **Offline Mode** | Full (on-device models) | None | Limited (desktop only) |
| **Cloud APIs** | Multiple providers | Single provider | None |
| **Mobile + Desktop** | Adaptive mobile + desktop | Native mobile | Desktop only |
| **Privacy Tiers** | 3 tiers (local / self-hosted / cloud) | Cloud only | Local only |
| **Cost Model** | Free to pay-per-use | Subscription required | Free (own hardware) |
| **Self-Hosted** | Ollama support | None | Multiple backends |
| **Cross-Provider Comparison** | Yes | No | Local models only |

**Unique position:** The only adaptive mobile + desktop app supporting the full spectrum from on-device privacy to cloud convenience with portable, file-backed chat history.

### Competitive Positioning

**Against ChatGPT / Claude apps:**
- One app for all models — no vendor lock-in
- Your data, your choice: local, self-hosted, or cloud
- Save money with smart model routing and pay-per-use pricing

**Against Jan.ai / LM Studio:**
- Mobile and desktop with the same portable history model
- Best of both worlds: local privacy + cloud power when you need it
- Access the latest cloud models alongside your local ones

---

## Target Users

Detailed personas live in [USER_PERSONAS.md](USER_PERSONAS.md). Summary of key segments:

| Segment | Core Need | Primary Tier |
|---|---|---|
| **Privacy Advocates** | Complete data control, no cloud dependency | Local + Self-hosted |
| **AI Experimenters** | Test and compare models across providers | All three tiers |
| **Cost-Conscious Users** | AI capability without subscription fees | Local + Pay-per-use cloud |
| **Mobile Professionals** | AI assistance on the go, offline resilience | Cloud + Local fallback |
| **Enterprise / Compliance** | Air-gapped or self-hosted AI for policy compliance | Self-hosted |

---

## Product Pillars

The architecture is built on three provider tiers. Every feature must work across all tiers or clearly indicate which tiers it supports.

### Tier 1: On-Device (Local)
- Models run entirely on the user's phone
- Zero network traffic — complete privacy
- Zero cost — no API fees, no subscriptions
- Works offline, on airplane mode, in dead zones
- Limited by device hardware (smaller models, slower inference)
- **Use when:** Privacy is paramount, connectivity is unavailable, or cost must be zero

### Tier 2: Self-Hosted (Ollama)
- Models run on user-controlled infrastructure (home server, NAS, office machine)
- Traffic stays on local network — high privacy
- Zero API cost — user provides the hardware
- Larger, more capable models than on-device
- Requires infrastructure setup and maintenance
- **Use when:** Users want capable models with full data control

### Tier 3: Cloud APIs
- Models hosted by third-party providers (OpenAI, Anthropic, Google, and others)
- Data sent to provider servers — privacy depends on provider policy
- Pay-per-use token pricing — cost scales with usage
- Access to the largest, most capable models available
- Requires internet connectivity and API keys
- **Use when:** Users need the most capable models or don't want to manage infrastructure

### Cross-Tier Features
- **Smart fallback chains** — if the preferred provider is unavailable, gracefully fall back to the next tier (respecting user preferences)
- **Unified interface** — same chat experience regardless of which tier powers the response
- **Provider badges** — always clear which tier is handling each conversation
- **Offline queue** — messages to cloud/self-hosted providers queue automatically and send when connectivity returns

---

## Feature Pillars

### Core Chat Experience
- Text chat with streaming responses
- Markdown rendering with syntax-highlighted code blocks
- Conversation management (create, search, organize, delete)
- Message actions (copy, retry, edit, delete)
- Conversation history with full-text search

### Multi-Modal Input
- Image attachment for vision models (gallery and camera)
- File attachment as context (text, code, PDF, markdown)
- Model capability detection (auto-detect vision, tool calling, context length)

### Model Intelligence
- Unified model picker across all provider tiers
- Model comparison — same prompt, multiple models, side-by-side results
- Model information display (capabilities, size, cost, context window)
- Favorites and recents for fast switching

### Cost & Usage Management
- Per-message token usage display for cloud APIs
- Estimated cost per message and per conversation
- Monthly cost tracking by provider
- Configurable spending limits and warnings
- "Free alternative" suggestions when local/self-hosted models suffice

### Organization & Productivity
- Projects / Spaces as folder-backed workspaces
- Portable plain-text chat history with restore on another device
- Data export (JSON, Markdown, plain text)
- `persona.md` configuration per project folder
- Platform share/import integration (send to and receive from other apps)
- Text-to-speech for AI responses
- Conversation templates and custom agents

### Tool Calling & Extended Capabilities
- Tool calling framework (web search, external tools)
- Extended reasoning model support
- Background task execution with progress tracking
- Multi-step task orchestration

---

## Success Metrics

### User Engagement
| Metric | Target |
|---|---|
| Daily Active Users | Growing month-over-month |
| Messages per session | Increasing over time |
| Multi-provider adoption | 60%+ users configure ≥2 provider types |
| Conversation retention | Users return to past conversations regularly |

### Technical Performance
| Metric | Target |
|---|---|
| Message response time (p95) | < 5s (typical models) |
| App startup time | < 2s |
| Provider connection success rate | > 95% |
| Crash-free sessions | > 99.5% |

### User Satisfaction
| Metric | Target |
|---|---|
| App store rating | 4.5+ |
| 30-day retention | 60%+ |
| Net Promoter Score | Positive and growing |

### Business
| Metric | Target |
|---|---|
| Cloud API setup completion rate | > 80% of those who start |
| Feature request velocity | Healthy community engagement |
| Open source contributions | Growing contributor base |

---

## Distribution Strategy

| Channel | Audience |
|---|---|
| **Google Play Store** | Android mobile distribution |
| **F-Droid** | Privacy-focused users (local/self-hosted features only) |
| **GitHub Releases** | Power users, beta testers, and desktop builds |
| **Direct installers / APKs** | Enterprise and restricted environments |

## Pricing Philosophy

- **Free and open source.** The core app is always free.
- No artificial limitations on the free tier.
- Future optional pro features may include: advanced cost analytics, team collaboration, priority routing, advanced export formats.
- Cloud API costs are the user's responsibility (they bring their own API keys).

---

## Long-Term North Star

Private Chat Hub becomes the **universal AI interface** — one app to access any AI model from any source. Not just chat, but an intelligent layer that helps users pick the right model for each task, routes requests optimally, and keeps costs under control.

The ultimate goal: every user has access to every AI model — local, self-hosted, or cloud — through one beautifully designed, privacy-respecting app.

---

*Related documents:*
- [USER_PERSONAS.md](USER_PERSONAS.md) — Detailed target user profiles
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) — Functional and non-functional requirements
- [ARCHITECTURE.md](ARCHITECTURE.md) — Technical architecture and provider abstraction
