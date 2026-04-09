//
//  MessageDetailView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 31/03/2026.
//

import SwiftUI

struct MessageDetailView: View {
    let topic: String
    let history: [MessageEntry]
    @Binding var pausedAt: Date?
    let onPublish: (String, String, Int, Bool) -> Void
    let onClearHistory: () -> Void

    @AppStorage("wrapHistoryMessages") var wrapHistoryMessages: Bool = true
    @AppStorage("syntaxHighlighting") var syntaxHighlighting: Bool = true
    @AppStorage("cmdEnterPublishes") var cmdEnterPublishes: Bool = false

    @State private var publishTopic: String = ""
    @State private var publishPayload: String = ""
    @State private var publishQoS: Int = 0
    @State private var publishRetain: Bool = false
    @AppStorage("publishEditorHeight") var editorHeight: Double = 120
    @State private var dragStartHeight: Double = 120

    private var displayedHistory: [MessageEntry] {
        let entries = pausedAt.map { cutoff in
            history.filter { $0.timestamp <= cutoff }
        } ?? history
        return Array(entries.reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Topic header ──────────────────────────────
            HStack {
                Text(topic)
                    .font(.headline)
                Spacer()
                Button(action: { Exporter.exportHistory(history, topic: topic) }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                .disabled(history.isEmpty)
                .keyboardShortcut("e", modifiers: .command)
                Button(action: onClearHistory) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(history.isEmpty)
                .keyboardShortcut("l", modifiers: .command)
                Button(action: togglePause) {
                    Label(
                        pausedAt == nil ? "Pause" : "Resume",
                        systemImage: pausedAt == nil ? "pause.circle" : "play.circle"
                    )
                }
                .buttonStyle(.borderless)
                .disabled(history.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // ── History ───────────────────────────────────
            SectionHeader("History")

            if displayedHistory.isEmpty {
                Text("No messages yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(displayedHistory) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(highlightedJSON(entry.value))
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(wrapHistoryMessages ? nil : 1)
                                .truncationMode(.tail)
                                .textSelection(.enabled)
                        }
                        .listRowInsets(EdgeInsets(top: 3, leading: 12, bottom: 3, trailing: 12))
                        .onTapGesture(count: 2) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(entry.value, forType: .string)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: displayedHistory.first?.id) { _, newID in
                        if let id = newID, pausedAt == nil {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }

            Divider()

            // ── Publish ───────────────────────────────────
            SectionHeader("Publish")

            VStack(alignment: .leading, spacing: 8) {
                TextField("Topic", text: $publishTopic)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Rectangle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .cornerRadius(2)
                    .frame(maxWidth: .infinity)
                    .onHover { hovering in
                        if hovering { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                editorHeight = max(40, min(400, dragStartHeight - Double(value.translation.height)))
                            }
                            .onEnded { _ in
                                dragStartHeight = editorHeight
                            }
                    )
                TextEditor(text: $publishPayload)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: CGFloat(editorHeight))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                HStack {
                    Picker("QoS", selection: $publishQoS) {
                        Text("QoS 0").tag(0)
                        Text("QoS 1").tag(1)
                        Text("QoS 2").tag(2)
                    }
                    .frame(width: 130)
                    Toggle("Retain", isOn: $publishRetain)
                    Spacer()
                    Group {
                        if cmdEnterPublishes {
                            Button("Publish") {
                                onPublish(publishTopic, publishPayload, publishQoS, publishRetain)
                            }
                            .keyboardShortcut(.return, modifiers: .command)
                        } else {
                            Button("Publish") {
                                onPublish(publishTopic, publishPayload, publishQoS, publishRetain)
                            }
                        }
                    }
                    .disabled(publishTopic.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(12)
        }
        .onAppear {
            publishTopic = topic
            publishPayload = prettyPrint(history.last?.value ?? "")
        }
        .onChange(of: topic) { _, newTopic in
            publishTopic = newTopic
            publishPayload = prettyPrint(history.last?.value ?? "")
        }
    }

    private func highlightedJSON(_ raw: String) -> AttributedString {
        let text = wrapHistoryMessages ? prettyPrint(raw) : raw
        guard syntaxHighlighting, text.hasPrefix("{") || text.hasPrefix("[") else {
            return AttributedString(text)
        }
        var attributed = AttributedString(text)
        let patterns: [(String, Color)] = [
            (#":\s*-?\d+\.?\d*(?:[eE][+-]?\d+)?"#, .teal),
            (#":\s*(?:true|false)"#, .orange),
            (#":\s*null"#, .gray),
            (#":\s*"[^"\\]*(?:\\.[^"\\]*)*""#, Color(red: 0.7, green: 0.2, blue: 0.2)),
            (#""[^"\\]*(?:\\.[^"\\]*)*"\s*:"#, .purple),
        ]
        for (pattern, color) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                guard let stringRange = Range(match.range, in: text) else { continue }
                let lo = text.distance(from: text.startIndex, to: stringRange.lowerBound)
                let hi = text.distance(from: text.startIndex, to: stringRange.upperBound)
                guard hi <= attributed.characters.count else { continue }
                let lower = attributed.characters.index(attributed.characters.startIndex, offsetBy: lo)
                let upper = attributed.characters.index(attributed.characters.startIndex, offsetBy: hi)
                attributed[lower..<upper].foregroundColor = color
            }
        }
        return attributed
    }

    private func prettyPrint(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
              let result = String(data: pretty, encoding: .utf8)
        else { return raw }
        return result
    }

    private func togglePause() {
        pausedAt = pausedAt == nil ? Date() : nil
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }
}
