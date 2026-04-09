# MacQTT

A native macOS MQTT client built with SwiftUI.

> **This project is under active development and not yet publicly released.**
> When it's ready, it will be available here as a free download.

---

## Features

- **Multiple simultaneous connections** — connect to several brokers at once, each in its own tab
- **Live topic tree** — topics populate in real time as messages arrive, organized in a collapsible tree
- **Message history** — per-topic message log with timestamps, configurable history size
- **Publish messages** — send payloads with QoS and retain flag control
- **Broker info** — quick overview of broker version, uptime, and connected clients
- **Topic filtering** — filter the tree by topic name as you type
- **Data export** — export the full topic tree or individual message history to JSON or CSV
- **Keyboard-first** — full keyboard navigation, configurable shortcuts (Cmd+K, Cmd+N, Cmd+T, Cmd+E, Cmd+L)
- **Light & dark mode** — native macOS appearance
- **Truly native** — built entirely with SwiftUI, no Electron, no web views

## Requirements

- macOS 15 or later
- Apple Silicon or Intel

## Status

| Stage | Description | Status |
|-------|-------------|--------|
| 1 | Single connection, topic tree, message history, export, keyboard shortcuts | ✅ Complete |
| 2 | Multiple parallel connections, Compare Trees | 🔄 In progress |
| 3 | Alert rules, notifications | 📋 Planned |
| 4 | TLS certificates, Apple Help, App Store release | 📋 Planned |

## Built with

- SwiftUI
- Swift Concurrency (actors, AsyncStream)
- SwiftData
- CocoaMQTT
- Keychain (credential storage)

---

*Made by [@lukjasin](https://github.com/lukjasin)*
