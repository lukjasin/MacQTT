//
//  SettingsView.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 01/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showMessagesInTree") var showMessagesInTree: Bool = true
    @AppStorage("highlightOnUpdate") var highlightOnUpdate: Bool = true
    @AppStorage("showCountBadges") var showCountBadges: Bool = true
    @AppStorage("historyLimit") var historyLimit: Int = 500
    @AppStorage("exportIncludeSys") var exportIncludeSys: Bool = true
    @AppStorage("keyboardNavigationEnabled") var keyboardNavigationEnabled: Bool = true
    @AppStorage("cmdCCopiesValue") var cmdCCopiesValue: Bool = true
    @AppStorage("cmdEnterPublishes") var cmdEnterPublishes: Bool = false
    @AppStorage("filterCaseSensitive") var filterCaseSensitive: Bool = false
    @AppStorage("wrapHistoryMessages") var wrapHistoryMessages: Bool = true
    @AppStorage("syntaxHighlighting") var syntaxHighlighting: Bool = true

    var body: some View {
        Form {
            Section("Topic Tree") {
                Toggle("Show messages in tree view", isOn: $showMessagesInTree)
                Toggle("Highlight rows on update", isOn: $highlightOnUpdate)
                Toggle("Show subtopic and message count badges", isOn: $showCountBadges)
                Toggle("Case-sensitive filter", isOn: $filterCaseSensitive)
            }
            Section("Message History") {
                Toggle("Wrap messages in history", isOn: $wrapHistoryMessages)
                Toggle("Syntax highlighting", isOn: $syntaxHighlighting)
                Picker("Messages stored per topic", selection: $historyLimit) {
                    Text("100").tag(100)
                    Text("500").tag(500)
                    Text("1 000").tag(1000)
                    Text("5 000").tag(5000)
                }
                Text("Takes effect after reconnecting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Keyboard") {
                Toggle("Enable keyboard navigation", isOn: $keyboardNavigationEnabled)
                Toggle("Cmd+C copies value instead of topic path", isOn: $cmdCCopiesValue)
                    .disabled(!keyboardNavigationEnabled)
                Toggle("Cmd+Enter publishes message", isOn: $cmdEnterPublishes)
            }
            Section("Export") {
                Toggle("Include $SYS topics in tree export", isOn: $exportIncludeSys)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 650)
    }
}
