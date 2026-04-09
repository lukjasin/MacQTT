//
//  Exporter.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 03/04/2026.
//

import AppKit
import UniformTypeIdentifiers

struct Exporter {

    static func exportHistory(_ history: [MessageEntry], topic: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = topic.replacingOccurrences(of: "/", with: "_") + ".csv"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let formatter = ISO8601DateFormatter()
        var lines = ["timestamp,value"]
        for entry in history {
            let ts = formatter.string(from: entry.timestamp)
            lines.append("\(ts),\(escapeCSV(entry.value))")
        }
        write(lines.joined(separator: "\n"), to: url)
    }

    static func exportTree(_ nodes: [TopicNode]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "mqtt_snapshot.csv"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let includeSys = UserDefaults.standard.object(forKey: "exportIncludeSys") as? Bool ?? true
        let formatter = ISO8601DateFormatter()
        var lines = ["topic,last_value,last_updated"]
        flattenTree(nodes, into: &lines, formatter: formatter, includeSys: includeSys)
        write(lines.joined(separator: "\n"), to: url)
    }

    private static func flattenTree(_ nodes: [TopicNode], into lines: inout [String], formatter: ISO8601DateFormatter, includeSys: Bool) {
        for node in nodes {
            if !includeSys && node.name == "$SYS" { continue }
            if let value = node.lastMessage {
                let ts = node.lastUpdated.map { formatter.string(from: $0) } ?? ""
                lines.append("\(escapeCSV(node.path)),\(escapeCSV(value)),\(ts)")
            }
            flattenTree(node.children, into: &lines, formatter: formatter, includeSys: includeSys)
        }
    }

    private static func write(_ content: String, to url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        try? content.write(to: url, atomically: true, encoding: .utf8)
        url.stopAccessingSecurityScopedResource()
    }

    private static func escapeCSV(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
