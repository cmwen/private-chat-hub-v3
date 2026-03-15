# User Personas: Private Chat Hub

**Document Version:** 2.0  
**Created:** January 2026  
**Purpose:** Define target users across the privacy-to-convenience spectrum to guide UX design and user story writing

---

## Overview

Private Chat Hub serves users who want **choice** in how they access AI — from fully offline on-device models, to self-hosted servers, to cloud APIs. These personas span that spectrum and reflect the diverse motivations driving adoption of a universal AI chat app.

---

## Persona 1: Alex — The Privacy Advocate

**Role:** System Administrator / DevOps Engineer  
**Age:** 30–50 | **Tech Savvy:** High

**Goals:**
- Maintain complete control over personal data — no cloud dependencies
- Use AI on mobile without sending conversations to third parties
- Integrate with existing self-hosted infrastructure (Ollama, home server)
- Eliminate subscription costs through self-hosted and local models

**Pain Points:**
- Cloud AI apps require surrendering private data to corporations
- Mobile AI tools are locked to cloud providers with no local option
- Desktop-focused local AI tools (Jan.ai, LM Studio) don't work on mobile
- No visibility into what data leaves the device

**Preferred Provider Mix:** 90% self-hosted (Ollama) / 10% on-device local models  
**Cloud willingness:** Only as an emergency fallback, if at all

**Key Scenarios:**
- Connects to home Ollama server over local network or VPN
- Uses on-device models when traveling without connectivity
- Exports all conversation history for local backup
- Verifies zero telemetry and no outbound data leaks

**Quote:** *"If I can't export it, own it, and control it, I won't use it."*

---

## Persona 2: Maya — The AI Experimenter

**Role:** ML Engineer / AI Enthusiast  
**Age:** 22–35 | **Tech Savvy:** Very High

**Goals:**
- Test and compare outputs across many models (local, self-hosted, cloud)
- Access the latest models as soon as they release
- Benchmark quality, speed, and cost across providers
- Use vision models, tool calling, and advanced capabilities on mobile

**Pain Points:**
- Switching between ChatGPT, Claude, and Ollama requires multiple apps
- Rate limits and per-seat subscriptions interrupt experimentation
- No single tool lets her compare a local model vs. GPT-4 vs. Claude side-by-side
- Cloud API costs spike during heavy experimentation sessions

**Preferred Provider Mix:** 40% cloud APIs / 40% self-hosted (Ollama) / 20% on-device  
**Cloud willingness:** High — values access to frontier models

**Key Scenarios:**
- Sends the same prompt to three different providers and compares outputs
- Switches from cloud to Ollama mid-conversation when hitting rate limits
- Attaches code files and images for multimodal testing
- Tracks token usage and estimated cost per session

**Quote:** *"I need to test 10 different models with the same prompt in under a minute."*

---

## Persona 3: Jordan — The Cost-Conscious Developer

**Role:** Freelance Developer / Indie Hacker  
**Age:** 22–40 | **Tech Savvy:** Medium-High

**Goals:**
- Get capable AI assistance without expensive subscriptions
- Use free local/self-hosted models for routine tasks, cloud APIs only when needed
- Track and control spending across providers
- Keep work conversations organized by project

**Pain Points:**
- $20/month ChatGPT Plus feels excessive for intermittent use
- Pay-per-use cloud APIs are great but costs are hard to predict
- No single app lets him mix free local models with occasional cloud calls
- Conversation history scattered across multiple apps and providers

**Preferred Provider Mix:** 60% self-hosted (Ollama) / 30% cloud APIs (pay-per-use) / 10% on-device  
**Cloud willingness:** Moderate — uses cloud strategically for complex tasks

**Key Scenarios:**
- Uses Ollama for daily coding questions (free), switches to Claude for architecture reviews
- Sets monthly cost limits per cloud provider
- Gets "free alternative" suggestions when a local model can handle the task
- Organizes conversations by client project for easy reference

**Quote:** *"I don't need the fanciest model every time. I need reliable AI that doesn't drain my wallet."*

---

## Persona 4: Priya — The Mobile Professional

**Role:** Consultant / Product Manager / Field Worker  
**Age:** 28–50 | **Tech Savvy:** Medium

**Goals:**
- Access AI assistance anywhere — commute, airports, client sites
- Work offline during travel with seamless sync when reconnected
- Use cloud APIs for complex tasks, local models for quick queries
- Integrate AI into mobile workflow (share menu, clipboard, TTS)

**Pain Points:**
- Existing AI apps are useless without reliable internet
- Can't queue up requests while offline and get answers later
- Switching providers based on connectivity is manual and tedious
- No good way to share AI responses directly to email, Slack, or notes apps

**Preferred Provider Mix:** 50% cloud APIs / 30% self-hosted (Ollama at home) / 20% on-device  
**Cloud willingness:** High — prioritizes capability and convenience

**Key Scenarios:**
- Drafts client emails using cloud API at the office, switches to on-device model on the plane
- Messages queue automatically when entering a dead zone, send when reconnected
- Uses platform share/open flows to send AI summaries to Slack
- Listens to long AI responses via text-to-speech while driving

**Quote:** *"I need AI that works as hard as I do — on the train, at a client site, or at 30,000 feet."*

---

## Persona 5: Sam — The Student / Learner

**Role:** CS Graduate Student / Self-taught Developer  
**Age:** 18–30 | **Tech Savvy:** High (but budget-limited)

**Goals:**
- Learn about LLMs through hands-on experimentation
- Access AI tools without blowing a student budget
- Compare model architectures and behaviors for research
- Work from phone between classes and during commute

**Pain Points:**
- Can't afford multiple AI subscriptions (ChatGPT + Claude + Gemini)
- University compute is desktop-only and requires VPN
- Free tiers are heavily rate-limited and unreliable for real work
- No tool helps systematically compare model behaviors on mobile

**Preferred Provider Mix:** 50% self-hosted (Ollama on cheap hardware) / 30% on-device / 20% cloud (free tiers + occasional pay-per-use)  
**Cloud willingness:** Low-moderate — only within free tier or small budget

**Key Scenarios:**
- Runs a 7B model on Ollama with a used mini-PC ($100 setup)
- Uses on-device models for quick study questions between classes
- Compares GPT-4 vs. local Llama output for thesis research
- Exports conversations as documentation for research papers

**Quote:** *"I'm learning AI, not made of money. I need tools that let me experiment freely."*

---

## Persona 6: Chris — The Enterprise / Compliance User

**Role:** Senior Analyst / Corporate IT Lead  
**Age:** 30–55 | **Tech Savvy:** Medium

**Goals:**
- Use AI for work while staying within strict data policies
- Access company-hosted AI infrastructure from a mobile device
- Maintain audit trails and exportable conversation records
- Provide a simple, approved tool for non-technical colleagues

**Pain Points:**
- Cloud AI services (ChatGPT, Claude) violate company data policy
- Enterprise AI tools are web-only — no mobile access for field work
- IT hasn't sanctioned a mobile solution, so employees use unauthorized apps
- Needs something reliable and low-maintenance, not a hobby project

**Preferred Provider Mix:** 90% self-hosted (corporate Ollama) / 10% on-device (air-gapped fallback)  
**Cloud willingness:** None — prohibited by policy

**Key Scenarios:**
- Connects to corporate Ollama instance over company VPN
- Uses on-device models when in secure facilities with no network
- Exports conversation logs for compliance audits
- Deploys app via managed APK distribution (no Play Store)

**Quote:** *"I need AI to do my job better, but I can't risk my career using unauthorized cloud services."*

---

## Anti-Personas

These users are **not** our target — if a feature only serves them, deprioritize it.

| Anti-Persona | Why Not |
|---|---|
| **The Zero-Setup User** — Wants AI to "just work" with no configuration | Our value is choice and control; minimum setup is connecting one provider |
| **The iOS-Only User** — Exclusively on Apple devices | Android-first; iOS is a future platform expansion |
| **The Single-Provider Loyalist** — Happy with ChatGPT/Claude subscription, no interest in alternatives | Our value proposition is multi-provider flexibility |

---

## Persona Spectrum Summary

| Persona | Privacy | Cost Sensitivity | Technical Skill | Primary Provider | Cloud Use |
|---|---|---|---|---|---|
| **Alex** — Privacy Advocate | 🔒🔒🔒 | Medium | High | Self-hosted | Minimal |
| **Maya** — AI Experimenter | 🔒 | Low | Very High | Mixed (all) | Heavy |
| **Jordan** — Cost-Conscious Dev | 🔒🔒 | High | Medium-High | Self-hosted + Cloud | Strategic |
| **Priya** — Mobile Professional | 🔒 | Low | Medium | Cloud + Local | Heavy |
| **Sam** — Student / Learner | 🔒🔒 | Very High | High | Self-hosted + Local | Free tiers |
| **Chris** — Enterprise User | 🔒🔒🔒 | Low (has budget) | Medium | Self-hosted | Prohibited |

---

## Using These Personas

When making product decisions, validate against this checklist:

1. **Which personas does this feature serve?** (Must serve at least 2)
2. **Does it respect Alex and Chris's privacy requirements?** (Never send data without explicit consent)
3. **Does it work for Priya offline?** (Offline-first is a core differentiator)
4. **Can Sam afford it?** (Core features must work with free/self-hosted models)
5. **Is it simple enough for Chris and Priya?** (Not everyone is a power user)
6. **Does it help Maya compare and experiment?** (Multi-provider flexibility is our edge)

---

**Related Documents:**
- [PRODUCT_VISION.md](PRODUCT_VISION.md) — Overall product vision and strategy
- [USER_STORIES.md](USER_STORIES.md) — User stories derived from these personas
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) — Functional requirements
