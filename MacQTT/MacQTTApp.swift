//
//  MacQTTApp.swift
//  MacQTT
//
//  Created by Łukasz Jasiński on 30/03/2026.
//

import SwiftUI
import SwiftData
import AppKit

extension Notification.Name {
    static let showNewConnection = Notification.Name("showNewConnection")
    static let exportTree       = Notification.Name("exportTree")
}

@main
struct MacQTTApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Connection.self)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Connection") {
                    NotificationCenter.default.post(name: .showNewConnection, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            // Zastępuje systemowe "New Tab" (Cmd+T) własną akcją eksportu drzewa
            CommandGroup(replacing: .windowArrangement) {
                Button("Export Topic Tree") {
                    NotificationCenter.default.post(name: .exportTree, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            CommandGroup(replacing: .appInfo) {
                Button("About MacQTT") {
                    showAboutPanel()
                }
            }
        }

        Settings {
            SettingsView()
        }
    }

    private func showAboutPanel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let small = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: small,
            .paragraphStyle: paragraphStyle
        ]
        let secondaryAttrs: [NSAttributedString.Key: Any] = [
            .font: small,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]

        let credits = NSMutableAttributedString(string: "By Łukasz Jasiński\n", attributes: nameAttrs)
        credits.append(NSAttributedString(string: "luk.jasin@gmail.com\n\n", attributes: secondaryAttrs))
        credits.append(NSAttributedString(string: "Uses CocoaMQTT by Emqx (Apache 2.0 License)", attributes: secondaryAttrs))

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "MacQTT",
            .credits: credits
        ])
    }
}
