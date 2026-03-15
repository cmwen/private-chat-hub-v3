# Opinionated Defaults

Sensible defaults for common Flutter app requirements. This document explains what's pre-configured and how to customize, including Android-specific paths where relevant.

---

## Permissions

**File location:** `android/app/src/main/AndroidManifest.xml`

### Required (Enabled by Default)

| Permission | Purpose |
|------------|---------|
| `INTERNET` | Network requests (API calls, provider communication) |
| `ACCESS_NETWORK_STATE` | Check device connectivity |

### Optional (Commented Out)

Uncomment as needed:

| Permission | Purpose | Notes |
|------------|---------|-------|
| `CAMERA` | Photo/video capture | Runtime permission required |
| `ACCESS_FINE_LOCATION` | GPS-level location | Runtime permission required |
| `ACCESS_COARSE_LOCATION` | Approximate location | Runtime permission required |
| `RECORD_AUDIO` | Microphone access (voice input) | Runtime permission required |
| `READ_EXTERNAL_STORAGE` | Read files | Limited to API 32 |
| `WRITE_EXTERNAL_STORAGE` | Write files | Limited to API 29 |

---

## Network Security

**File location:** `android/app/src/main/res/xml/network_security_config.xml`

### Default Configuration

- **HTTPS required** for all production traffic
- **HTTP allowed** for localhost and emulator addresses (development only)
- **System CAs only** — no custom certificate trust by default

### Self-Hosted Provider Access

For Ollama and LM Studio running on local network, add domains:

```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">localhost</domain>
    <domain includeSubdomains="true">10.0.2.2</domain>
    <!-- Add local network hosts for self-hosted providers -->
    <domain includeSubdomains="true">192.168.1.100</domain>
</domain-config>
```

---

## Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| User preferences | SharedPreferences | Simple key-value, fast access |
| Saved conversations | Plain-text history files | Portable, readable source of truth |
| Search/index cache | Local SQLite database | Structured, queryable, rebuildable cache for speed and FTS |
| API keys | Encrypted storage | Security-sensitive credentials |
| Cached models list | Local file system | Large, infrequently changing |
| Cost tracking data | Local database | Structured, needs aggregation |

### Credential Storage

API keys for cloud providers **must** use encrypted storage:

```dart
// Use flutter_secure_storage or equivalent
await secureStorage.write(key: 'openai_api_key', value: apiKey);
```

Never store API keys in SharedPreferences or plain text files.

---

## Provider Defaults

| Setting | Default | Rationale |
|---------|---------|-----------|
| Default provider | Self-hosted (Ollama) | Privacy-first positioning |
| Fallback behavior | Ask user | Respect user's privacy choice |
| Cost warnings | Enabled | Prevent unexpected charges |
| Streaming | Enabled | Better perceived performance |
| Markdown rendering | Enabled | AI responses use markdown |
| Dark mode | System default | Respect OS preference |
| Chat history save mode | Automatically | Simplest default; users can switch to prompt/manual |

---

## Summary

| Feature | Default State |
|---------|---------------|
| Internet permission | Enabled |
| Network state permission | Enabled |
| Camera, location, audio | Commented out |
| HTTPS enforcement | Enabled (HTTP for localhost) |
| Saved chat history | Plain-text files |
| Search index/cache | SQLite (rebuildable) |
| API key encryption | Required |
| Provider default | Self-hosted (Ollama) |
| Streaming responses | Enabled |
| Cost warnings | Enabled |
| Chat history save mode | Automatically |
