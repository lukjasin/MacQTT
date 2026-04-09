# MacQTT

A native macOS MQTT client built with SwiftUI.

**This project is under active development and not yet publicly released.**
When it's ready, it will be available here as a free download.

---

## Stage 1. Foundation

Single broker connection with a live topic tree, message history, and data export.

**Features:**
- Connect to an MQTT broker (with optional TLS)
- Live topic tree that populates in real time as messages arrive
- Per-topic message history with timestamps and configurable size limit
- Publish messages with QoS and retain flag control
- Broker info panel (version, uptime, connected clients)
- Topic filtering by name + regex
- Export the full topic tree or message history to CSV
- Full keyboard navigation with configurable shortcuts
- System theme
- Truly native — built entirely with SwiftUI, no Electron, no web views

---

## Stage 2. Multiple connections

Support for several brokers open at the same time, each in its own tab.

**Planned:**
- Multiple parallel connections
- Per-connection topic trees
- Compare Trees — side-by-side diff of two broker topic trees

---

## Stage 3. Alerts & rules

Trigger notifications based on topic values.

**Planned:**
- Alert rules: topic pattern, condition, action
- macOS notifications
- Rule management UI

---

## Stage 4. Polish & release 📋

**Planned:**
- TLS certificate support
- Apple Help integration
- App Store release

---

## Requirements

- macOS 15 or later
- Apple Silicon or Intel

## Built with

- SwiftUI
- Swift Concurrency (actors, AsyncStream)
- SwiftData
- CocoaMQTT
- Keychain (credential storage)

---

lukjasin
